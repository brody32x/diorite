/*
 * Author: Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * To the extent possible under law, author has waived all
 * copyright and related or neighboring rights to this file.
 * http://creativecommons.org/publicdomain/zero/1.0/
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Tests are under public domain because they might contain useful sample code.
 */

using Drt.Utils;

namespace Drt {

public class JsonArrayTest: Drt.TestCase {

    private JsonArray load_array() throws GLib.Error {
        return JsonParser.load_array("""
            [
            null,
            true,
            false,
            -1234,
            -12.34,
            "",
            "string",
            [null, true, false, -1234, -12.34, "", "string", [4, 5], {"a": "A", "b": "B"}],
            {"a": "A", "b": "B"}
            ]
            """);
    }

    public void test_append_prepend_insert_remove() throws GLib.Error {
        var array = new JsonArray();
        var null_val = new JsonValue.@null();
        array.append(null_val);
        assert_uint_equal(1, array.length, "1 item");
        assert(array[0] == null_val, "[0] equal");

        var int_val = new JsonValue.@int(5);
        array.append(int_val);
        assert_uint_equal(2, array.length, "2 items");
        assert(array[1] == int_val, "[1] equal");

        var double_val = new JsonValue.@double(5.5);
        array.prepend(double_val);
        assert_uint_equal(3, array.length, "3 items");
        assert(array[0] == double_val, "[0] equal");
        assert(array[1] == null_val, "[1] equal");
        assert(array[2] == int_val, "[2] equal");

        var str_val = new JsonValue.@string("str");
        array.insert(1, str_val);
        assert_uint_equal(4, array.length, "4 items");
        assert(array[0] == double_val, "[0] equal");
        assert(array[1] == str_val, "[1] equal");
        assert(array[2] == null_val, "[2] equal");
        assert(array[3] == int_val, "[3] equal");

        var array_val = new JsonArray();
        array.insert(9, array_val);
        expect_critical_message("DioriteGlib", "drt_json_array_insert*assertion '*<=*' failed",
            "invalid index 9");
        array.insert(4, array_val);
        assert_uint_equal(5, array.length, "5 items");
        assert(array[0] == double_val, "[0] equal");
        assert(array[1] == str_val, "[1] equal");
        assert(array[2] == null_val, "[2] equal");
        assert(array[3] == int_val, "[3] equal");
        assert(array[4] == array_val, "[4] equal");

        array.insert(1, str_val);
        expect_critical_message("DioriteGlib", "*assertion '* == NULL' failed", "parent not null");
        array.prepend(str_val);
        expect_critical_message("DioriteGlib", "*assertion '* == NULL' failed", "parent not null");
        array.append(str_val);
        expect_critical_message("DioriteGlib", "*assertion '* == NULL' failed", "parent not null");
        assert_uint_equal(5, array.length, "5 items");
        assert(array[0] == double_val, "[0] equal");
        assert(array[1] == str_val, "[1] equal");
        assert(array[2] == null_val, "[2] equal");
        assert(array[3] == int_val, "[3] equal");
        assert(array[4] == array_val, "[4] equal");

        uint index;
        expect_true(array.index(double_val, out index), "index found");
        assert_uint_equal(0, index, "index 0 equal");
        expect_true(array.index(str_val, out index), "index found");
        assert_uint_equal(1, index, "index 4 equal");
        expect_true(array.index(null_val, out index), "index found");
        assert_uint_equal(2, index, "index 2 equal");
        expect_true(array.index(int_val, out index), "index found");
        assert_uint_equal(3, index, "index 3 equal");
        expect_true(array.index(array_val, out index), "index found");
        assert_uint_equal(4, index, "index 4 equal");


        array.remove_at(5);
        assert_uint_equal(5, array.length, "5 items");
        expect_critical_message("DioriteGlib", "*assertion '* != NULL' failed", "invalid index");

        array.remove_at(4);
        assert_uint_equal(4, array.length, "4 items");
        assert(array[0] == double_val, "[0] equal");
        assert(array[1] == str_val, "[1] equal");
        assert(array[2] == null_val, "[2] equal");
        assert(array[3] == int_val, "[3] equal");
        expect_false(array.index(array_val, out index), "index not found");

        array.remove_at(1);
        assert_uint_equal(3, array.length, "53items");
        assert(array[0] == double_val, "[0] equal");
        assert(array[1] == null_val, "[2] equal");
        assert(array[2] == int_val, "[3] equal");

        expect_false(array.remove(str_val), "remove non-existent");
        assert_uint_equal(3, array.length, "3 items");
        assert(array[0] == double_val, "[0] equal");
        assert(array[1] == null_val, "[2] equal");
        assert(array[2] == int_val, "[3] equal");

        expect_true(array.remove(null_val), "remove existent");
        assert_uint_equal(2, array.length, "3 items");
        assert(array[0] == double_val, "[0] equal");
        assert(array[1] == int_val, "[3] equal");

        array.remove_at(0);
        array.remove_at(0);
        assert_uint_equal(0, array.length, "0 items");

        array.remove_at(0);
        expect_critical_message("DioriteGlib", "*assertion '* != NULL' failed", "invalid index");
    }

