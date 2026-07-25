package model

import "core:math/linalg"
import "../../core/zmath/color"

Vertex4D :: struct {
    position: linalg.Vector4f32,
    color: color.Color4xF32,
}

Vertex3D :: struct {
    position: linalg.Vector3f32,
    color: color.Color4xF32,
}

Vertex2D :: struct {
    position: linalg.Vector2f32,
    color: color.Color4xF32,
}
