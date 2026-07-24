package main

import "vendor:x11/xlib"
import "core:time"
import "core:fmt"

import "platform/window"
import "renderer"
import "core"
import "zmath/color"
import "core/model"
import "profiler"

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

    profiler.begin_profiling()

    for {
        start_tick := time.tick_now()

        event: window.Event
        for window.poll_event(&win, &event) {
            renderer.dispatch_event(&render_ctx, event)
        }

        @static update_id: u32 = 0
        update_block := profiler.begin_block("Renderer Update", &update_id)
        renderer.render_update(&render_ctx, delta_time);
        profiler.end_block(&update_block)

        @static render_clr_id: u32 = 0
        render_clr_block := profiler.begin_block("Renderer Clear", &render_clr_id)
        renderer.render_clear(&render_ctx);
        profiler.end_block(&render_clr_block)

        @static draw3d_id: u32 = 0
        draw3d_block := profiler.begin_block("Renderer Draw3D", &draw3d_id)
        renderer.draw_3d(&render_ctx, triangles)
        profiler.end_block(&draw3d_block)

        @static drawline3d_id: u32 = 0
        drawline3d_block := profiler.begin_block("Renderer DrawLine3D", &drawline3d_id)
        renderer.draw_line_3d(&render_ctx, {
            model.Line3D{
                a = model.Vertex4D{
                    position = {0, 0, 0, 1},
                    color = color.Color4xF32{1.0, 1.0, 1.0, 1.0}
                },
                b = model.Vertex4D{
                    position = {0.5, 0, 0, 1},
                    color = color.Color4xF32{0, 0, 1.0, 1.0}
                },
            },
            model.Line3D{
                a = model.Vertex4D{
                    position = {0, 0, 0, 1},
                    color = color.Color4xF32{1.0, 1.0, 1.0, 1.0}
                },
                b = model.Vertex4D{
                    position = {0, 0.5, 0, 1},
                    color = color.Color4xF32{0, 1.0, 0, 1.0}
                },
            },
            model.Line3D{
                a = model.Vertex4D{
                    position = {0, 0, 0, 1},
                    color = color.Color4xF32{1.0, 1.0, 1.0, 1.0}
                },
                b = model.Vertex4D{
                    position = {0, 0, 0.5, 1},
                    color = color.Color4xF32{1.0, 0, 0, 1.0}
                },
            }
        })
        profiler.end_block(&drawline3d_block)
        
        window.present(&win)

        profiler.end_profiling()

        // TODO: Make a proper V-Sync
        sleep_time := SYNC_DURATION - time.tick_diff(start_tick, time.tick_now()) 
        if sleep_time >= 0 {
            time.sleep(sleep_time)
        }
        window.draw_string(&win,"Something", 10, 10)
        delta_time = time.tick_diff(start_tick, time.tick_now()) 
        // fmt.printfln("Frame Time: %.5f", delta_time)
        render_ctx.acc_time += f32(delta_time) / 1_000_000_000
    }

    renderer.destroy_renderer(&render_ctx)
    window.destroy(&win)
}
