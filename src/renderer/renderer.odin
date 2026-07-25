package renderer

import "core:math/linalg"
import "core:math"
import "core:fmt"
import "core:math/rand"
import "core:reflect"
import "core:time"

import "../platform/window"
import "../core/zmath/color"
import "../core/zmath"
import "../platform/input"
import "../core"
import "../core/model"


Mouse_State :: struct {
    pos: [2]i32,
    lmb_pressed: bool,
    rmb_pressed: bool,
}

Renderer :: struct {
    image: ^core.Image,
    depth_buffer: DepthBuffer,
    acc_time: f32,
    camera: Camera,
    mouse_state: Mouse_State,
}

dispatch_event :: proc(renderer: ^Renderer, event: window.Event) {
    #partial switch event_type in event {
    case window.Resize_Window:
        renderer.image = event_type.image

        depth_buffer_destroy(&renderer.depth_buffer)
        renderer.depth_buffer = depth_buffer_create(event_type.width,
            event_type.height)

        camera_set_resolution(&renderer.camera, event_type.width,
            event_type.height)
    case window.Key_Released: on_key_released(renderer, event_type)
    case window.Key_Pressed: on_key_pressed(renderer, event_type)
    case window.MouseBtn_Released: on_mousebtn_released(renderer, event_type)
    case window.MouseBtn_Pressed: on_mousebtn_pressed(renderer, event_type)
    case window.Pointer_Moved: on_mouse_moved(renderer, event_type)
    case window.Null: // Do nothing
    case:
        fmt.printfln("Unhandled event! %v", reflect.union_variant_typeid(
            event))
    }

}

on_key_released :: proc(renderer: ^Renderer, event: window.Key_Released) {
    #partial switch event.keycode {
    case .KB_W:
        camera_set_move_forward(&renderer.camera, false)
    case .KB_A:
        camera_set_move_left(&renderer.camera, false)
    case .KB_S:
        camera_set_move_backwards(&renderer.camera, false)
    case .KB_D:
        camera_set_move_right(&renderer.camera, false)
    }
}

on_key_pressed :: proc(renderer: ^Renderer, event: window.Key_Pressed) {
    #partial switch event.keycode {
    case .KB_W:
        camera_set_move_forward(&renderer.camera, true)
    case .KB_A:
        camera_set_move_left(&renderer.camera, true)
    case .KB_S:
        camera_set_move_backwards(&renderer.camera, true)
    case .KB_D:
        camera_set_move_right(&renderer.camera, true)
    }
}

on_mousebtn_released :: proc(
    renderer: ^Renderer,
    event: window.MouseBtn_Released
) {
    #partial switch event.button {
    case .LMB: renderer.mouse_state.lmb_pressed = false
    case .RMB: renderer.mouse_state.rmb_pressed = false
    }
}

on_mousebtn_pressed :: proc(
    renderer: ^Renderer,
    event: window.MouseBtn_Pressed
) {
    #partial switch event.button {
    case .LMB: renderer.mouse_state.lmb_pressed = true
    case .RMB: renderer.mouse_state.rmb_pressed = true
    }
}

on_mouse_moved :: proc(renderer: ^Renderer, event: window.Pointer_Moved) {
    pos_diff := event.pos - renderer.mouse_state.pos
    if renderer.mouse_state.rmb_pressed {
        camera_yaw(&renderer.camera, -f32(pos_diff.x))
        camera_pitch(&renderer.camera, f32(pos_diff.y))
    }
    renderer.mouse_state.pos = event.pos
}


create_renderer :: proc(image: ^core.Image) -> Renderer {
    return {
        image = image,
        depth_buffer = depth_buffer_create(u32(image.width), u32(image.height)),
        camera = camera_create({0, 0, -1}, {0, 0, 0},
            u32(image.width), u32(image.height)),
        acc_time = 0.0
    }
}

destroy_renderer :: proc(renderer: ^Renderer) {
    depth_buffer_destroy(&renderer.depth_buffer)
}

render_update :: proc(renderer: ^Renderer, delta_time: time.Duration) {
    camera_update(&renderer.camera, f32(time.duration_seconds(delta_time)))
    renderer.acc_time += f32(time.duration_seconds(delta_time))
}

