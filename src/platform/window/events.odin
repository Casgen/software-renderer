package platform

import "../input"
import "../../core"

Resize_Window :: struct {
    image: ^core.Image,
    width: u32,
    height: u32
}

Key_Released :: struct {
    keycode: input.Key_Code,
    x, y: i32,
}

Key_Pressed :: struct {
    keycode: input.Key_Code,
    x, y: i32,
}

MouseBtn_Pressed :: struct {
    button: input.MouseBtn_Code,
    x, y: i32,
}

MouseBtn_Released :: struct {
    button: input.MouseBtn_Code,
    x, y: i32,
}

Pointer_Moved :: struct {
    pos: [2]i32, // x, y
}

Destroy_Window :: struct {}
Null :: struct {}

Event :: union {
    Null,
    Resize_Window,
    Key_Released,
    Key_Pressed,
    MouseBtn_Released,
    MouseBtn_Pressed,
    Destroy_Window,
    Pointer_Moved,
}
