package obj

import "core:fmt"
import "core:io"
import "core:slice"
import "core:strconv"
import "core:strings"

Invalid_Face : i64 : -1

ObjParser :: struct {
    lexer:                  ObjLexer,
    curr_token, peek_token: Token,
    info:                   ObjInfo,
    errors:                 [dynamic]string,
}

@(private)
ObjModel :: struct {
    vert_pos:       [dynamic]f32,
    vert_tex:       [dynamic]f32,
    vert_norm:      [dynamic]f32,
    vert_par_space: [dynamic]f32,
    polygon_faces:  [dynamic]i64,
}

@(private)
ObjGroup :: struct {
    name:  string,
    model: ObjModel,
}

@(private)
ObjInfo :: struct {
    groups: [dynamic]ObjGroup,
}

parser_create :: proc(reader: io.Reader) -> ObjParser {

    parser: ObjParser
    parser.lexer = lexer_create(reader)
    parser.curr_token = lexer_next_token(&parser.lexer)
    parser.peek_token = lexer_next_token(&parser.lexer)

    return parser
}

parser_next_token :: proc(par: ^ObjParser) {
    par.curr_token = par.peek_token
    par.peek_token = lexer_next_token(&par.lexer)
}

parser_destroy :: proc(par: ^ObjParser) {
    lexer_destroy(&par.lexer)
    delete(par.errors)
}

@(private)
parse_attribute :: proc(par: ^ObjParser, info: ^ObjInfo) {

    #partial switch par.curr_token.type {
    case .Group:
        group_name: string

        if check_peek_token(par, .String) {
            group_name = strings.clone(par.curr_token.data)
        } else {
            group_name = fmt.tprintf("Group_%d", len(info.groups))
        }

        new_group: ObjGroup = {
            name = group_name,
        }

        append(&par.info.groups, new_group)
    case .VertexPosition:
        parse_vertex_position(par, info)
    case .VertexNormal:
        parse_vertex_normal(par, info)
    case .VertexTexture:
        parse_vertex_texture(par, info)
    case .VertexParameterSpace:
        parse_vertex_param_space(par, info)
    case .PolygonFaceElement:
        parse_face_element(par, info)
    case:
        create_error(
            par,
            "Unrecognized or unsupported %v token!",
            par.curr_token.type,
        )
    }
}

@(private)
create_error :: proc(par: ^ObjParser, msg: string, args: ..any) {
    append(&par.errors, fmt.tprintf(msg, args))
}

@(private)
check_curr_token :: proc(par: ^ObjParser, type: TokenType) -> bool {
    if par.curr_token.type == type {
        return true
    }

    create_error(
        par,
        "Unexpected token! Expected %v, got %v!",
        type,
        par.curr_token.type,
    )
    return false
}

@(private)
check_peek_token :: proc(par: ^ObjParser, type: TokenType) -> bool {
    if par.peek_token.type == type {
        return true
    }

    create_error(
        par,
        "Unexpected token! Expected %v, got %v!",
        type,
        par.peek_token.type,
    )
    return false
}

@(private)
parse_vertex_position :: proc(par: ^ObjParser, info: ^ObjInfo) {

    model := slice.last(info.groups[:]).model
    pos_index := len(model.vert_pos)
    append(&model.vert_pos, 0.0, 0.0, 0.0, 1.0)

    for i in 0 ..< 3 {
        parser_next_token(par)
        if !check_curr_token(par, .Number) {
            continue
        }

        value, ok := strconv.parse_f32(par.curr_token.data)
        if !ok {
            create_error(
                par,
                "Failed to parse a vertex position value! %s is an invalid format!",
                par.curr_token.data,
            )
            continue
        }

        model.vert_pos[pos_index + i] = value
    }

    // w-component is optional. If not defined, leave it as 1.0
    if !check_peek_token(par, .Number) {
        return
    }

    parser_next_token(par)

    value, ok := strconv.parse_f32(par.curr_token.data)
    if !ok {
        create_error(
            par,
            "Failed to parse a vertex position value! %s is an invalid format!",
            par.curr_token.data,
        )
        return
    }


    model.vert_pos[pos_index + 3] = value

}

