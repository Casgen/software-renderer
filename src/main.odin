package main

import "vendor:x11/xlib"
import "core:slice"
import "core:fmt"

import "core:time"

main :: proc() {

    display := xlib.OpenDisplay(nil)

    assert(display != nil, "Failed to open a display! Display is null!")

    screen := xlib.DefaultScreen(display)
    // Windows and pixmaps act as Drawables!
    window := xlib.CreateSimpleWindow(display, xlib.RootWindow(display, screen),
        10, 10, 1024, 768, 1, xlib.BlackPixel(display, screen),
        xlib.WhitePixel(display, screen))

    xlib.SelectInput(display, window, {.Exposure, .KeyPress});
    xlib.MapWindow(display, window);

    event: xlib.XEvent
    msg := "Hello, World!"

    delta_time: time.Duration

    main_loop: for {
        fmt.printfln("Tick = %d", delta_time)
        start_tick := time.tick_now()

        xlib.Flush(display)
        pending_count := xlib.Pending(display)

        for pending_count > 0 {
            xlib.NextEvent(display, &event)
            #partial switch event.type {
            case .Expose:
                xlib.FillRectangle(display, window, xlib.DefaultGC(display,
                    screen), 20, 20, 10, 10)
                xlib.DrawString(display, window, xlib.DefaultGC(display,
                    screen), 10, 50, raw_data(msg), i32(len(msg)))
            case .DestroyNotify:
                break main_loop
            }
            pending_count -= 1
        }

        delta_time = time.tick_diff(start_tick, time.tick_now())
    }

    xlib.CloseDisplay(display);
}
