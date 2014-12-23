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

namespace Diorite
{

[Flags]
public enum PropertyBindingFlags
{
	/**
	 * When either the value of a property or a key changes, the other is updated.
	 */
	BIDIRECTIONAL,
	/**
	 * When value of a given key is changed, the object's property is updated with its value.
	 */
	KEY_TO_PROPERTY,
	/**
	 * When value of an object property is changed, the key is updated with its value.
	 */
	PROPERTY_TO_KEY;
}

public class PropertyBinding
{
	public unowned KeyValueStorage storage {get; private set;}
	public string key {get; private set;}
	public unowned GLib.Object? object {get; private set;}
	public unowned ParamSpec property {get; private set;}
	public PropertyBindingFlags flags {get; private set;}
	private bool has_gone = false;
	
	public PropertyBinding(KeyValueStorage storage, string key, GLib.Object object, ParamSpec property, PropertyBindingFlags flags)
	{
		
		if ((flags & PropertyBindingFlags.PROPERTY_TO_KEY) != 0
		&& (flags & PropertyBindingFlags.KEY_TO_PROPERTY) != 0)
			flags |= PropertyBindingFlags.BIDIRECTIONAL;
		this.storage = storage;
		this.key = key;
		this.object = object;
		this.property = property;
		this.flags = flags;
		if ((flags & (PropertyBindingFlags.BIDIRECTIONAL|PropertyBindingFlags.PROPERTY_TO_KEY)) != 0)
			object.notify[property.name].connect_after(on_property_changed);
		
		if ((flags & (PropertyBindingFlags.BIDIRECTIONAL|PropertyBindingFlags.KEY_TO_PROPERTY)) != 0)
			storage.changed.connect(on_key_changed);
		
		object.weak_ref(gone);
		storage.weak_ref(gone);
	}
	
	~PropertyBinding()
	{
		if (!has_gone)
		{
			object.weak_unref(gone);
			storage.weak_unref(gone);
			has_gone = true;
		}
		
		if ((flags & (PropertyBindingFlags.BIDIRECTIONAL|PropertyBindingFlags.PROPERTY_TO_KEY)) != 0)
			object.notify[property.name].disconnect(on_property_changed);
		
		if ((flags & (PropertyBindingFlags.BIDIRECTIONAL|PropertyBindingFlags.KEY_TO_PROPERTY)) != 0)
			storage.changed.disconnect(on_key_changed);
	}
	
	public string to_string()
	{
		string relation;
		if ((flags & PropertyBindingFlags.BIDIRECTIONAL) != 0)
			relation = "<==>";
		else if ((flags & PropertyBindingFlags.PROPERTY_TO_KEY) != 0)
			relation = "<==";
		else if ((flags & PropertyBindingFlags.KEY_TO_PROPERTY) != 0)
			relation = "==>";
		else
			relation = "=?=";
		return "%s['%s'] %s %s['%s'] (type %s)".printf(storage.get_type().name(), key, relation,
			object.get_type().name(), property.name, property.value_type.name());
	}
	
	public void update_key()
	{
		if (property.value_type == typeof(string))
		{
			string? str_value = null;
			object.get(property.name, &str_value, null);
			storage.set_string(key, str_value);
		}
		else if (property.value_type == typeof(bool))
		{
			bool value = false;
			object.get(property.name, &value, null);
			storage.set_bool(key, value);
		}
		else
		{
			critical("Unsupported type for property binding. %s.", to_string());
		}
	}
	
	public bool update_property()
	{
		if (property.value_type == typeof(string))
		{
			string? str_value = null;
			object.get(property.name, &str_value, null);
			var new_str_value = storage.get_string(key);
			if (str_value == new_str_value)
				return false;
			
			object.set(property.name, new_str_value, null);
			return true;
		}
		else if (property.value_type == typeof(bool))
		{
			bool value = false;
			object.get(property.name, &value, null);
			var new_value = storage.get_bool(key);
			if (value == new_value)
				return false;
			
			object.set(property.name, new_value, null);
			return true;
		}
		else
		{
			critical("Unsupported type for property binding. %s.", to_string());
		}
		return false;
	}
	
	private void on_property_changed(GLib.Object o, ParamSpec p)
	{
		update_key();
	}
	
	private void on_key_changed(string key, Variant? old_value)
	{
		if (key == this.key)
			update_property();
	}
	
	private void gone(GLib.Object o)
	{
		has_gone = true;
		if (o != object)
			object.weak_unref(gone);
		if (o != storage)
			storage.weak_unref(gone);
		
		if (storage != null)
			storage.remove_property_binding(this);
	}
}

} // namespace Diorite