render_clear :: proc(renderer: ^Renderer) {
    window.clear_image(renderer.image)
    depth_buffer_clear(&renderer.depth_buffer)
}

random_vertex_2d :: proc() -> model.Vertex2D{

    x := rand.float32() * 2.0 - 1.0
    y := rand.float32() * 2.0 - 1.0

    return model.Vertex2D{linalg.Vector2f32{x, y}, color.rand_color4xf32()}
}

random_vertex_4d :: proc() -> model.Vertex4D {

    x := rand.float32() - 0.5
    y := rand.float32() - 0.5
    z := rand.float32() - 0.5

    return model.Vertex4D{
        linalg.Vector4f32{x, y, z, 1.0},
        color.rand_color4xf32()
    }
}

generate_random_2d_triangles :: proc(count: u32) -> []model.Triangle2D {

    triangles := make([]model.Triangle2D, count)

    for i in 0..<len(triangles) {
        triangles[i] = model.Triangle2D{
            a = random_vertex_2d(),
            b = random_vertex_2d(),
            c = random_vertex_2d(),
        }
    }

    return triangles

    // triangles := make([]Triangle2D, 1)
    //
    // for i in 0..<len(triangles) {
    //     triangles[i] = Triangle2D{
    //         a = Point2D{{-0.968523502, -0.777187109}, color.rand_color4xf32()},
    //         b = Point2D{{-0.533231378, 0.087064743}, color.rand_color4xf32()},
    //         c = Point2D{{-0.244763136, 0.0905495882}, color.rand_color4xf32()},
    //     }
    // }
    //
    // return triangles
}

generate_random_3d_triangles :: proc(count: u32) -> []model.Triangle3D {

    // triangles := make([]core.Triangle3D, count)
    //
    // for i in 0..<len(triangles) {
    //     triangles[i] = core.Triangle3D{
    //         a = random_vertex_4d(),
    //         b = random_vertex_4d(),
    //         c = random_vertex_4d(),
    //     }
    // }
    //
    // return triangles

    triangles := make([]model.Triangle3D, 1)
    
    for i in 0..<len(triangles) {
        triangles[i] = model.Triangle3D{
            a = model.Vertex4D{{0, 0.5, 0, 1}, color.rand_color4xf32()},
            b = model.Vertex4D{{-0.5, 0, 0, 1}, color.rand_color4xf32()},
            c = model.Vertex4D{{0, -0.5, 0, 1}, color.rand_color4xf32()},
        }
    }
    
    return triangles
}

