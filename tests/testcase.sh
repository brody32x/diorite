#!/bin/bash

# Author: Jiří Janoušek <janousek.jiri@gmail.com>
#
# To the extent possible under law, author has waived all
# copyright and related or neighboring rights to this file.
# http://creativecommons.org/publicdomain/zero/1.0/
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 build|dist|run lin|mingw"
	exit 1
fi

set -eu
NAME="testcase"
CMD="$1"
PLATFORM="$2"
OUT=${OUT:-`dirname $PWD`/build}
BUILD=${BUILD:-`dirname $PWD`/build}
. ../examples/conf.inc.sh 

build()
{
	dist
	echo "*** $0 build ***"
	mkdir -p ${OUT}/testgen
	set -x
	$TESTGEN -d ${OUT}/testgen --vapidir $BUILD --vapidir ../vapi *.vala
	
	valac -C -g -d ${OUT}/tests -b ${OUT}/testgen --thread --save-temps -v \
	--library=${NAME}  --vapidir $BUILD  \
	--vapidir ../vapi --pkg glib-2.0 --target-glib=2.32 \
	--pkg=dioriteglib --pkg=posix --pkg gmodule-2.0 \
	${OUT}/testgen/*.vala
	
	cc -g -o ${OUT}/${LIBPREFIX}${NAME}${LIBSUFFIX} \
	-fPIC -shared -g3 '-DG_LOG_DOMAIN="Diorite"' \
	-I$BUILD -L$BUILD -ldioriteglib \
	$(pkg-config --cflags --libs gmodule-2.0 glib-2.0) \
	${OUT}/tests/*.c
	set +x
}

run()
{
	build
	dist
	echo "*** $0 run ***"
	set -x
	$TESTER ${OUT}/testcase ${OUT}/testgen/tests.spec
	set +x
}

$CMD
