package zmath

import "base:intrinsics"
import "core:simd"

@(require_results)
lerp :: proc {
    lerp_f32,
    lerp_2xf32,
    lerp_3xf32,
    lerp_4xf32,

    lerp_f64,
    lerp_2xf64,
    lerp_3xf64,
    lerp_4xf64,
}

@(require_results)
lerp_f32 :: #force_inline proc(a, b, t: f32) -> f32 {
    return simd.fma(1 - t, a, t * b)
}

@(require_results)
lerp_f64 :: #force_inline proc(a, b, t: f64) -> f64 {
    return simd.fma(1 - t, a, t * b)
}

@(require_results)
lerp_2xf32 :: #force_inline proc(a, b: [2]f32, t: f32) -> [2]f32 {
    flipped_t := 1 - t
    return {
        simd.fma(flipped_t, a.x, t * b.x),
        simd.fma(flipped_t, a.y, t * b.y),
    }
}

@(require_results)
lerp_2xf64 :: #force_inline proc(a, b: [2]f64, t: f64) -> [2]f64 {
    flipped_t := 1 - t
    return {
        simd.fma(flipped_t, a.x, t * b.x),
        simd.fma(flipped_t, a.y, t * b.y),
    }
}

@(require_results)
lerp_3xf32 :: #force_inline proc(a, b: [3]f32, t: f32) -> [3]f32 {
    a_simd: simd.f32x4 = simd.from_array([4]f32{a.x, a.y, a.z, 0})
    b_simd: simd.f32x4 = simd.from_array([4]f32{b.x, b.y, b.z, 0})

    t_simd := simd.f32x4{t, t, t, 0}

    result := simd.fma(
        simd.sub(simd.f32x4{1, 1, 1, 0}, t_simd),
        a_simd,
        simd.mul(t_simd, b_simd),
    )

    return {
        simd.extract(result, 0),
        simd.extract(result, 1),
        simd.extract(result, 2),
    }
}

@(require_results)
lerp_3xf64 :: #force_inline proc(a, b: [3]f64, t: f64) -> [3]f64 {
    a_simd: simd.f64x4 = {a.x, a.y, a.z, 0}
    b_simd: simd.f64x4 = {b.x, b.y, b.z, 0}

    t_simd := simd.f64x4{t, t, t, 0}

    result := simd.fma(
        simd.sub(simd.f64x4{1, 1, 1, 0}, t_simd),
        a_simd,
        simd.mul(t_simd, b_simd),
    )

    return {
        simd.extract(result, 0),
        simd.extract(result, 1),
        simd.extract(result, 2),
    }
}

@(require_results)
lerp_4xf32 :: #force_inline proc(a, b: [4]f32, t: f32) -> [4]f32 {
    a_simd: simd.f32x4 = simd.from_array(a)
    b_simd: simd.f32x4 = simd.from_array(b)

    t_simd := simd.f32x4{t, t, t, t}

    result := simd.fma(
        simd.sub(simd.f32x4{1, 1, 1, 1}, t_simd),
        a_simd,
        simd.mul(t_simd, b_simd),
    )

    return simd.to_array(result)
}

@(require_results)
lerp_4xf64 :: #force_inline proc(a, b: [4]f64, t: f64) -> [4]f64 {
    a_simd: simd.f64x4 = simd.from_array(a)
    b_simd: simd.f64x4 = simd.from_array(b)

    t_simd := simd.f64x4{t, t, t, t}

    result := simd.fma(
        simd.sub(simd.f64x4{1, 1, 1, 1}, t_simd),
        a_simd,
        simd.mul(t_simd, b_simd),
    )

    return simd.to_array(result)
}

@(require_results)
square_raw :: proc(val: $T) -> T where intrinsics.type_is_numeric(T) {
    return val * val
}

