package main

import "vendor:x11/xlib"
import "core:slice"
import "core:fmt"
import "core:time"
import "core:math"
import "core:c/libc"
import "core:c"
import "core:mem"
import "core:bytes"

import "platform/window"
import "renderer"

SYNC_DURATION : time.Duration : time.Duration(16_666_666)

main :: proc() {

    win, ok := window.create({1024, 768, "Software Renderer App",
        "SoftwareRendererClass"})
    assert(ok, "Failed to create a window!")

    window.filter_events_mask(&win, {
        .Exposure,
        .KeyPress,
        .StructureNotify,
    })

    window.show(&win)

    msg := "Hello, World!"
    delta_time: time.Duration

    window_attrs := window.get_attributes(&win)

    render_ctx: renderer.Renderer
    render_ctx.image = win.image

    main_loop: for {
        start_tick := time.tick_now()

        for event, is_pending := window.poll_event(&win); is_pending;
            event, is_pending = window.poll_event(&win) {
            #partial switch event.type {
            case .DestroyNotify:
                break main_loop
            case .ResizeRequest:
                window.resize(&win, u32(event.xresizerequest.width),
                    u32(event.xresizerequest.height))
                render_ctx.image = win.image
            case .ConfigureNotify:
                window.resize(&win, u32(event.xconfigure.width),
                    u32(event.xconfigure.height))
                render_ctx.image = win.image
            }
        }

        window.clear(&win)
        renderer.draw(&render_ctx)
        window.present(&win)

        sleep_time := SYNC_DURATION - time.tick_diff(start_tick, time.tick_now()) 
        if sleep_time >= 0 {
            time.sleep(sleep_time)
        }
        delta_time = time.tick_diff(start_tick, time.tick_now()) 
        render_ctx.acc_time += f32(delta_time) / 1_000_000_000
    }

    window.destroy(&win)
}
