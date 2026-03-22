package model

import "core:math/linalg"

import "../zmath/color"


Point4D :: struct {
    position: linalg.Vector4f32,
    color: color.Color4xF32,
}

Point3D :: struct {
    position: linalg.Vector3f32,
    color: color.Color4xF32,
}

Point2D :: struct {
    position: linalg.Vector2f32,
    color: color.Color4xF32,
}

Triangle2D :: struct {
    a, b, c: Point2D
}

Triangle3D :: struct {
    a, b, c: Point4D
}

Topology_Type :: enum {
    Triangle_List
}

Object :: struct {
    vertex_buffer: []Point4D,
    index_buffer: []u32,
    topology_type: Topology_Type 
}

Line3D :: struct {
    a, b: Point4D,
    color: color.Color4xU8
}

Line2D :: struct {
    a, b: Point2D,
    color: color.Color4xU8
}

// TODO: Add Line representation
