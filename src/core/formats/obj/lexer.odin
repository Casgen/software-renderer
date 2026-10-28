package obj

import "core:bufio"
import "core:fmt"
import "core:io"
import "core:mem/virtual"

ObjLexer :: struct {
    reader:    bufio.Reader,
    curr_char: byte,
    peek_char: byte,
    arena:     virtual.Arena,
}

@(private)
EOF: byte : 0

lexer_read_char :: proc(lexer: ^ObjLexer) {
    lexer.curr_char = lexer.peek_char

    err: io.Error
    lexer.peek_char, err = bufio.reader_read_byte(&lexer.reader)

    #partial switch err {
    case .EOF:
        lexer.peek_char = EOF
    case .None:
    case:
        fmt.panicf("Failed to read an OBJ format! %v", err)
    }
}

@(private)
create_token :: proc(lexer: ^ObjLexer, str: string, type: TokenType) -> Token {

    data, err := virtual.make(&lexer.arena, []byte, len(str))
    fmt.assertf(err == nil, "Failed to allocate a string in arena! %v", err)

    for i in 0 ..< len(str) {
        data[i] = str[i]
    }

    return {data = string(data), type = type}
}


lexer_create :: proc(reader: io.Reader) -> ObjLexer {
    lexer: ObjLexer

    bufio.reader_init(&lexer.reader, reader)

    arena_err := virtual.arena_init_growing(&lexer.arena)
    fmt.assertf(arena_err == nil, "Failed to Arena! %v", arena_err)

    lexer_read_char(&lexer)
    lexer_read_char(&lexer)

    return lexer
}

lexer_destroy :: proc(lexer: ^ObjLexer) {
    virtual.arena_destroy(&lexer.arena)
    bufio.reader_destroy(&lexer.reader)

    lexer.peek_char = 0
    lexer.curr_char = 0
}

@(private)
parse_vertex_element :: proc(lexer: ^ObjLexer) -> Token {

    defer lexer_read_char(lexer)

    switch lexer.peek_char {
    case 't':
        return create_token(lexer, "vt", .VertexTexture)
    case 'n':
        return create_token(lexer, "vn", .VertexNormal)
    case ' ':
        return create_token(lexer, "v", .VertexPosition)
    case:
        wrong_token: [2]byte = {lexer.curr_char, lexer.peek_char}
        return create_token(lexer, string(wrong_token[:]), .Illegal)
    }
}

@(private)
read_number :: proc(lexer: ^ObjLexer) -> string {
    num: [dynamic]byte

    for is_digit(lexer.curr_char) || lexer.curr_char == '.' {
        append(&num, lexer.curr_char)
        lexer_read_char(lexer)
    }

    return string(num[:])
}

@(private)
read_string :: proc(lexer: ^ObjLexer) -> string {
    str: [dynamic]byte

    for is_letter(lexer.curr_char) {
        append(&str, lexer.curr_char)
        lexer_read_char(lexer)
    }

    return string(str[:])
}

@(private)
is_new_line :: proc(lexer: ^ObjLexer) -> (result: bool, is_crlf: bool) {
    if lexer.curr_char == '\n' {
        result = true
    } else if lexer.curr_char == '\r' && lexer.peek_char == '\n' {
        result = true
        is_crlf = true
    }

    return
}

skip_whitespace_or_comments :: proc(lexer: ^ObjLexer) {

    for is_whitespace(lexer.curr_char) || lexer.curr_char == '#' {
        // SKip whitespace
        for is_whitespace(lexer.curr_char) {
            lexer_read_char(lexer)
        }

        // Skip comment
        for lexer.curr_char == '#' {
            new_line, is_crlf: bool

            for !new_line {
                lexer_read_char(lexer)
                new_line, is_crlf = is_new_line(lexer)
            }

            if is_crlf {
                lexer_read_char(lexer) // if newline is CRLF, Skip over '\r'
            }
            lexer_read_char(lexer) // skip over \n
        }
    }
}

lexer_next_token :: proc(lexer: ^ObjLexer) -> Token {

    skip_whitespace_or_comments(lexer)

    token: Token
    switch lexer.curr_char {
    case 'v':
        token = parse_vertex_element(lexer)
    case 'f':
        token = create_token(lexer, "f", .PolygonFaceElement)
    case '/':
        token = create_token(lexer, "/", .FwdSlash)
    case '[':
        token = create_token(lexer, "[", .LeftBracket)
    case ']':
        token = create_token(lexer, "]", .RightBracket)
    case 's':
        token = create_token(lexer, "s", .UseSmoothShading)
    case 'g':
        token = create_token(lexer, "g", .Group)
    case EOF:
        token = create_token(lexer, "", .EOF)
    case:
        if is_digit(lexer.curr_char) {
            num := read_number(lexer)
            defer delete(num)
            token = create_token(lexer, num, .Number)

            return token
        } else if is_letter(lexer.curr_char) {
            str := read_string(lexer)
            defer delete(str)

            type, ok := keywords_map[str]

            if !ok {
                type = .String
            }

            token = create_token(lexer, str, type)
            return token
        } else {
            // If nothing matches, create an illegal token.
            wrong_token: [1]byte = {lexer.curr_char}
            token = create_token(lexer, string(wrong_token[:]), .Illegal)
        }
    // TODO: Implement other elements?
    }

    lexer_read_char(lexer)

    return token
}

@(private)
is_whitespace :: proc(char: byte) -> bool {
    return char == ' ' || char == '\t' || char == '\r' || char == '\n'
}


@(private)
is_digit :: proc(char: byte) -> bool {
    return char >= '0' && char <= '9'
}

@(private)
is_letter :: proc(char: byte) -> bool {
    MASK: byte : 0b11011111

    // Mask out the particular bit to convert it to uppercase letter
    uppercase_l := char & MASK
    return uppercase_l >= 'A' && uppercase_l <= 'Z'
}

