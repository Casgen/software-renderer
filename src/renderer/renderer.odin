package renderer

import "core:math/linalg"
import "vendor:x11/xlib"
import "core:slice"
import "core:math"
import "core:fmt"

import "../platform/window"
import "../zmath/color"
import "../zmath"

Renderer :: struct {
    image: window.WindowImage,
    acc_time: f32,
}

Vertex3D :: struct {
    position: linalg.Vector3f32,
    color: color.Color4xF32,
}

Vertex2D :: struct {
    position: linalg.Vector2f32,
    color: color.Color4xF32,
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
draw :: proc(renderer: ^Renderer) {

    a := Vertex2D{position = {0.0, -0.5}, color = {1.0, 0, 0, 0}}
    b := Vertex2D{position = {-0.5, 0.0}, color = {0, 1.0, 0, 0}} 
    c := Vertex2D{position = {0.0,  0.5}, color = {0, 0, 1.0, 0}} 

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
                
    // Transform vertices to project them onto the screen
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

    // Line coefficients. Size of a step per 1 pixel down in the direction of Y
    k_ab := (trans_b.x - trans_a.x) / (trans_b.y - trans_a.y) // For Line A-B
    k_ac := (trans_a.x - trans_c.x) / (trans_c.y - trans_a.y) // For Line A-C
    k_bc := (trans_c.x - trans_b.x) / (trans_c.y - trans_b.y) // For Line B-C

    // Represent one incremental step in X when looping through each scan line.
    x_min_step, x_max_step: f32

    inverted_t: f32
    if is_cw_winding {
        x_min_step = k_ac
        x_max_step = k_ab
        inverted_t := 1
    } else {
        x_min_step = k_ab
        x_max_step = k_ac
        inverted_t := 0
    }

    // Render first top half of the triangle
    // Accumulative X coordinates to fill the triangle line by line.
    // Accumulates by each step. More accurate and faster due to only addition.
    acc_min_x := trans_a.x
    acc_max_x := trans_a.x

    // Cutoff the coordinates to fit within the framebuffer.
    // Would do access out of bounds!
    y_min := u32(math.max(trans_a.y, 0))
    y_max := u32(math.min(trans_b.y, height - 1))

    for y := y_min; y < y_max; y += 1 {

        diff := (f32(y) - trans_a.y) 
        t_ab := diff / (trans_b.y - trans_a.y) // T between A-B
        t_ac := diff / (trans_c.y - trans_a.y) // T between A-C

        acc_min_x += math.round(x_min_step)
        acc_max_x += math.round(x_max_step)

        color_ab := zmath.lerp_4xf32(a.color, b.color, t_ab)
        color_ac := zmath.lerp_4xf32(a.color, c.color, t_ac)

        if (y == y_max - 1) {
            fmt.printfln("t_ab: %.5f, t_ac: %.5f", t_ab, t_ac)
        }
        
        row := y * u32(renderer.image.x_image.width)

        // TODO: Probably could be SIMDed
        for x := u32(acc_min_x); x < u32(acc_max_x); x += 1 {
            // NOTE: See docs why t is calculated this way
            t := math.abs(inverted_t - ((f32(x) - acc_min_x) / (acc_max_x - acc_min_x)))
            color_abc := zmath.lerp_4xf32(color_ab, color_ac, t)
            result_pixel := color.to_u32(color_abc)
            renderer.image.buffer[row + x] = result_pixel
        }
    }

    if is_cw_winding {
        x_max_step = k_bc
    } else {
        x_min_step = k_bc
    }
    
    // Render the bottom half of the triangle
    for y := u32(trans_b.y); y < u32(trans_c.y); y += 1 {
        
        diff := (f32(y) - trans_a.y)

        t_bc := (f32(y) - trans_b.y) / (trans_c.y - trans_b.y) // T between B-C
        t_ac := (f32(y) - trans_a.y) / (trans_c.y - trans_a.y) // T between A-C

        acc_min_x += math.round(x_min_step)
        acc_max_x += math.round(x_max_step)

        color_bc := zmath.lerp_4xf32(b.color, c.color, t_bc)
        color_ac := zmath.lerp_4xf32(a.color, c.color, t_ac)

        row := y * u32(renderer.image.x_image.width)

        // TODO: Probably could be SIMDed
        for x := u32(acc_min_x); x < u32(acc_max_x); x += 1 {
            t := math.abs(inverted_t - ((f32(x) - acc_min_x) / (acc_max_x - acc_min_x)))
            color_abc := zmath.lerp_4xf32(color_bc, color_ac, t)
            result_pixel := color.to_u32(color_abc)
            renderer.image.buffer[row + x] = result_pixel
        }
    }
}