@(private)
parse_vertex_normal :: proc(par: ^ObjParser, info: ^ObjInfo) {
    model := slice.last(info.groups[:]).model
    norm_index := len(model.vert_norm)
    append(&model.vert_norm, 0.0, 0.0, 0.0)

    for i in 0 ..< 3 {
        parser_next_token(par)
        if !check_curr_token(par, .Number) {
            continue
        }

        value, ok := strconv.parse_f32(par.curr_token.data)
        if !ok {
            create_error(
                par,
                "Failed to parse a vertex normal value! %s is an invalid format!",
                par.curr_token.data,
            )
            continue
        }

        model.vert_norm[norm_index + i] = value
    }
}

@(private)
parse_vertex_texture :: proc(par: ^ObjParser, info: ^ObjInfo) {
    model := slice.last(info.groups[:]).model
    tex_index := len(model.vert_tex)
    append(&model.vert_tex, 0.0, 0.0, 0.0)

    for i in 0 ..< 2 {
        parser_next_token(par)
        if !check_curr_token(par, .Number) {
            continue
        }

        value, ok := strconv.parse_f32(par.curr_token.data)
        if !ok {
            create_error(
                par,
                "Failed to parse a vertex position value! %s is an invalid format!",
                par.curr_token.data,
            )
            continue
        }

        model.vert_pos[tex_index + i] = value
    }

    // w-component is optional. If not defined, leave it as 1.0
    if !check_peek_token(par, .Number) {
        return
    }

    parser_next_token(par)

    value, ok := strconv.parse_f32(par.curr_token.data)
    if !ok {
        create_error(
            par,
            "Failed to parse a vertex position value! %s is an invalid format!",
            par.curr_token.data,
        )
        return
    }


    model.vert_pos[tex_index + 2] = value
}

@(private)
parse_vertex_param_space :: proc(par: ^ObjParser, info: ^ObjInfo) {
    model := slice.last(info.groups[:]).model
    par_space_index := len(model.vert_par_space)
    append(&model.vert_par_space, 0.0, 0.0, 0.0)

    parser_next_token(par)
    if check_curr_token(par, .Number) {
        value, ok := strconv.parse_f32(par.curr_token.data)
        if !ok {
            create_error(
                par,
                "Failed to parse a vertex position value! %s is an invalid format!",
                par.curr_token.data,
            )
        } else {
            model.vert_pos[par_space_index + 0] = value
        }
    }


    // v-component and w-component is optional. If not defined, leave it as 1.0
    for i in 1 ..< 3 {
        if !check_peek_token(par, .Number) {
            return
        }

        parser_next_token(par)

        value, ok := strconv.parse_f32(par.curr_token.data)
        if !ok {
            create_error(
                par,
                "Failed to parse a vertex position value! %s is an invalid format!",
                par.curr_token.data,
            )
            continue
        }

        model.vert_pos[par_space_index + i] = value
    }

}

@(private)
parse_face_element :: proc(par: ^ObjParser, info: ^ObjInfo) {
    for i in i..<3 {

        if check_curr_token(par, .Number) {
            value, ok := strconv.parse_f32(par.curr_token.data)
            if !ok {
                create_error(
                    par,
                    "Failed to parse a vertex position value! %s is an invalid format!",
                    par.curr_token.data,
                )
                continue
            }
        }

    }

}

parser_parse :: proc(par: ^ObjParser) -> (ObjInfo, bool) {
    info: ObjInfo

    for par.curr_token.type != .EOF {
        parse_attribute(par, &info)
        parser_next_token(par)
    }

    return info, len(par.errors) == 0
}


obj_info_destroy :: proc(info: ^ObjInfo) {


}

