package math

import "core:simd"

lerp :: proc {
    lerp_f32
}

lerp_f32 :: proc(a, b, t: f32) -> f32 {
    return simd.fma(b - a, t, a)
}

