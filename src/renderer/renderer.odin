package renderer

import "core:math/linalg"
import "vendor:x11/xlib"
import "core:slice"
import "core:math/fixed"

import "../platform/window"
import "../zmath"

Renderer :: struct {
    image: window.WindowImage,
}

Vertex3D :: struct {
    position: linalg.Vector3f32,
    color: [4]u8,
}

Vertex2D :: struct {
    position: linalg.Vector2f32,
    color: [4]u8,
}

Topology_Type :: enum {
    Triangle_List
}

Object :: struct {
    vertex_buffer: []Vertex3D,
    index_buffer: []u32,
    topology_type: Topology_Type 
}

// TODO: Do not directly access the x_image struct
fill_screen :: proc(renderer: ^Renderer) {
    for y in 0..<renderer.image.x_image.height {

        y_offset := y * renderer.image.x_image.width
        for x in 0..<renderer.image.x_image.width {
            pixel: [4]u8 = {
                u8(x % 256), // B
                u8(y % 256), // G
                128,         // R
                255,         // A
            }

            renderer.image.buffer[y_offset + x] = transmute(u32)pixel
        }
    }

}

draw :: proc(renderer: ^Renderer) {

    a := Vertex2D{position = {0.0, -0.5}, color = {255, 0, 0, 0}}
    b := Vertex2D{position = {0.5, 0.0}, color = {0, 255, 0, 0}} 
    c := Vertex2D{position = {0.0,  0.5}, color = {0, 0, 255, 0}} 

    // Sort vertices from top to bottom
    if (c.position.y < b.position.y) {
        temp := c
        c = b
        b = temp
    }

    if (b.position.y < a.position.y) {
        temp := b
        b = a
        a = temp
    }

    if (c.position.y < b.position.y) {
        temp := c
        c = b
        b = temp
    }
                
    width: f32 = f32(renderer.image.x_image.width)
    height: f32 = f32(renderer.image.x_image.height)

    // TODO: Might have to deal with odd value width and height...
    trans_a: [2]f32 = {(a.position.x + 1.0) * 0.5 * width,
                       (a.position.y + 1.0) * 0.5 * height}
    trans_b: [2]f32 = {(b.position.x + 1.0) * 0.5 * width,
                       (b.position.y + 1.0) * 0.5 * height}
    trans_c: [2]f32 = {(c.position.x + 1.0) * 0.5 * width,
                       (c.position.y + 1.0) * 0.5 * height}


    // Check whether the triangle has counter clock-wise or clock-wise winding.
    ac_vec := a.position - c.position
    bc_vec := b.position - c.position
    is_cw_winding := -ac_vec.x * bc_vec.y + bc_vec.x * ac_vec.y < 0

    // Line coefficients (size of a step per pixel).
    k_ab := (trans_b.x - trans_a.x) / (trans_b.y - trans_a.y) // For Line A-B
    k_ac := (trans_a.x - trans_c.x) / (trans_c.y - trans_a.y) // For Line A-C
    k_bc := (trans_c.x - trans_b.x) / (trans_c.y - trans_b.y) // For Line B-C

    x_min_step, x_max_step: f32
    if is_cw_winding {
        x_min_step = k_ac
        x_max_step = k_ab
    } else {
        x_min_step = k_ab
        x_max_step = k_ac
    }

    // Render first top half of the triangle
    acc_min_x := trans_a.x
    acc_max_x := trans_a.x

    for y := u32(trans_a.y); y < u32(trans_b.y); y += 1 {

        acc_min_x += x_min_step
        acc_max_x += x_max_step
        
        row := y * u32(renderer.image.x_image.width)

        // TODO: Probably could be SIMDed
        for x := u32(acc_min_x); x < u32(acc_max_x); x += 1 {
            renderer.image.buffer[row + x] = 0x00FF00
        }
    }

    if is_cw_winding {
        x_max_step = k_bc
    } else {
        x_max_step = k_ac
    }


    // Render the bottom half of the triangle
    for y := u32(trans_b.y); y < u32(trans_c.y); y += 1 {
        acc_min_x += x_min_step
        acc_max_x += x_max_step

        row := y * u32(renderer.image.x_image.width)

        // TODO: Probably could be SIMDed
        for x := u32(acc_min_x); x < u32(acc_max_x); x += 1 {
            renderer.image.buffer[row + x] = 0x00FF00
        }
    }
}