draw :: proc(renderer: ^Renderer, triangles: []model.Triangle2D) {
    for &triangle in triangles {
        a := &triangle.a
        b := &triangle.b
        c := &triangle.c

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


        width: f32 = f32(renderer.image.width)
        height: f32 = f32(renderer.image.height)

        // Transform vertices to project them onto the screen
        // TODO: Might have to deal with odd value width and height...
        trans_a: [2]f32 = {math.floor_f32((a.position.x + 1.0) * 0.5 * width),
                           math.floor_f32((a.position.y + 1.0) * 0.5 * height)}
        trans_b: [2]f32 = {math.floor_f32((b.position.x + 1.0) * 0.5 * width),
                           math.floor_f32((b.position.y + 1.0) * 0.5 * height)}
        trans_c: [2]f32 = {math.floor_f32((c.position.x + 1.0) * 0.5 * width),
                           math.floor_f32((c.position.y + 1.0) * 0.5 * height)}


        // Check whether the triangle has counter clock-wise or clock-wise winding.
        ac_vec := a.position - c.position
        bc_vec := b.position - c.position
        is_cw_winding := -ac_vec.x * bc_vec.y + bc_vec.x * ac_vec.y < 0

        // Cutoff the coordinates to fit within the framebuffer.
        // Would do access out of bounds!
        y_min := i32(math.max(trans_a.y, 0))
        y_max := i32(math.min(trans_b.y, height - 1))

        inverted_t: f32 = is_cw_winding ? 1.0 : 0.0

        for y := y_min; y < y_max; y += 1 {

            diff := (f32(y) - trans_a.y) 
            t_ab := diff / (trans_b.y - trans_a.y) // T between A-B
            t_ac := diff / (trans_c.y - trans_a.y) // T between A-C

            color_ab := zmath.lerp_4xf32(a.color, b.color, t_ab)
            color_ac := zmath.lerp_4xf32(a.color, c.color, t_ac)

            x1 := i32(zmath.lerp_f32(trans_a.x, trans_b.x, t_ab))
            x2 := i32(zmath.lerp_f32(trans_a.x, trans_c.x, t_ac))

            // TODO: can this be done outisde of this for loop? Investigate
            if x1 > x2 {
                temp := x1
                x1 = x2
                x2 = temp
            }

            x_min := math.max(x1, 0)
            x_max := math.min(x2, i32(renderer.image.width) - 1)

            row := y * i32(renderer.image.width)

            // TODO: Probably could be SIMDed
            for x := x_min; x < x_max; x += 1 {
                t := math.abs(inverted_t - (f32(x - x1) / f32(x2 - x1)))
                color_abc := zmath.lerp_4xf32(color_ab, color_ac, t)
                result_pixel := color.to_u32(color_abc)
                renderer.image.buffer[row + x] = result_pixel
            }
        }

        y_min = i32(math.max(trans_b.y, 0))
        y_max = i32(math.min(trans_c.y, height - 1))

        // Render the bottom half of the triangle
        for y := y_min; y < y_max; y += 1 {
            t_bc := (f32(y) - trans_b.y) / (trans_c.y - trans_b.y) // T between B-C
            t_ac := (f32(y) - trans_a.y) / (trans_c.y - trans_a.y) // T between A-C

            color_bc := zmath.lerp_4xf32(b.color, c.color, t_bc)
            color_ac := zmath.lerp_4xf32(a.color, c.color, t_ac)

            x1 := i32(zmath.lerp_f32(trans_b.x, trans_c.x, t_bc))
            x2 := i32(zmath.lerp_f32(trans_a.x, trans_c.x, t_ac))

            if x1 > x2 {
                temp := x1
                x1 = x2
                x2 = temp
            }

            x_min := math.max(x1, 0)
            x_max := math.min(x2, i32(renderer.image.width) - 1)

            row := y * i32(renderer.image.width)

            // TODO: Probably could be SIMDed
            for x := x_min; x < x_max; x += 1 {
                t := math.abs(inverted_t - (f32(x - x1) / f32(x2 - x1)))
                color_abc := zmath.lerp_4xf32(color_bc, color_ac, t)
                result_pixel := color.to_u32(color_abc)
                renderer.image.buffer[row + x] = result_pixel
            }
        }
    }
}

