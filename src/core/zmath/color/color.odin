package color

import "core:simd"
import "core:math/linalg"
import "core:math/rand"

import "../../../constants"

// Typedef for storing 4-value color in 4 usigned integers.
// TODO: could be a simd type?
Color4xU8 :: [4]u8
Color3xU8 :: [3]u8

RED   : Color3xU8 : {255, 0, 0}
GREEN : Color3xU8 : {0, 255, 0}
BLUE  : Color3xU8 : {0, 0, 255}
WHITE : Color3xU8 : {255, 255, 255}
BLACK : Color3xU8 : {0, 0, 0}

Color4xU16 :: [4]u16
Color3xU16 :: [3]u16

// Typedef for storing 4-value color in 4 floats.
// WARN: Values should be normalized from 0.0 to 1.0!
// TODO: could be a simd type?
Color4xF32 :: [4]f32
Color3xF32 :: [3]f32

to_u32 :: proc{
    to_u32_from_color4xU8, to_u32_from_color4xF32,
}

to_u32_from_color4xU8 :: #force_inline proc(color: Color4xU8) -> u32 {
    return transmute(u32)color
}

to_u32_from_color4xF32 :: #force_inline proc(color: Color4xF32) -> u32 {
    result := to_color4xu8(color)
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

// Maps a 4-component color defined in u8 (0- 255)
// to 4-component color defined in u16 (0 - 65535)
map_color4xU8_to_color4xU16 :: proc(color: Color4xU8) -> Color4xU16 {
    t_color: simd.f32x4 = {
        f32(constants.U8_MAX) / f32(color.r),
        f32(constants.U8_MAX) / f32(color.g),
        f32(constants.U8_MAX) / f32(color.b),
        f32(constants.U8_MAX) / f32(color.a),
    }

    b_color: simd.f32x4 = {f32(constants.U16_MAX), f32(constants.U16_MAX),
                           f32(constants.U16_MAX), f32(constants.U16_MAX)}
    a_color: simd.f32x4 = {0.0, 0.0, 0.0, 0.0} 

    mapped_color := simd.fma(t_color, b_color, a_color)

    return {
        u16(simd.extract(mapped_color, 0)),
        u16(simd.extract(mapped_color, 1)),
        u16(simd.extract(mapped_color, 2)),
        u16(simd.extract(mapped_color, 3)),
    }

}

// Maps a 3-component color defined in u8 (0- 255)
// to 3-component color defined in u16 (0 - 65535)
map_color3xU8_to_color3xU16 :: #force_inline proc(color: Color3xU8) -> Color3xU16 {
    result := map_color4xU8_to_color4xU16({color.r, color.g, color.b, 0})
    return {result.r, result.g, result.b}
}

to_color4xu8 :: proc(color: Color4xF32) -> Color4xU8 {
    return Color4xU8{
        u8(color.r * 255.0),
        u8(color.g * 255.0),
        u8(color.b * 255.0),
        u8(color.a * 255.0),
    }
}

rand_color4xf32 :: proc() -> Color4xF32 {
    return {
        rand.float32(),
        rand.float32(),
        rand.float32(),
        rand.float32(),
    }
}
