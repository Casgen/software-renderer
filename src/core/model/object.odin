package model

Topology_Type :: enum {
    Triangle_List,
    Triangle_Strip
}

Object :: struct {
    vertex_buffer: []Vertex4D,
    index_buffer: []u32,
    topology_type: Topology_Type 
}

