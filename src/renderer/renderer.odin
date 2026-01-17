package renderer

import "core:math/linalg"
import "vendor:x11/xlib"
import "core:slice"

Renderer :: struct {
    image: ^xlib.XImage,
}

Vertex :: struct {
    position: linalg.Vector3f32,
    color: linalg.Vector3f32,
}

Topology_Type :: enum {
    Triangle_List
}

Object :: struct {
    vertex_buffer: []Vertex,
    index_buffer: []u32,
    topology_type: Topology_Type 
}

fill_screen :: proc(renderer: ^Renderer) {
    for y in 0..<renderer.image.height {
        for x in 0..<renderer.image.width {

            // TODO: There has to be a better way to do this...
            pixel: [8]u8 = {
                u8(x % 256), // B
                u8(y % 256), // G
                128,         // R
                255,         // A
                0,
                0,
                0,
                0,
            }

            xlib.PutPixel(renderer.image, x, y, transmute(uint)pixel)
        }
    }

}

draw :: proc(renderer: ^Renderer, obj: Object) {

    a: ^Vertex = nil
    b: ^Vertex = nil
    c: ^Vertex = nil

    switch obj.topology_type {
        case .Triangle_List:
            for i := 0; i < len(obj.index_buffer); i += 3 {
                a := &obj.vertex_buffer[obj.index_buffer[i]]
                b := &obj.vertex_buffer[obj.index_buffer[i + 1]]
                c := &obj.vertex_buffer[obj.index_buffer[i + 2]]

                // Sort vertices from top to bottom
                if (c.position.y > b.position.y) {
                    temp := c
                    c = b
                    b = temp
                }

                if (b.position.y > a.position.y) {
                    temp := b
                    b = a
                    a = temp
                }

                if (c.position.y > b.position.y) {
                    temp := c
                    c = b
                    b = temp
                }
                
                
                
            }
            
    }
        
    
}
