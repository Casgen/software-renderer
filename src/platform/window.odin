package platform

import "vendor:x11/xlib"
import "../../lib/x11/xutil"
import "core:fmt"
import "core:slice"
import "base:runtime"

Window :: struct {
    display: ^xlib.Display,
    window: xlib.Window, // Windows act as Drawables!
    screen: i32,
}

@private
error_handler :: proc "c" (
    display: ^xlib.Display,
    error_event: ^xlib.XErrorEvent
) -> i32 {

    status := cast(xlib.Status)error_event.error_code

    buffer: [256]u8 = {}

    xlib.GetErrorText(display, i32(error_event.error_code),
        &buffer[0], len(buffer))

    context = runtime.default_context()
    fmt.eprintfln("XLib Error: %s", error_event.error_code)

    return 0
}

destroy_window :: proc(win: ^Window) {
    xlib.DestroyWindow(win.display, win.window)
    xlib.CloseDisplay(win.display)

    free(win)
}

create_window :: proc() -> (^Window, bool) {

    display := xlib.OpenDisplay(nil)
    if display == nil {
        return nil, false
    }

    xlib.SetErrorHandler(error_handler)

    screen := xlib.DefaultScreen(display)
    window := xlib.CreateSimpleWindow(
        display,
        xlib.RootWindow(display, screen),
        10, 10, 1024, 768, 1,
        xlib.BlackPixel(display, screen),
        xlib.WhitePixel(display, screen)
    )

    my_window := new(Window)
    my_window.window = window
    my_window.display = display
    my_window.screen = screen

    x_context := xutil.UniqueContext()
    xutil.SaveContext(display, window, x_context, my_window)

    return my_window, true
}
