package model

import "core:math/linalg"
import "../../core/zmath/color"

Point2D :: linalg.Vector2f32
Point3D :: linalg.Vector3f32
Point4D :: linalg.Vector4f32

Vertex4D :: struct {
    position: Point4D,
    color: color.Color4xF32,
}

Vertex3D :: struct {
    position: Point3D,
    color: color.Color4xF32,
}

Vertex2D :: struct {
    position: Point2D,
    color: color.Color4xF32,
}
