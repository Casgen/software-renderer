
package tests

import "core:testing"

import "../core/formats/obj"


@(test)
obj_parser_test :: proc(t: ^testing.T) {

    reader, err := open_file_and_create_reader("res/tests/cube.obj")
    if !testing.expectf(
        t,
        err == nil,
        "Failed to open a file! %v",
        err,
    ) {return}

    obj_parser := obj.parser_create(reader)
    _, ok := obj.parser_parse(&obj_parser)

    if (testing.expectf(
               t,
               ok,
               "Failed to parse the .obj file! \n%s",
               obj.parser_get_errors_string(&obj_parser),
           )) {
        return
    }


}
