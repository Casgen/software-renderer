package renderer

import "../model"
import "core:math"
import "../zmath/color"
import "../zmath"
import "core:math/linalg"
import "core:simd"
import "core:sys/posix"

OutCode :: u8

@private INSIDE : u8 : 0b0000
@private LEFT : u8 :   0b0001
@private RIGHT : u8 :  0b0010
@private BOTTOM : u8 : 0b0100
@private TOP : u8 :    0b1000

// Based on Liang-Barsky line clipping algorithms
// Returns:
//  - Bool value if the line should be discarded or not (is outside the window)
// TODO: Maybe a fixed point precision or integer based clipping for performance?
liang_barsky_clip_3d :: proc(
    x_min, x_max, y_min, y_max: f32,
    line: ^model.Line3D
) -> bool {
    
    p1: f32 = -(line.b.position.x - line.a.position.x)
    p2: f32 = -p1
    p3: f32 = -(line.b.position.y - line.a.position.y)
    p4: f32 = -p3

    q1: f32 = line.a.position.x - x_min
    q2: f32 = x_max - line.a.position.x
    q3: f32 = line.a.position.y - y_min
    q4: f32 = y_max - line.a.position.y

    
    // TODO: Is there ever a high chance that this will be hit? Probably
    // not...
    if (p1 == 0 && q1 < 0) || (p2 == 0 && q2 < 0) || (p3 == 0 && q3 < 0) ||
       (p4 == 0 && q4 < 0) {
        return false
    }

    entry_params: [3]f32 = {0, 0, 0}
    exit_params: [3]f32 = {1, 1, 1}

    entry_index: u8 = 1
    exit_index: u8 = 1

    if p1 != 0 {
        r1 := q1 / p1
        r2 := q2 / p2

        if (p1 < 0) {
            entry_params[entry_index] = r1;
            entry_index += 1

            exit_params[exit_index] = r2;
            exit_index += 1
        } else {
            entry_params[entry_index] = r2;
            entry_index += 1

            exit_params[exit_index] = r1;
            exit_index += 1
        }
    }

    if p3 != 0 {
        r3 := q3 / p3
        r4 := q4 / p4

        if (p3 < 0) {
            entry_params[entry_index] = r3;
            entry_index += 1

            exit_params[exit_index] = r4;
            exit_index += 1
        } else {
            entry_params[entry_index] = r4;
            entry_index += 1

            exit_params[exit_index] = r3;
            exit_index += 1
        }
    }

    t1 := math.max(entry_params[0], entry_params[1], entry_params[2])
    t2 := math.min(exit_params[0], exit_params[1], exit_params[2])

    if t1 > t2 do return false

    z_diff := line.b.position.z - line.a.position.z

    line.a.position.x = math.clamp(simd.fma(t1, line.b.position.x - line.a.position.x, line.a.position.x), x_min, x_max)
    line.a.position.y = math.clamp(simd.fma(t1, line.b.position.y - line.a.position.y, line.a.position.y), y_min, y_max)
    line.a.position.z = simd.fma(t1, z_diff, line.a.position.z)

    line.b.position.x = math.clamp(simd.fma(t2, line.b.position.x - line.a.position.x, line.a.position.x), x_min, x_max)
    line.b.position.y = math.clamp(simd.fma(t2, line.b.position.y - line.a.position.y, line.a.position.y), y_min, y_max)
    line.b.position.z = simd.fma(t2, z_diff, line.a.position.z)

    if line.a.position.x < -1.0 || line.a.position.y < -1.0  || line.a.position.x > 1.0 || line.a.position.y > 1.0 ||
       line.b.position.x < -1.0 || line.b.position.y < -1.0  || line.b.position.x > 1.0 || line.b.position.y > 1.0 {
        posix.raise(posix.Signal.SIGTRAP)
    }

    return true
}
    
liang_barsky_clip_2d :: proc(
    x_min, x_max, y_min, y_max: f32,
    line: ^model.Line2D
) -> bool {
    
    p1: f32 = -(line.b.position.x - line.a.position.x)
    p2: f32 = -p1
    p3: f32 = -(line.b.position.y - line.a.position.y)
    p4: f32 = -p3

    q1: f32 = line.a.position.x - x_min
    q2: f32 = x_max - line.a.position.x
    q3: f32 = line.a.position.y - y_min
    q4: f32 = y_max - line.a.position.y

    
    if (p1 == 0 && q1 < 0) || (p2 == 0 && q2 < 0) || (p3 == 0 && q3 < 0) ||
       (p4 == 0 && q4 < 0) {
        return false
    }

    entry_params: [3]f32 = {0, 0, 0}
    exit_params: [3]f32 = {1, 1, 1}

    entry_index: u8 = 1
    exit_index: u8 = 1

    if p1 != 0 {
        r1 := q1 / p1
        r2 := q2 / p2

        if (p1 < 0) {
            entry_params[entry_index] = r1;
            entry_index += 1

            exit_params[exit_index] = r2;
            exit_index += 1
        } else {
            entry_params[entry_index] = r2;
            entry_index += 1

            exit_params[exit_index] = r1;
            exit_index += 1
        }
    }

    if p3 != 0 {
        r3 := q3 / p3
        r4 := q4 / p4

        if (p1 < 0) {
            entry_params[entry_index] = r3;
            entry_index += 1

            exit_params[exit_index] = r4;
            exit_index += 1
        } else {
            entry_params[entry_index] = r4;
            entry_index += 1

            exit_params[exit_index] = r3;
            exit_index += 1
        }
    }

    t1 := math.max(entry_params[0], entry_params[1], entry_params[2])
    t2 := math.min(exit_params[0], exit_params[1], exit_params[2])

    if t1 > t2 do return false

    line.a.position.x = simd.fma(line.a.position.x, p2, t1)
    line.a.position.y = simd.fma(line.a.position.y, p4, t1)

    line.b.position.x = simd.fma(line.b.position.x, p2, t2)
    line.b.position.y = simd.fma(line.b.position.y, p4, t2)

    return true
}



draw_line_2d :: proc(renderer: ^Renderer, lines: []model.Line2D) {
    for i in 0..<len(lines) {
        line := &lines[i]

        resolution: [2]f32 = {f32(renderer.image.x_image.width),
                              f32(renderer.image.x_image.height)}

        liang_barsky_clip_2d(-1.0, 1.0, -1.0, 1.0, line)
        
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

        x := trans_a.x
        y := trans_a.y

        // TODO: fix crashing when lines go out of bounds
        for i := 0; i <= int(step); i += 1 {
            x = x + dx
            y = y + dy

            put_pixel(renderer.image, u32(x), u32(y), color.to_u32(test_line.color))
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
        resolution: [2]f32 = {f32(renderer.image.x_image.width),
                              f32(renderer.image.x_image.height)}

        if !liang_barsky_clip_3d(-1.0, 1.0, -1.0, 1.0, line) do return 


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

        x := trans_a.x
        y := trans_a.y
        z := line.a.position.z

        // TODO: fix crashing when lines go out of bounds
        for i := 0; i < int(step); i += 1 {
            x = x + dx
            y = y + dy
            z = z + dz

            index := u32(y) * u32(renderer.image.x_image.width) + u32(x)
            renderer.image.buffer[index] = color.to_u32(line.color)
            renderer.depth_buffer[index] = z
        }

    }

}
