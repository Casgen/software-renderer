package renderer


DepthBuffer :: struct {
    width, height: u32,
    data: []f32
}

depth_buffer_create :: proc(width: u32, height: u32) -> DepthBuffer {
    pixel_count := width * height * 4

    buffer := DepthBuffer{
        data = make([]f32, pixel_count),
        width = width,
        height = height,
    }
    for i in 0..<pixel_count do buffer.data[i] = 1.0

    return buffer
}

depth_buffer_destroy :: proc(buffer: ^DepthBuffer) {
    delete(buffer.data)
    buffer.data = nil
    buffer.width = 0
    buffer.height = 0
}

depth_buffer_clear :: proc(buffer: ^DepthBuffer) {
    for i in 0..<len(buffer.data) do buffer.data[i] = 1.0
}

// Returns true if the value successfully written. (new value < old value)
depth_buffer_write :: proc(buffer: ^DepthBuffer, x, y: u32, value: f32) -> bool {
    pixel := &buffer.data[y * buffer.width + x]
    if pixel^ > value {
        pixel^ = value
        return true
    }
    return false
}
