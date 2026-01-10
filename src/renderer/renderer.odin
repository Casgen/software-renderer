package renderer

import "core:math/linalg"

Vertex :: struct {
    position: linalg.Vector3f32,
    color: linalg.Vector3f32,
}

Object :: struct {
    vertex_buffer: []Vertex,
    index_buffer: []u32,
}


draw :: proc(obj: Object) {

}
