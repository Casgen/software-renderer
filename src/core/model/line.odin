package model

import "core:math"
import "core:simd"
import "core:sys/posix"

OutCode :: u8

@private INSIDE : u8 : 0b0000
@private LEFT : u8 :   0b0001
@private RIGHT : u8 :  0b0010
@private BOTTOM : u8 : 0b0100
@private TOP : u8 :    0b1000

Line3D :: struct { a, b: Vertex4D, }
Line2D :: struct { a, b: Vertex2D, }

// Based on Liang-Barsky line clipping algorithms
// Returns:
//  - Bool value if the line should be discarded or not (is outside the window)
// TODO: Maybe a fixed point precision or integer based clipping for performance?
line_liang_barsky_clip_3d :: proc(
    x_min, x_max, y_min, y_max: f32,
    line: ^Line3D
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
    
line_liang_barsky_clip_2d :: proc(
    x_min, x_max, y_min, y_max: f32,
    line: ^Line2D
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
