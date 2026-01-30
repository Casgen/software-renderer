package zmath

import "core:simd"
import "core:math"
import "core:math/fixed"
import "core:math/linalg"

lerp_f32 :: #force_inline proc(a, b, t: f32) -> f32 {
    return simd.fma(1 - t, a, t * b)
}

lerp_4xf32 :: #force_inline proc(a, b: [4]f32, t: f32) -> [4]f32 {
    a_simd: simd.f32x4 = simd.from_array(a)
    b_simd: simd.f32x4 = simd.from_array(b)
    
    t_simd := simd.f32x4{t, t, t, t}

    result := simd.fma(
        simd.sub(simd.f32x4{1, 1, 1, 1}, t_simd),
        a_simd,
        simd.mul(t_simd, b_simd)
    )

    return simd.to_array(result)
}

square :: proc {
    square_f32, square_u32,
}

@(require_results)
square_u32 :: #force_inline proc(val: u32) -> u32 {
    return val * val
}

@(require_results)
square_f32 :: #force_inline proc(val: f32) -> f32 {
    return val * val
}


