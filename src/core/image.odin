package core

Image :: struct {
    width, height: u32,
    buffer:        []u32,
}

image_write_rgb :: proc {
    image_write_rgb_u8,
    image_write_rgb_3xu8,
}

image_create :: proc(width, height: u32) -> Image {
    return Image {
        width = width,
        height = height,
        buffer = make([]u32, width * height * 4),
    }
}

image_write_rgb_u8 :: proc(
    image: ^Image,
    x: u32,
    y: u32,
    r: u8,
    g: u8,
    b: u8,
) {
    index := int(y * image.width + x)
    assert(
        index + 3 < len(image.buffer),
        "Failed to write into image! Out of bounds!",
    )

    ptr := transmute([^]u8)&image.buffer[index]
    ptr[0] = r
    ptr[1] = g
    ptr[2] = b
    ptr[3] = 255
}

image_write_rgb_3xu8 :: proc(
    image: ^Image,
    x: u32,
    y: u32,
    colors: [3]u8
) {
    index := int(y * image.width + x)
    assert(
        index + 3 < len(image.buffer),
        "Failed to write into image! Out of bounds!",
    )

    ptr := transmute([^]u8)&image.buffer[index]
    ptr[0] = colors[0]
    ptr[1] = colors[1]
    ptr[2] = colors[2]
    ptr[3] = 255
}


image_write_rgba :: proc {
    image_write_rgba_u32,
    image_write_rgba_u8
}

image_write_rgba_u8 :: proc(image: ^Image, x, y: u32, r, g, b, a: u8, bounds_check := true) {
    index := int(y * image.width + x)
    if (bounds_check) {
        assert(
            index + 3 < len(image.buffer),
            "Failed to write into image! Out of bounds!",
        )
    }

    #no_bounds_check ptr := transmute([^]u8)&image.buffer[index]
    ptr[0] = r
    ptr[1] = g
    ptr[2] = b
    ptr[3] = a
}

image_write_rgba_u32 :: proc(image: ^Image, x, y: u32, value: u32, bounds_check := true) {
    index := int(y * image.width + x)
    if bounds_check {
        assert(
            index < len(image.buffer),
            "Failed to write into image! Out of bounds!",
        )
    }

   #no_bounds_check image.buffer[index] = value
}

image_destroy :: proc(image: ^Image) {
    image.height = 0xFFFFFFFF
    image.width = 0xFFFFFFFF
    delete(image.buffer)
}

