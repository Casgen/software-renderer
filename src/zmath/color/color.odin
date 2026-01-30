package color

import "core:simd"
import "core:math/linalg"

// Typedef for storing 4-value color in 4 usigned integers.
// TODO: could be a simd type?
Color4xU8 :: [4]u8

// Typedef for storing 4-value color in 4 floats.
// WARN: Values should be normalized from 0.0 to 1.0!
// TODO: could be a simd type?
Color4xF32 :: [4]f32

to_u32 :: proc{
    to_u32_from_color4xU8, to_u32_from_color4xF32,
}

to_u32_from_color4xU8 :: #force_inline proc(color: Color4xU8) -> u32 {
    return transmute(u32)color
}

to_u32_from_color4xF32 :: #force_inline proc(color: Color4xF32) -> u32 {
    result := to_color4u32(color)
    return transmute(u32)result
}

from_u32 :: proc(value: u32) -> Color4xU8 {
    return transmute([4]u8)value
}

to_color4xf32 :: proc(color: Color4xU8) -> Color4xF32 {
    return Color4xF32{
        f32(color.r) / 255.0,
        f32(color.g) / 255.0,
        f32(color.b) / 255.0,
        f32(color.a) / 255.0,
    }
}

to_color4u32 :: proc(color: Color4xF32) -> Color4xU8 {
    return Color4xU8{
        u8(color.r * 255.0),
        u8(color.g * 255.0),
        u8(color.b * 255.0),
        u8(color.a * 255.0),
    }
}
