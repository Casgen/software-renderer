package renderer

import "core:math/linalg"
import "vendor:x11/xlib"
import "core:slice"
import "core:math"

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
    b := Vertex2D{position = {-0.5, 0.0}, color = {0, 255, 0, 0}} 
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
    is_cw_winding := -ac_vec.x * bc_vec.y + bc_vec.x * ac_vec.y > 0

    if (is_cw_winding) {
        // Render first top half of the triangle
        for y := u32(trans_a.y); y < u32(trans_b.y); y += 1 {
            t1 := (trans_b.y - f32(y)) / (trans_b.y - trans_a.y) // For Line A-B
            t2 := (f32(y) - trans_c.y) / (trans_c.y - trans_a.y) // For Line A-C

            x_min := u32(zmath.lerp_f32(trans_b.x, trans_a.x, t1))
            x_max := u32(zmath.lerp_f32(trans_a.x, trans_c.x, t2))
            
            row := y * u32(renderer.image.x_image.width)

            for x := x_min; x < x_max; x += 1 {
                renderer.image.buffer[row + x] = 0x00FF00
            }
        }

        // Render the bottom half of the triangle
        for y := u32(trans_b.y); y < u32(trans_c.y); y += 1 {
            t1 := (f32(y) - trans_b.y) / (trans_c.y - trans_b.y) // For Line B-C
            t2 := (f32(y) - trans_c.y) / (trans_c.y - trans_a.y) // For Line A-C

            x_min := u32(zmath.lerp_f32(trans_b.x, trans_c.x, t1))
            x_max := u32(zmath.lerp_f32(trans_a.x, trans_c.x, t2))

            row := y * u32(renderer.image.x_image.width)

            for x := x_min; x < x_max; x += 1 {
                renderer.image.buffer[row + x] = 0x00FF00
            }
        }
    } else {
        // NOTE: If the winding is counter-clockwise, just switch the x_max
        // and x_min
        for y := u32(trans_a.y); y < u32(trans_b.y); y += 1 {
            t1 := (trans_b.y - f32(y)) / (trans_b.y - trans_a.y) // For Line A-B
            t2 := (f32(y) - trans_c.y) / (trans_c.y - trans_a.y) // For Line A-C

            x_max := u32(zmath.lerp_f32(trans_b.x, trans_a.x, t1))
            x_min := u32(zmath.lerp_f32(trans_a.x, trans_c.x, t2))
            
            row := y * u32(renderer.image.x_image.width)

            for x := x_min; x < x_max; x += 1 {
                renderer.image.buffer[row + x] = 0x00FF00
            }
        }

        for y := u32(trans_b.y); y < u32(trans_c.y); y += 1 {
            t1 := (f32(y) - trans_b.y) / (trans_c.y - trans_b.y) // For Line B-C
            t2 := (f32(y) - trans_c.y) / (trans_c.y - trans_a.y) // For Line A-C

            x_max := u32(zmath.lerp_f32(trans_b.x, trans_c.x, t1))
            x_min := u32(zmath.lerp_f32(trans_a.x, trans_c.x, t2))

            row := y * u32(renderer.image.x_image.width)

            for x := x_min; x < x_max; x += 1 {
                renderer.image.buffer[row + x] = 0x00FF00
            }
        }
    }
    
}
