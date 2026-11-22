package tests

import "core:io"
import "core:log"
import "core:testing"

import "../core/formats/obj"

@(test)
obj_lexer_test :: proc(t: ^testing.T) {
    LegalToken :: struct {
        data: string,
        type: obj.TokenType,
    }

    
    legal_tokens := []LegalToken {
        {"g", .Group},
        {"cube", .String},

        {"v", .VertexPosition},
        {"1.0", .Number},
        {"2.0", .Number},
        {"3.0", .Number},

        {"vn", .VertexNormal},
        {"1.0", .Number},
        {"2.0", .Number},
        {"3.0", .Number},

        {"vt", .VertexTexture},
        {"1.0", .Number},
        {"2", .Number},

        {"f", .PolygonFaceElement},

        {"1", .Number},
        {"2", .Number},
        {"3", .Number},

        {"f", .PolygonFaceElement},

        {"1", .Number},
        {"/", .FwdSlash},
        {"2", .Number},
        {"3", .Number},
        {"/", .FwdSlash},
        {"4", .Number},

        {"f", .PolygonFaceElement},

        {"1", .Number},
        {"/", .FwdSlash},
        {"/", .FwdSlash},
        {"2", .Number},
        {"3", .Number},
        {"/", .FwdSlash},
        {"/", .FwdSlash},
        {"4", .Number},
        {"5", .Number},
        {"/", .FwdSlash},
        {"/", .FwdSlash},
        {"6", .Number},

        {"f", .PolygonFaceElement},

        {"1", .Number},
        {"/", .FwdSlash},
        {"2", .Number},
        {"/", .FwdSlash},
        {"3", .Number},
        {"4", .Number},
        {"/", .FwdSlash},
        {"5", .Number},
        {"/", .FwdSlash},
        {"6", .Number},
        {"7", .Number},
        {"/", .FwdSlash},
        {"8", .Number},
        {"/", .FwdSlash},
        {"9", .Number},

        {"", .EOF},
    }

    actual_tokens: [dynamic]obj.Token = make_dynamic_array_len_cap(
        [dynamic]obj.Token,
        0,
        len(legal_tokens),
    )
    defer delete(actual_tokens)


    reader, err := open_file_and_create_reader("res/tests/cube.obj")
    if !testing.expectf(
        t,
        err == nil,
        "Failed to open a file! %v",
        err,
    ) {return}

    defer {
        err := io.close(reader)
        if err != nil {
            log.warnf("Failed to close a file! %v", err)
        }
    }

    lexer := obj.lexer_create(reader)
    defer obj.lexer_destroy(&lexer)


    token := obj.Token {
        data = "",
        type = .Illegal,
    }

    for token.type != .EOF {
        token = obj.lexer_next_token(&lexer)
        append(&actual_tokens, obj.Token{data = token.data, type = token.type})
    }

    testing.expectf(
        t,
        len(actual_tokens) == len(legal_tokens),
        "Number of tokens doesn't match! %d != %d",
        len(legal_tokens),
        len(actual_tokens),
    )

    for i in 0 ..< len(legal_tokens) {
        testing.expectf(
            t,
            legal_tokens[i].data == actual_tokens[i].data,
            "Token text doesn't match! \"%s\" != \"%s\"",
            legal_tokens[i].data,
            actual_tokens[i].data,
        )

        testing.expectf(
            t,
            legal_tokens[i].type == actual_tokens[i].type,
            "Token type doesn't match! \"%s\" != \"%s\"",
            legal_tokens[i].type,
            actual_tokens[i].type,
        )
    }

}
