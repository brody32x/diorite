/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Diorite.Ipc
{

public void uint32_to_bytes(ref uint8[] buffer, uint32 data, uint offset=0)
{
	var size = sizeof(uint32);
	assert(buffer.length >= offset + size);
	for(var i = 0; i < size; i ++)
		buffer[offset + i] = (uint8)((data >> ((3 - i) * 8)) & 0xFF);
}

public void uint32_from_bytes(ref uint8[] buffer, out uint32 data, uint offset=0)
{
	var size = sizeof(uint32);
	assert(buffer.length >= offset + size);
	data = 0;
	for(var i = 0; i < size; i ++)
		data += buffer[offset + i] * (1 << (3 - i) * 8);
} 

public class Channel
{
	private string name;
	private string path;
	#if WIN
	private Win32.NamedPipe pipe = Win32.NamedPipe.INVALID;
	#else
	// TODO
	#endif
	private bool connected
	{
		get
		{
			#if WIN
			return pipe != Win32.Handle.INVALID;
			#else
			return false;
			#endif
		}
	}
	
	public Channel(string name)
	{
		this.name = name;
		this.path = create_path(name);
	}
	
	public void create()  throws IOError
	{
		#if WIN
		pipe = Win32.NamedPipe.create((Win32.String) path,
		Win32.PIPE_ACCESS_DUPLEX,
		Win32.PIPE_TYPE_BYTE | Win32.PIPE_READMODE_BYTE | Win32.PIPE_WAIT, 
		Win32.PIPE_UNLIMITED_INSTANCES, PIPE_BUFSIZE, PIPE_BUFSIZE, 0, null);
		if (pipe == Win32.Handle.INVALID)
			throw new IOError.CONN_FAILED("Failed to create pipe '%s'. %s", path, Win32.get_last_error_msg());
		#else
		assert_not_reached();
		#endif
	}
	
	public void listen() throws IOError
	{
		check_connected();
		#if WIN
		if (!pipe.connect() && Win32.get_last_error() != Win32.ERROR_PIPE_CONNECTED)
		{
			close();
			throw new IOError.CONN_FAILED("Failed to connect pipe '%s'. %s", path, Win32.get_last_error_msg());
		}
		#else
		assert_not_reached();
		#endif
	}
	
	public void disconnect() throws IOError
	{
		check_connected();
		#if WIN
		pipe.disconnect();
		#else
		assert_not_reached();
		#endif
	}
	
	public void connect(uint timeout) throws IOError
	{
		#if WIN
		while (true)
		{
			pipe = Win32.NamedPipe.open((Win32.String) path,
			Win32.GENERIC_READ | Win32.GENERIC_WRITE, 0,
			null, Win32.OPEN_EXISTING, 0);
			if (pipe != Win32.FileHandle.INVALID)
				break;
			
			if (Win32.get_last_error() != Win32.ERROR_PIPE_BUSY) 
				throw new IOError.CONN_FAILED("Failed to connect to pipe '%s'. %s", path, Win32.get_last_error_msg()); 
		
			if (!Win32.NamedPipe.wait((Win32.String) name, timeout))
				throw new IOError.TIMEOUT("Timeout reached for pipe '%s'. %s", path, Win32.get_last_error_msg()); 
		}
		
		ulong mode = Win32.PIPE_READMODE_BYTE;
		if (!pipe.set_state(ref mode, null, null) && Win32.get_last_error() != 0)
		{
			pipe.close();
			pipe = Win32.NamedPipe.INVALID;
			throw new IOError.CONN_FAILED("Failed to set up pipe '%s'. %s", path, Win32.get_last_error_msg()); 
		}
		#else
		assert_not_reached();
		#endif
	}
	
	public void write_data(owned uint8[] data) throws IOError
	{
		var bytes = new ByteArray.take((owned) data);
		write_bytes(bytes);
	}
	
	public void close()
	{
		if (connected)
		{
			#if WIN
			pipe.close();
			pipe = Win32.NamedPipe.INVALID;
			#else
			assert_not_reached();
			#endif
		}
	}
	
	public void flush() throws IOError
	{
		check_connected();
		#if WIN
		pipe.flush();
		#else
		assert_not_reached();
		#endif
	}
	
	protected void write(uint8* buffer, int len, out ulong bytes_written) throws IOError
	{
		bytes_written = 0;
		#if WIN
		unowned uint8[] data = (uint8[]) buffer;
		data.length = len;
		if (!pipe.write(data, out bytes_written))
		{
			close();
			throw new IOError.WRITE("Failed send request to pipe '%s': %s", path, Win32.get_last_error_msg());
		}
		#else
		assert_not_reached();
		#endif
		flush();
	}
	
	public void write_bytes(ByteArray bytes) throws IOError
	{
		check_connected();
		if (bytes.len > get_max_message_size())
			throw new IOError.TOO_MANY_DATA("Only %s bytes can be sent.", get_max_message_size().to_string());
		
		uint32 size = bytes.len;
		uint8[] size_buffer = new uint8[sizeof(uint32)];
		uint32_to_bytes(ref size_buffer, size);
		bytes.prepend(size_buffer);
		
		#if WIN
			uint8* data = bytes.data;
			var total_size = bytes.len;
			ulong bytes_written_total = 0;
			ulong bytes_written;
			do
			{
				write(data + bytes_written_total, int.min(MESSAGE_BUFSIZE, (int)(total_size - bytes_written_total)), out bytes_written);
				bytes_written_total += bytes_written;
			}
			while (bytes_written_total < total_size);
		#else
		assert_not_reached();
		#endif
	}
	
	public void read_data(out uint8[] data) throws IOError
	{
		ByteArray bytes;
		read_bytes(out bytes);
		data = (owned) bytes.data;
	}
	
	public void read_bytes(out ByteArray bytes) throws IOError
	{
		check_connected();
		bytes = new ByteArray();
		#if WIN
		uint8[MESSAGE_BUFSIZE] buffer = new uint8[MESSAGE_BUFSIZE];
		ulong bytes_read;
		uint64 bytes_read_total = 0;
		uint64 message_size = 0;
		do
		{
			pipe.read(buffer, out bytes_read);
			if (bytes_read_total == 0)
			{
				uint32_from_bytes(ref buffer, out message_size);
				bytes_read_total += bytes_read - sizeof(uint32);
				unowned uint8[] shorter_buffer = (uint8[])((uint8*) buffer + sizeof(uint32));
				shorter_buffer.length = (int) (buffer.length - sizeof(uint32));
				bytes.append(shorter_buffer);
			}
			else
			{
				bytes.append(buffer);
				bytes_read_total += bytes_read;
			}
			
			var extra = (uint) (MESSAGE_BUFSIZE - bytes_read);
			if (extra > 0)
				bytes.remove_range(bytes.len - extra, extra);
		}
		while (bytes_read_total < message_size);
		#else
		assert_not_reached();
		#endif
	}
	
	protected void read(uint8[] buffer, out long bytes_read) throws IOError
	{
		bytes_read = 0;
		#if WIN
		var result = pipe.read(buffer, out bytes_read);
		if (!result && Win32.get_last_error() != Win32.ERROR_MORE_DATA)
		{
			close();
			throw new IOError.READ("Failed to read from pipe. %s", Win32.get_last_error_msg());
		}
		#else
		assert_not_reached();
		#endif
	}
	
	protected void check_connected() throws IOError
	{
		if (!connected)
			throw new IOError.NOT_CONNECTED("Not connected.");
	}
	
	public static size_t get_max_message_size()
	{
		return uint32.MAX - sizeof(uint32);
	}
}

} // namespace Diorote