draw_3d :: proc(renderer: ^Renderer, triangles: []model.Triangle3D) {
    for i in 0..<len(triangles) {
        tri := triangles[i]
        tri.a.position = renderer.camera.proj_matrix *
                         renderer.camera.view_matrix *
                         tri.a.position
        tri.b.position = renderer.camera.proj_matrix *
                         renderer.camera.view_matrix *
                         tri.b.position
        tri.c.position = renderer.camera.proj_matrix *
                         renderer.camera.view_matrix *
                         tri.c.position

        tri.a.position /= tri.a.position.w
        tri.b.position /= tri.b.position.w
        tri.c.position /= tri.c.position.w

        a := &tri.a
        b := &tri.b
        c := &tri.c

        // Sort vertices from bottom to top C-B-A (After the Y-flipping, the A
        // vertex is at the top (A-B-C)
        if (c.position.y > b.position.y) {
            temp := c
            c = b
            b = temp
        }

        if (b.position.y > a.position.y) {
            temp := b
            b = a
            a = temp
        }

        if (c.position.y > b.position.y) {
            temp := c
            c = b
            b = temp
        }


        width: f32 = f32(renderer.image.width)
        height: f32 = f32(renderer.image.height)

        
        trans_a: [2]f32 = {math.floor((a.position.x + 1.0) * 0.5 * width),
                           math.floor((1.0 - a.position.y) * 0.5 * height)}
        trans_b: [2]f32 = {math.floor((b.position.x + 1.0) * 0.5 * width),
                           math.floor((1.0 - b.position.y) * 0.5 * height)}
        trans_c: [2]f32 = {math.floor((c.position.x + 1.0) * 0.5 * width),
                           math.floor((1.0 - c.position.y) * 0.5 * height)}


        // Check whether the triangle has counter clock-wise or clock-wise
        // winding.
        ac_vec := trans_a - trans_c
        bc_vec := trans_b - trans_c
        is_cw_winding := -ac_vec.x * bc_vec.y + bc_vec.x * ac_vec.y < 0

        // FIXME: Cutoff the coordinates to fit within the framebuffer.
        // Would do access out of bounds!
        y_min := i32(math.max(trans_a.y, 0))
        y_max := i32(math.min(trans_b.y, height - 1))

        inverted_t: f32 = is_cw_winding ? 1.0 : 0.0

        for y := y_min; y < y_max; y += 1 {
            diff := (f32(y) - trans_a.y) 
            t_ab := diff / (trans_b.y - trans_a.y) // T between A-B
            t_ac := diff / (trans_c.y - trans_a.y) // T between A-C

            color_ab := zmath.lerp_4xf32(a.color, b.color, t_ab)
            color_ac := zmath.lerp_4xf32(a.color, c.color, t_ac)

            x1 := i32(zmath.lerp_f32(trans_a.x, trans_b.x, t_ab))
            x2 := i32(zmath.lerp_f32(trans_a.x, trans_c.x, t_ac))

            z1 := zmath.lerp_f32(a.position.z, b.position.z, t_ab)
            z2 := zmath.lerp_f32(a.position.z, c.position.z, t_ac)

            // TODO: can this be done outisde of this for loop? Investigate
            if x1 > x2 {
                temp := x1
                x1 = x2
                x2 = temp
            }

            x_min := math.max(x1, 0)
            x_max := math.min(x2, i32(renderer.image.width) - 1)

            row := y * i32(renderer.image.width)

            // TODO: Probably could be SIMDed
            for x := x_min; x < x_max; x += 1 {
                t := math.abs(inverted_t - (f32(x - x1) / f32(x2 - x1)))
                i := row + x
                z := zmath.lerp_f32(z1, z2, t)
                
                if depth_buffer_write(&renderer.depth_buffer, u32(x), u32(y), z) {
                    color_abc := zmath.lerp_4xf32(color_ab, color_ac, t)
                    result_pixel := color.to_u32(color_abc)
                    renderer.image.buffer[i] = result_pixel
                }
            }
        }

        y_min = i32(math.max(trans_b.y, 0))
        y_max = i32(math.min(trans_c.y, height - 1))

        // Render the bottom half of the triangle
        for y := y_min; y < y_max; y += 1 {
            t_bc := (f32(y) - trans_b.y) / (trans_c.y - trans_b.y) // T between B-C
            t_ac := (f32(y) - trans_a.y) / (trans_c.y - trans_a.y) // T between A-C

            color_bc := zmath.lerp_4xf32(b.color, c.color, t_bc)
            color_ac := zmath.lerp_4xf32(a.color, c.color, t_ac)

            x1 := i32(zmath.lerp_f32(trans_b.x, trans_c.x, t_bc))
            x2 := i32(zmath.lerp_f32(trans_a.x, trans_c.x, t_ac))

            z1 := zmath.lerp_f32(b.position.z, c.position.z, t_bc)
            z2 := zmath.lerp_f32(a.position.z, c.position.z, t_ac)

            if x1 > x2 {
                temp := x1
                x1 = x2
                x2 = temp
            }

            x_min := math.max(x1, 0)
            x_max := math.min(x2, i32(renderer.image.width) - 1)

            row := y * i32(renderer.image.width)

            // TODO: Probably could be SIMDed
            for x := x_min; x < x_max; x += 1 {
                t := math.abs(inverted_t - (f32(x - x1) / f32(x2 - x1)))
                i := row + x

                z := zmath.lerp_f32(z1, z2, t)

                if depth_buffer_write(&renderer.depth_buffer, u32(x), u32(y), z) {
                    color_abc := zmath.lerp_4xf32(color_bc, color_ac, t)
                    result_pixel := color.to_u32(color_abc)
                    renderer.image.buffer[row + x] = result_pixel
                }

            }
        }
    }
}

