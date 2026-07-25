package main

import "vendor:x11/xlib"
import "core:time"

import "platform/window"
import "renderer"
import "core"
import "profiler"
import "core/zmath/color"

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

    delta_time: time.Duration

    render_ctx := renderer.create_renderer(&win.image)
    triangles := renderer.generate_random_3d_triangles(2)


    for {
        start_tick := time.tick_now()

        event: window.Event
        for window.poll_event(&win, &event) {
            renderer.dispatch_event(&render_ctx, event)
        }

        update_timer := profiler.timer_start("Render Update")
        renderer.render_update(&render_ctx, delta_time);
        update_result := profiler.timer_end(&update_timer)

        clear_timer := profiler.timer_start("Render Clear")
        renderer.render_clear(&render_ctx);
        clear_result := profiler.timer_end(&clear_timer)

        draw_timer := profiler.timer_start("Draw Timer")
        renderer.draw_3d(&render_ctx, triangles)
        draw_result := profiler.timer_end(&draw_timer)

        // renderer.draw_line_3d(&render_ctx, {
        //     model.Line3D{
        //         a = model.Vertex4D{
        //             position = {0, 0, 0, 1},
        //             color = color.Color4xF32{1.0, 1.0, 1.0, 1.0}
        //         },
        //         b = model.Vertex4D{
        //             position = {0.5, 0, 0, 1},
        //             color = color.Color4xF32{0, 0, 1.0, 1.0}
        //         },
        //     },
        //     model.Line3D{
        //         a = model.Vertex4D{
        //             position = {0, 0, 0, 1},
        //             color = color.Color4xF32{1.0, 1.0, 1.0, 1.0}
        //         },
        //         b = model.Vertex4D{
        //             position = {0, 0.5, 0, 1},
        //             color = color.Color4xF32{0, 1.0, 0, 1.0}
        //         },
        //     },
        //     model.Line3D{
        //         a = model.Vertex4D{
        //             position = {0, 0, 0, 1},
        //             color = color.Color4xF32{1.0, 1.0, 1.0, 1.0}
        //         },
        //         b = model.Vertex4D{
        //             position = {0, 0, 0.5, 1},
        //             color = color.Color4xF32{1.0, 0, 0, 1.0}
        //         },
        //     }
        // })

        window.present(&win)

        update_fmt := profiler.timer_fmt_result(&update_result)
        clear_fmt := profiler.timer_fmt_result(&clear_result)
        draw_fmt := profiler.timer_fmt_result(&draw_result)

        window.draw_string(&win, update_fmt, 10, 10, color.WHITE)
        window.draw_string(&win, clear_fmt, 10, 20, color.WHITE)
        window.draw_string(&win, draw_fmt, 10, 30, color.WHITE)

        delete(update_fmt)
        delete(clear_fmt)
        delete(draw_fmt)

        profiler.timer_destroy(&update_timer)
        profiler.timer_destroy(&clear_timer)
        profiler.timer_destroy(&draw_timer)

        // TODO: Make a proper V-Sync
        sleep_time := SYNC_DURATION - time.tick_diff(start_tick, time.tick_now()) 
        if sleep_time >= 0 {
            time.sleep(sleep_time)
        }


        delta_time = time.tick_diff(start_tick, time.tick_now()) 
        // fmt.printfln("Frame Time: %.5f", delta_time)
        render_ctx.acc_time += f32(delta_time) / 1_000_000_000
    }

    renderer.destroy_renderer(&render_ctx)
    window.destroy(&win)
}
