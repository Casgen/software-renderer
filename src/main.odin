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

// main :: proc() {
//
//     win, ok := window.create({1024, 768, "Software Renderer App",
//         "SoftwareRendererClass"})
//     assert(ok, "Failed to create a window!")
//
//     window.filter_events_mask(&win, {
//         .Exposure,
//         .KeyPress,
//         .ResizeRedirect,
//         .StructureNotify,
//     })
//
//     window.show(&win)
//
//     msg := "Hello, World!"
//     delta_time: time.Duration
//
//     window_attrs := window.get_attributes(&win)
//
//     render_ctx: renderer.Renderer
//     render_ctx.image = win.color_buffer
//
//     main_loop: for {
//         start_tick := time.tick_now()
//
//         for event, is_pending := window.poll_event(&win); is_pending;
//             event, is_pending = window.poll_event(&win) {
//             #partial switch event.type {
//             case .DestroyNotify:
//                 break main_loop
//             case .ResizeRequest:
//                 window.resize(&win, u32(event.xresizerequest.width),
//                     u32(event.xresizerequest.height))
//                 render_ctx.image = win.color_buffer
//             case .ConfigureNotify:
//                 window.resize(&win, u32(event.xconfigure.width),
//                     u32(event.xconfigure.height))
//                 render_ctx.image = win.color_buffer
//                 xlib.
//             }
//         }
//
//         renderer.fill_screen(&render_ctx)
//         window.present(&win)
//
//         sleep_time := SYNC_DURATION - time.tick_diff(start_tick, time.tick_now()) 
//         if sleep_time >= 0 {
//             time.sleep(sleep_time)
//         }
//         delta_time = time.tick_diff(start_tick, time.tick_now()) 
//         fmt.printfln("Delta time: %v", delta_time)
//
//     }
//
//     window.destroy(&win)
// }



main :: proc() {
    width: i32 = 800
    height: i32 = 600
    
    display := xlib.OpenDisplay(nil)
    
    if display == nil {
        fmt.printfln("No display available")
        return
    }
    
    root := xlib.DefaultRootWindow(display)
    default_screen := xlib.DefaultScreen(display)
    
    screen_bit_depth: i32 = 24

    def_visual := xlib.DefaultVisual(display, default_screen)
    
    window_attr: xlib.XSetWindowAttributes 
    window_attr.bit_gravity = .StaticGravity
    window_attr.background_pixel = 0
    window_attr.colormap = xlib.CreateColormap(display, root, def_visual,
        .AllocNone)
    window_attr.event_mask = { .StructureNotify } 

    depth := xlib.DefaultDepth(display, default_screen)
    
    window := xlib.CreateWindow(display, root, 0, 0, u32(width), u32(height), 0,
        depth, .InputOutput, def_visual,
        {.CWBitGravity , .CWBackPixel , .CWColormap , .CWEventMask },
        &window_attr)

    class_hint := xlib.AllocClassHint()
    class_hint.res_name = "Software Renderer App"
    class_hint.res_class = "SoftwareRendererClass"

    xlib.SetClassHint(display, window, class_hint)
    
    xlib.StoreName(display, window, "Hello, World!")
    xlib.MapWindow(display, window)
    
    //toggleMaximize(display, window)
    xlib.Flush(display)
    
    pixelBits: i32 = 32
    pixelBytes: i32 = pixelBits / 8
    window_buffer_size := c.size_t(width * height * pixelBytes)

    img_data: rawptr = libc.malloc(window_buffer_size)
    img_buffer: []u32 = slice.from_ptr(transmute(^u32)img_data, int(width * height))
    
    x_window_buffer := xlib.CreateImage(display, def_visual, u32(depth),
                                         .ZPixmap, 0, img_data, u32(width), u32(height),
                                         pixelBits, 0)  
    default_gc := xlib.DefaultGC(display, default_screen)
    
    size_change := false
    window_open := true
    for window_open {
        ev: xlib.XEvent

        for xlib.Pending(display) > 0 {
            xlib.NextEvent(display, &ev)

            #partial switch ev.type {
            case .DestroyNotify:
                if ev.xdestroywindow.window == window {
                    window_open = false
                }
            case .ConfigureNotify:
                width = ev.xconfigure.width
                height = ev.xconfigure.height
                size_change = true
            }
        }
        
        if size_change {
            size_change = false
            xlib.DestroyImage(x_window_buffer) // Free's the memory we malloced
            window_buffer_size = c.size_t(width * height * pixelBytes)
            img_data = libc.malloc(window_buffer_size)
            img_buffer = slice.from_ptr(transmute(^u32)img_data, int(width * height))
            
            x_window_buffer = xlib.CreateImage(display, def_visual, u32(depth),
                                         .ZPixmap, 0, img_data, u32(width), u32(height),
                                         pixelBits, 0)
        }
        
        for y in 0..<height {
            row := width * y
            for x in 0..<width {
                pixel := &img_buffer[row + x] 

                if x % 16 > 0 && y % 16 > 0 {
                    pixel^ = 0xffffffff
                } else {
                    pixel^ = 0
                }
            }
        }
        
        xlib.PutImage(display, window, default_gc, x_window_buffer, 0, 0, 0, 0, 
                  u32(width), u32(height))
    }
    
} 
