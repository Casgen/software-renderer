package model

import "../../core/zmath"
import "../../core/zmath/color"
import "core:math/linalg"

Point2D :: linalg.Vector2f32
Point3D :: linalg.Vector3f32
Point4D :: linalg.Vector4f32

Vertex4D :: struct {
    position: Point4D,
    color:    color.Color4xF32,
}

Vertex3D :: struct {
    position: Point3D,
    color:    color.Color4xF32,
}

Vertex2D :: struct {
    position: Point2D,
    color:    color.Color4xF32,
}

vertex_4d_lerp :: #force_inline proc(
    a: ^Vertex4D,
    b: ^Vertex4D,
    t: f32,
) -> Vertex4D {
    return Vertex4D {
        position = zmath.lerp(a.position, b.position, t),
        color = zmath.lerp(a.color, b.color, t),
    }

}