draw_line_2d :: proc(renderer: ^Renderer, lines: []model.Line2D) {
    for i in 0..<len(lines) {
        line := &lines[i]

        resolution: [2]f32 = {f32(renderer.image.width),
                              f32(renderer.image.height)}

        model.line_liang_barsky_clip_2d(-1.0, 1.0, -1.0, 1.0, line)
        
        // TODO: Transformation could be SIMDed?
        trans_a := [2]f32{
            math.floor((line.a.position.x + 1.0) * 0.5 * (resolution.x - 1)),
            math.floor((1.0 - line.a.position.y) * 0.5 * (resolution.y - 1))
        }
        trans_b := [2]f32{
            math.floor((line.b.position.x + 1.0) * 0.5 * (resolution.x - 1)),
            math.floor((1.0 - line.b.position.y) * 0.5 * (resolution.y - 1))
        }

        dx := trans_b.x - trans_a.x
        dy := trans_b.y - trans_a.y

        x_inc, y_inc: f32
        max: u32

        step: f32 = math.abs(dx) >= math.abs(dy) ? math.abs(dx) : math.abs(dy)

        dx = dx / step
        dy = dy / step

        d_rgba := (line.b.color - line.a.color) / linalg.Vector4f32{step, step,
            step, step}

        x := trans_a.x
        y := trans_a.y

        rgba: color.Color4xF32 = line.b.color

        // TODO: fix crashing when lines go out of bounds
        for i := 0; i <= int(step); i += 1 {
            x += dx
            y += dy

            rgba += d_rgba

            put_pixel(renderer.image, u32(x), u32(y), color.to_u32(rgba))
        }
    }
}


// TODO: Maybe convert this into a fixed point calculation if possible
draw_line_3d :: proc(renderer: ^Renderer, lines: []model.Line3D) {
    for i in 0..<len(lines) {
        line := &lines[i]
        line.a.position = renderer.camera.proj_matrix *
                          renderer.camera.view_matrix *
                          line.a.position
        line.b.position = renderer.camera.proj_matrix *
                          renderer.camera.view_matrix *
                          line.b.position

        // TODO: Do fast clipping.
        if (line.a.position.x < -line.a.position.w || line.a.position.x > line.a.position.w) &&
           (line.b.position.x < -line.b.position.w || line.b.position.x > line.b.position.w) {
            return 
        }

        line.a.position /= line.a.position.w
        line.b.position /= line.b.position.w
        
        // TODO: Maybe this is unecessary to do after every line.
        // Precompute this during init
        resolution: [2]f32 = {f32(renderer.image.width),
                              f32(renderer.image.height)}

        if !model.line_liang_barsky_clip_3d(-1.0, 1.0, -1.0, 1.0, line) do return 


        trans_a := [2]f32{
            math.floor((line.a.position.x + 1.0) * 0.5 * (resolution.x - 1)),
            math.floor((1.0 - line.a.position.y) * 0.5 * (resolution.y - 1))
        }
        trans_b := [2]f32{
            math.floor((line.b.position.x + 1.0) * 0.5 * (resolution.x - 1)),
            math.floor((1.0 - line.b.position.y) * 0.5 * (resolution.y - 1))
        }

        dx := trans_b.x - trans_a.x
        dy := trans_b.y - trans_a.y
        dz := line.b.position.z - line.a.position.z

        x_inc, y_inc: f32
        max: u32

        step: f32 = math.max(math.abs(dx), math.abs(dy), math.abs(dz))

        dx = dx / step
        dy = dy / step
        dz = dz / step
        // TODO: Could be maybe done in integer representation
        d_rgba := (line.b.color - line.a.color) / linalg.Vector4f32{step, step,
            step, step}

        x := trans_a.x
        y := trans_a.y
        z := line.a.position.z
        rgba: color.Color4xF32 = line.b.color

        for i := 0; i < int(step); i += 1 {
            x += dx
            y += dy
            z += dz
            rgba += d_rgba

            // TODO: probably doing uneccessary calculation underneath depth
            // buffer. Maybe merge Depth buffer and image buffer?
            if depth_buffer_write(&renderer.depth_buffer, u32(x), u32(y), z) {
                index := u32(y) * renderer.image.width + u32(x)
                renderer.image.buffer[index] = color.to_u32(rgba)
            }
        }

    }

}

put_pixel :: proc(img: ^core.Image, x, y, color: u32) {
    index := y * u32(img.width) + x

    assert(x < img.width && y < img.height &&
        index < u32(len(img.buffer)), "Drawing pixel out of bounds!")

    img.buffer[index] = color
}
