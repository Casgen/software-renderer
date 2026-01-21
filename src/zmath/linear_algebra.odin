package zmath

import "core:simd"

lerp_f32 :: #force_inline proc(a, b, t: f32) -> f32 {
    return simd.fma((1 - t), a, t * b)
}


