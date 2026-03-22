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
import "profiler"
import "model"
import "zmath/color"

SYNC_DURATION : time.Duration : time.Duration(16_666_666)

main :: proc() {
    win, ok := window.create({1024, 768, "Software Renderer App",
        "SoftwareRendererClass"})
    assert(ok, "Failed to create a window!")

    window.filter_events_mask(&win, {
        .Exposure,
        .KeyPress,
        .StructureNotify,
        .KeyPress,
        .KeyRelease,
        .ButtonPress,
        .ButtonRelease,
        .PointerMotion,
    })

    window.show(&win)

    msg := "Hello, World!"
    delta_time: time.Duration

    window_attrs := window.get_attributes(&win)

    render_ctx := renderer.create_renderer(win.image, win.depth_buffer)
    triangles := renderer.generate_random_3d_triangles(2)
    main_loop: for {
        start_tick := time.tick_now()

        event: window.Event
        for window.poll_event(&win, &event) {
            renderer.dispatch_event(&render_ctx, event)
        }

        renderer.renderer_update(&render_ctx, delta_time);

        window.clear(&win, 0)
        renderer.draw_3d(&render_ctx, triangles)

        renderer.draw_line_3d(&render_ctx, {
            model.Line3D{
                a = model.Point4D{
                    position = {0, 0, 0, 1},
                },
                b = model.Point4D{
                    position = {0.5, 0, 0, 1},
                },
                color = color.Color4xU8{255, 0, 0, 0}
            },
            model.Line3D{
                a = model.Point4D{
                    position = {0, 0, 0, 1},
                },
                b = model.Point4D{
                    position = {0, 0.5, 0, 1},
                },
                color = color.Color4xU8{0, 255, 0, 0}
            },
            model.Line3D{
                a = model.Point4D{
                    position = {0, 0, 0, 1},
                },
                b = model.Point4D{
                    position = {0, 0, 0.5, 1},
                },
                color = color.Color4xU8{0, 0, 255, 0}
            }
        })
        
        window.present(&win)

        sleep_time := SYNC_DURATION - time.tick_diff(start_tick, time.tick_now()) 
        if sleep_time >= 0 {
            time.sleep(sleep_time)
        }
        window.draw_string(&win,"Something", 10, 10)
        delta_time = time.tick_diff(start_tick, time.tick_now()) 
        // fmt.printfln("Frame Time: %.5f", delta_time)
        render_ctx.acc_time += f32(delta_time) / 1_000_000_000
    }

    window.destroy(&win)
}