    public void test_set() throws GLib.Error {
        var array = new JsonArray();
        var null_val = new JsonValue.@null();
        array[1] = null_val;
        expect_critical_message("DioriteGlib", "*assertion '*<=*' failed",
            "invalid index 1");
        array[0] = null_val;
        assert_uint_equal(1, array.length, "1 item");
        expect_true(array[0] == null_val, "item 0 equal");
        array[1] = null_val;
        expect_critical_message("DioriteGlib", "*assertion '* == NULL' failed", "parent not null");

        var int_val = new JsonValue.@int(5);
        array[2] = int_val;
        expect_critical_message("DioriteGlib", "*assertion '*<=*' failed",
            "invalid index 2");
        array[1] = int_val;
        assert_uint_equal(2, array.length, "2 items");
        expect_true(array[1] == int_val, "item 1 equal");

        var double_val = new JsonValue.@double(5.5);
        array[1] = double_val;
        assert_uint_equal(2, array.length, "2 items");
        expect_true(array[1] == double_val, "item 1 equal");
    }

    public void test_get() throws GLib.Error {
        JsonArray array = load_array();
        unowned JsonNode? node;
        string[] results = {
            "null", // null
            "bool", // true
            "bool", // false
            "int", // -1234
            "double", // -12.34
            "string", // ""
            "string", // "string"
            "array", // array
            "object", // object
            "nothing", // nothing
        };
        for (uint i = 0; i < results.length; i++) {
            node = array.get(i);
            switch (results[i]) {
            case "null":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_null(), @"array[$i] is $(results[i])");
                }
                break;
            case "bool":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_bool(), @"array[$i] is $(results[i])");
                }
                break;
            case "int":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_int(), @"array[$i] is $(results[i])");
                }
                break;
            case "double":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_double(), @"array[$i] is $(results[i])");
                }
                break;
            case "string":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_string(), @"array[$i] is $(results[i])");
                }
                break;
            case "array":
                if (expect_type_of<JsonArray>(node, @"array[$i]")) {
                    expect_true(node.is_array(), @"array[$i] is $(results[i])");
                }
                break;
            case "object":
                if (expect_type_of<JsonObject>(node, @"array[$i]")) {
                    expect_true(node.is_object(), @"array[$i] is $(results[i])");
                }
                break;
            case "nothing":
                expect_null(node, @"array[$i]");
                break;
            default:
                expectation_failed(@"Unknown type '$(results[i])'");
                break;
            }
        }
    }

    public void test_dotget() throws GLib.Error {
        JsonArray array = load_array();
        unowned JsonNode? node;
        uint i;
        string key;
        string[] results = {
            "null", // null
            "bool", // true
            "bool", // false
            "int", // -1234
            "double", // -12.34
            "string", // ""
            "string", // "string"
            "array", // array
            "object", // object
            "nothing", // nothing
        };

        for (i = 0; i < results.length; i++) {
            node = array.dotget(i.to_string());
            switch (results[i]) {
            case "null":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_null(), @"array[$i] is $(results[i])");
                }
                break;
            case "bool":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_bool(), @"array[$i] is $(results[i])");
                }
                break;
            case "int":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_int(), @"array[$i] is $(results[i])");
                }
                break;
            case "double":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_double(), @"array[$i] is $(results[i])");
                }
                break;
            case "string":
                if (expect_type_of<JsonValue>(node, @"array[$i]")) {
                    expect_true(node.is_string(), @"array[$i] is $(results[i])");
                }
                break;
            case "array":
                if (expect_type_of<JsonArray>(node, @"array[$i]")) {
                    expect_true(node.is_array(), @"array[$i] is $(results[i])");
                }
                break;
            case "object":
                if (expect_type_of<JsonObject>(node, @"array[$i]")) {
                    expect_true(node.is_object(), @"array[$i] is $(results[i])");
                }
                break;
            case "nothing":
                expect_null(node, @"array[$i]");
                break;
            default:
                expectation_failed(@"Unknown type '$(results[i])'");
                break;
            }
        }

        for (i = 0; i < results.length; i++) {
            key = "7.%u".printf(i);
            node = array.dotget(key);
            switch (results[i]) {
            case "null":
                if (expect_type_of<JsonValue>(node, @"array[$key]")) {
                    expect_true(node.is_null(), @"array[$key] is $(results[i])");
                }
                break;
            case "bool":
                if (expect_type_of<JsonValue>(node, @"array[$key]")) {
                    expect_true(node.is_bool(), @"array[$key] is $(results[i])");
                }
                break;
            case "int":
                if (expect_type_of<JsonValue>(node, @"array[$key]")) {
                    expect_true(node.is_int(), @"array[$key] is $(results[i])");
                }
                break;
            case "double":
                if (expect_type_of<JsonValue>(node, @"array[$key]")) {
                    expect_true(node.is_double(), @"array[$key] is $(results[i])");
                }
                break;
            case "string":
                if (expect_type_of<JsonValue>(node, @"array[$key]")) {
                    expect_true(node.is_string(), @"array[$key] is $(results[i])");
                }
                break;
            case "array":
                if (expect_type_of<JsonArray>(node, @"array[$key]")) {
                    expect_true(node.is_array(), @"array[$key] is $(results[i])");
                }
                break;
            case "object":
                if (expect_type_of<JsonObject>(node, @"array[$key]")) {
                    expect_true(node.is_object(), @"array[$key] is $(results[i])");
                }
                break;
            case "nothing":
                expect_null(node, @"array[$key]");
                break;
            default:
                expectation_failed(@"Unknown type '$(results[i])'");
                break;
            }
        }

        string[,] results2 = {
            {"", "*drt_json_array_dotget*assertion*!= '\\0'*failed*"},
            {".", "*drt_json_array_dotget*assertion*!= 0*failed*"},
            {"7.", "*drt_json_array_dotget*assertion*!= '\\0'*failed*"},
            {"7..", "*drt_json_array_dotget*assertion*!= 0*failed*"},
            {"a", ""},
        };
        for (i = 0; i < results2.length[0]; i++) {
            unowned string ukey = results2[i, 0];
            expect_null(array.dotget(ukey), @"invalid key '$ukey'");
            unowned string msg = results2[i, 1];
            if (msg[0] != '\0') {
                expect_critical_message("DioriteGlib", msg, @"critical msg for '$ukey'");
            }
        }
    }

    public void test_get_bool() throws GLib.Error {
        JsonArray array = load_array();
        bool val = true;
        GLib.Value[,] results = {
            {false, false}, // null
            {true, true}, // true
            {true, false}, // false
            {false, true}, // -1234
            {false, false}, // -12.34
            {false, false}, // ""
            {false, false}, // "string"
            {false, false}, // array
            {false, false}, // object
            {false, false}, // nothing
        };
        for (uint i = 0; i < results.length[0]; i++) {
            expect(results[i, 0] == array.get_bool(i, out val), @"get_bool($i)");
            expect(results[i, 1] == val, @"[$i] == $(results[i, 1].get_boolean())");
        }
    }

    public void test_dotget_bool() throws GLib.Error {
        JsonArray array = load_array();
        string key;
        unowned string ukey;
        bool val = true;
        uint i;
        GLib.Value[,] results = {
            {false, false}, // null
            {true, true}, // true
            {true, false}, // false
            {false, true}, // -1234
            {false, false}, // -12.34
            {false, false}, // ""
            {false, false}, // "string"
            {false, false}, // array
            {false, false}, // object
            {false, false}, // nothing
        };
        for (i = 0; i < results.length[0]; i++) {
            expect(results[i, 0] == array.dotget_bool(i.to_string(), out val), @"get_bool('$i')");
            expect(results[i, 1] == val, @"[$i] == $(results[i, 1].get_boolean())");
        }
        for (i = 0; i < results.length[0]; i++) {
            key = "7.%u".printf(i);
            expect(results[i, 0] == array.dotget_bool(key, out val), @"get_bool('$key')");
            expect(results[i, 1] == val, @"[$key] == $(results[i, 1].get_boolean())");
        }

        GLib.Value[,] results2 = {
            {"", false, "*drt_json_array_dotget*assertion*!= '\\0'*failed*", false},
            {".", false, "*drt_json_array_dotget*assertion*!= 0*failed*", false},
            {"7.", false, "*drt_json_array_dotget*assertion*!= '\\0'*failed*", false},
            {"7..", false, "*drt_json_array_dotget*assertion*!= 0*failed*", false},
            {"a", false, "", false},
        };
        for (i = 0; i < results2.length[0]; i++) {
            ukey = results2[i, 0].get_string();
            expect(results2[i, 1] == array.dotget_bool(ukey, out val), @"invalid key '$ukey'");
            unowned string msg = results2[i, 2].get_string();
            if (msg[0] != '\0') {
                expect_critical_message("DioriteGlib", msg, @"critical msg for '$ukey'");
            }
            expect(results2[i, 3] == val, @"[$ukey] == $(results2[i, 3].get_boolean())");
        }
    }

    public void test_get_int() throws GLib.Error {
        JsonArray array = load_array();
        int val = -1;
        GLib.Value[,] results = {
            {false, 0}, // null
            {false, 1}, // true
            {false, 0}, // false
            {true, -1234}, // -1234
            {false, 0}, // -12.34
            {false, 0}, // ""
            {false, 0}, // "string"
            {false, 0}, // array
            {false, 0}, // object
            {false, 0}, // nothing
        };
        for (uint i = 0; i < results.length[0]; i++) {
            expect(results[i, 0] == array.get_int(i, out val), @"get_int($i)");
            int exp_val = results[i, 1].get_int();
            expect_int_equal(exp_val, val, @"[$i] == $exp_val");
        }
    }

    public void test_dotget_int() throws GLib.Error {
        JsonArray array = load_array();
        string key;
        unowned string ukey;
        int val = -1;
        uint i;
        GLib.Value[,] results = {
            {false, 0}, // null
            {false, 1}, // true
            {false, 0}, // false
            {true, -1234}, // -1234
            {false, 0}, // -12.34
            {false, 0}, // ""
            {false, 0}, // "string"
            {false, 0}, // array
            {false, 0}, // object
            {false, 0}, // nothing
        };
        for (i = 0; i < results.length[0]; i++) {
            expect(results[i, 0] == array.dotget_int(i.to_string(), out val), @"dotget_int($i)");
            int exp_val = results[i, 1].get_int();
            expect_int_equal(exp_val, val, @"[$i] == $exp_val");
        }
        for (i = 0; i < results.length[0]; i++) {
            key = "7.%u".printf(i);
            expect(results[i, 0] == array.dotget_int(key, out val), @"dotget_int('$key')");
            int exp_val = results[i, 1].get_int();
            expect_int_equal(exp_val, val, @"[$key] == $exp_val");
        }

        GLib.Value[,] results2 = {
            {"", false, "*drt_json_array_dotget*assertion*!= '\\0'*failed*", 0},
            {".", false, "*drt_json_array_dotget*assertion*!= 0*failed*", 0},
            {"7.", false, "*drt_json_array_dotget*assertion*!= '\\0'*failed*", 0},
            {"7..", false, "*drt_json_array_dotget*assertion*!= 0*failed*", 0},
            {"a", false, "", 0},
        };
        for (i = 0; i < results2.length[0]; i++) {
            ukey = results2[i, 0].get_string();
            expect(results2[i, 1] == array.dotget_int(ukey, out val), @"invalid key '$ukey'");
            unowned string msg = results2[i, 2].get_string();
            if (msg[0] != '\0') {
                expect_critical_message("DioriteGlib", msg, @"critical msg for '$ukey'");
            }
            int exp_val = results2[i, 3].get_int();
            expect_int_equal(exp_val, val, @"[$ukey] == $exp_val");
        }
    }

    public void test_get_double() throws GLib.Error {
        JsonArray array = load_array();
        double val = -1.0;
        GLib.Value[,] results = {
            {false, 0.0}, // null
            {false, 0.0}, // true
            {false, 0.0}, // false
            {false, 0.0}, // -1234
            {true, -12.34}, // -12.34
            {false, 0.0}, // ""
            {false, 0.0}, // "string"
            {false, 0.0}, // array
            {false, 0.0}, // object
            {false, 0.0}, // nothing
        };
        for (uint i = 0; i < results.length[0]; i++) {
            expect(results[i, 0] == array.get_double(i, out val), @"get_double($i)");
            double exp_val = results[i, 1].get_double();
            expect_double_equal(exp_val, val, @"[$i] == $exp_val");
        }
    }

    public void test_dotget_double() throws GLib.Error {
        JsonArray array = load_array();
        string key;
        unowned string ukey;
        double val = -1;
        uint i;
        GLib.Value[,] results = {
            {false, 0.0}, // null
            {false, 0.0}, // true
            {false, 0.0}, // false
            {false, 0.0}, // -1234
            {true, -12.34}, // -12.34
            {false, 0.0}, // ""
            {false, 0.0}, // "string"
            {false, 0.0}, // array
            {false, 0.0}, // object
            {false, 0.0}, // nothing
        };
        for (i = 0; i < results.length[0]; i++) {
            expect(results[i, 0] == array.dotget_double(i.to_string(), out val), @"dotget_double($i)");
            double exp_val = results[i, 1].get_double();
            expect_double_equal(exp_val, val, @"[$i] == $exp_val");
        }
        for (i = 0; i < results.length[0]; i++) {
            key = "7.%u".printf(i);
            expect(results[i, 0] == array.dotget_double(key, out val), @"dotget_double('$key')");
            double exp_val = results[i, 1].get_double();
            expect_double_equal(exp_val, val, @"[$key] == $exp_val");
        }

        GLib.Value[,] results2 = {
            {"", false, "*drt_json_array_dotget*assertion*!= '\\0'*failed*", 0.0},
            {".", false, "*drt_json_array_dotget*assertion*!= 0*failed*", 0.0},
            {"7.", false, "*drt_json_array_dotget*assertion*!= '\\0'*failed*", 0.0},
            {"7..", false, "*drt_json_array_dotget*assertion*!= 0*failed*", 0.0},
            {"a", false, "", 0.0},
        };
        for (i = 0; i < results2.length[0]; i++) {
            ukey = results2[i, 0].get_string();
            expect(results2[i, 1] == array.dotget_double(ukey, out val), @"invalid key '$ukey'");
            unowned string msg = results2[i, 2].get_string();
            if (msg[0] != '\0') {
                expect_critical_message("DioriteGlib", msg, @"critical msg for '$ukey'");
            }
            double exp_val = results2[i, 3].get_double();
            expect_double_equal(exp_val, val, @"[$ukey] == $exp_val");
        }
    }

    public void test_get_string() throws GLib.Error {
        JsonArray array = load_array();
        string? val = null;
        GLib.Value?[,] results = {
            {false, null}, // null
            {false, null}, // true
            {false, null}, // false
            {false, null}, // -1234
            {false, null}, // -12.34
            {true, ""}, // ""
            {true, "string"}, // "string"
            {false, null}, // array
            {false, null}, // object
            {false, null}, // nothing
        };
        for (uint i = 0; i < results.length[0]; i++) {
            expect(results[i, 0].get_boolean() == array.get_string(i, out val), @"get_string($i)");
            unowned string? exp_val = results[i, 1] == null ? null : results[i, 1].get_string();
            expect_str_equal(exp_val, val, @"[$i] == $(Drt.String.repr(exp_val))");
        }
    }

    public void test_dotget_string() throws GLib.Error {
        JsonArray array = load_array();
        string key;
        unowned string ukey;
        string? val = null;
        uint i;
        GLib.Value?[,] results = {
            {false, null}, // null
            {false, null}, // true
            {false, null}, // false
            {false, null}, // -1234
            {false, null}, // -12.34
            {true, ""}, // ""
            {true, "string"}, // "string"
            {false, null}, // array
            {false, null}, // object
            {false, null}, // nothing
        };
        for (i = 0; i < results.length[0]; i++) {
            expect(results[i, 0].get_boolean() == array.dotget_string(i.to_string(), out val), @"dotget_string($i)");
            string exp_val = results[i, 1] != null ? results[i, 1].get_string() : null;
            expect_str_equal(exp_val, val, @"[$i] == $(Drt.String.repr(exp_val))");
        }
        for (i = 0; i < results.length[0]; i++) {
            key = "7.%u".printf(i);
            expect(results[i, 0].get_boolean() == array.dotget_string(key, out val), @"dotget_string('$key')");
            string exp_val = results[i, 1] != null ? results[i, 1].get_string() : null;
            expect_str_equal(exp_val, val, @"[$key] == $(Drt.String.repr(exp_val))");
        }

        GLib.Value[,] results2 = {
            {"", false, "*drt_json_array_dotget*assertion*!= '\\0'*failed*"},
            {".", false, "*drt_json_array_dotget*assertion*!= 0*failed*"},
            {"7.", false, "*drt_json_array_dotget*assertion*!= '\\0'*failed*"},
            {"7..", false, "*drt_json_array_dotget*assertion*!= 0*failed*"},
            {"a", false, ""},
        };
        for (i = 0; i < results2.length[0]; i++) {
            ukey = results2[i, 0].get_string();
            expect(results2[i, 1] == array.dotget_string(ukey, out val), @"invalid key '$ukey'");
            unowned string msg = results2[i, 2].get_string();
            if (msg[0] != '\0') {
                expect_critical_message("DioriteGlib", msg, @"critical msg for '$ukey'");
            }
            expect_null(val, @"['$ukey'] == null");
        }
    }

    public void test_get_null() throws GLib.Error {
        JsonArray array = load_array();
        bool[] results = {
            true, // null
            false, // true
            false, // false
            false, // -1234
            false, // -12.34
            false, // ""
            false, // "string"
            false, // array
            false, // object
            false, // nothing
        };
        for (uint i = 0; i < results.length; i++) {
            expect(results[i] == array.get_null(i), @"get_null($i)");
        }
    }

    public void test_get_array() throws GLib.Error {
        JsonArray array = load_array();
        for (uint i = 0; i < 10; i++) {
            if (i != 7) {
                expect_null(array.get_array(i), @"get_array($i)");
            } else {
                expect_not_null(array.get_array(i), @"get_array($i)");
            }
        }
    }

    public void test_get_object() throws GLib.Error {
        JsonArray array = load_array();
        for (uint i = 0; i < 10; i++) {
            if (i != 8) {
                expect_null(array.get_object(i), @"get_object($i)");
            } else {
                expect_not_null(array.get_object(i), @"get_object($i)");
            }
        }
    }

    public void test_as_bool_array() throws GLib.Error {
        JsonArray array = load_array();
        bool[] empty = {};
        bool[] result;
        expect_false(array.as_bool_array(out result), "not bool array");
        expect_array(wrap_boolv(empty), wrap_boolv(result), bool_eq, "array eq");

        expect_true(new JsonArray().as_bool_array(out result), "empty bool array");
        expect_array(wrap_boolv(empty), wrap_boolv(result), bool_eq, "array eq");

        array = JsonParser.load_array("[true, false, null]");
        expect_false(array.as_bool_array(out result), "not bool array");
        expect_array(wrap_boolv(empty), wrap_boolv(result), bool_eq, "array eq");

        array = JsonParser.load_array("[true, false, true]");
        expect_true(array.as_bool_array(out result), "bool array");
        expect_array(wrap_boolv({true, false, true}), wrap_boolv(result), bool_eq, "array eq");
    }

    public void test_as_int_array() throws GLib.Error {
        JsonArray array = load_array();
        int[] empty = {};
        int[] result;
        expect_false(array.as_int_array(out result), "not int array");
        expect_array(wrap_intv(empty), wrap_intv(result), int_eq, "array eq");

        expect_true(new JsonArray().as_int_array(out result), "empty int array");
        expect_array(wrap_intv(empty), wrap_intv(result), int_eq, "array eq");

        array = JsonParser.load_array("[0, 1, null]");
        expect_false(array.as_int_array(out result), "not int array");
        expect_array(wrap_intv(empty), wrap_intv(result), int_eq, "array eq");

        array = JsonParser.load_array("[0, 10, -5]");
        expect_true(array.as_int_array(out result), "int array");
        expect_array(wrap_intv({0, 10, -5}), wrap_intv(result), int_eq, "array eq");
    }

    public void test_as_double_array() throws GLib.Error {
        JsonArray array = load_array();
        double[] empty = {};
        double[] result;
        expect_false(array.as_double_array(out result), "not double array");
        expect_array(wrap_doublev(empty), wrap_doublev(result), double_eq, "array eq");

        expect_true(new JsonArray().as_double_array(out result), "empty double array");
        expect_array(wrap_doublev(empty), wrap_doublev(result), double_eq, "array eq");

        array = JsonParser.load_array("[0.5, 1.3, null]");
        expect_false(array.as_double_array(out result), "not double array");
        expect_array(wrap_doublev(empty), wrap_doublev(result), double_eq, "array eq");

        array = JsonParser.load_array("[0.5, 10.8, -5.7]");
        expect_true(array.as_double_array(out result), "double array");
        expect_array(wrap_doublev({0.5, 10.8, -5.7}), wrap_doublev(result), double_eq, "array eq");
    }

    public void test_as_string_array() throws GLib.Error {
        JsonArray array = load_array();
        string[] empty = {};
        string[] result;
        expect_false(array.as_string_array(out result), "not string array");
        expect_array(wrap_strv(empty), wrap_strv(result), str_eq, "array eq");

        expect_true(new JsonArray().as_string_array(out result), "empty string array");
        expect_array(wrap_strv(empty), wrap_strv(result), str_eq, "array eq");

        array = JsonParser.load_array("[\"\", \"str\", null]");
        expect_false(array.as_string_array(out result), "not string array");
        expect_array(wrap_strv(empty), wrap_strv(result), str_eq, "array eq");

        array = JsonParser.load_array("[\"\", \"str\", \"line1\\nline2\"]");
        expect_true(array.as_string_array(out result), "string array");
        expect_array(wrap_strv({"", "str", "line1\nline2"}), wrap_strv(result), str_eq, "array eq");
    }

    public void test_to_string() throws GLib.Error {
        JsonArray array = load_array();
        const string one_line_json = (
            "[null, true, false, -1234, -12.34, \"\", \"string\", " +
            "[null, true, false, -1234, -12.34, \"\", \"string\", " +
            "[4, 5], {\"a\": \"A\", \"b\": \"B\"}], " +
            "{\"a\": \"A\", \"b\": \"B\"}]");
        const string compact_json = (
            "[null,true,false,-1234,-12.34,\"\",\"string\"," +
            "[null,true,false,-1234,-12.34,\"\",\"string\"," +
            "[4,5],{\"a\":\"A\",\"b\":\"B\"}],{\"a\":\"A\",\"b\":\"B\"}]");
        const string pretty_json = """[
    null,
    true,
    false,
    -1234,
    -12.34,
    "",
    "string",
    [
        null,
        true,
        false,
        -1234,
        -12.34,
        "",
        "string",
        [
            4,
            5
        ],
        {
            "a": "A",
            "b": "B"
        }
    ],
    {
        "a": "A",
        "b": "B"
    }
]
""";
        expect_str_equal(one_line_json, array.to_string(), "one line json");
        expect_str_equal(one_line_json, array.dump(null, false, 0), "one line json");
        expect_str_equal(compact_json, array.dump(null, true, 0), "compact json");
        expect_str_equal(compact_json, array.to_compact_string(), "compact json");
        expect_str_equal(pretty_json, array.to_pretty_string(), "pretty json");
        expect_str_equal(pretty_json, array.dump("    ", false, 0), "pretty json");
        var buf = new StringBuilder();
        array.dump_to_buffer(buf, "    ", false, 0);
        expect_str_equal(pretty_json, buf.str, "pretty json");
    }
}

} // namespace Drt
