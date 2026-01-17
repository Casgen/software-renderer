package platform

import "vendor:x11/xlib"
import "core:fmt"
import "core:slice"
import "base:runtime"
import "core:mem"
import "core:strings"
import "core:c/libc"
import "core:c"

WindowCreateParams :: struct {
    width, height: u32,
    app_name, class_name: string 
}

WindowAttributes :: struct {
    width, height: u32,
    depth: i32
}

Window :: struct {
    display: ^xlib.Display,
    window: xlib.Window, // Windows act as Drawables!
    color_buffer: ^xlib.XImage,
    screen: i32,
    gc: xlib.GC,
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

poll_event :: #force_inline proc(window: ^Window) -> (xlib.XEvent, bool) {
    event: xlib.XEvent
    is_pending := xlib.Pending(window.display) > 0

    if is_pending {
        xlib.NextEvent(window.display, &event)
    }

    return event, is_pending
}

next_event :: proc(window: ^Window) -> xlib.XEvent {
    event: xlib.XEvent
    xlib.NextEvent(window.display, &event)

    return event
}

show:: #force_inline proc(win: ^Window) {
    xlib.MapWindow(win.display, win.window)
    xlib.Flush(win.display)
}

hide:: #force_inline proc(win: ^Window) {
    xlib.UnmapWindow(win.display, win.window)
}

destroy:: #force_inline proc(win: ^Window) {
    xlib.UnmapWindow(win.display, win.window)
    xlib.DestroyWindow(win.display, win.window)
    xlib.CloseDisplay(win.display)

    free(win)
}

// TODO: Have to make sure that width and height are somehow synchronized.
// Taking an image's width and height isn't probably a good idea.
// And this is probably not a good solution. Probably slow?
clear :: #force_inline proc(win: ^Window) {

    for y in 0..<win.color_buffer.height {

        for x in 0..<win.color_buffer.width {
            xlib.PutPixel(win.color_buffer, x, y, 0);
        }
    }
    
}


create_rgb_image :: proc(win: ^Window, width, height: u32) -> ^xlib.XImage {
    depth := xlib.DefaultDepth(win.display, win.screen);
    visual := xlib.DefaultVisual(win.display, win.screen)

    assert(depth >= 0)

    img_data := libc.malloc(c.size_t(width * height * 4))
    img := xlib.CreateImage(win.display, visual, u32(depth), .ZPixmap,
        0, img_data, width, height, 32, 0)

    return img
}

present :: #force_inline proc(win: ^Window) {
    xlib.PutImage(
        win.display,
        win.window,
        win.gc,
        win.color_buffer,
        0, 0, 0, 0,
        u32(win.color_buffer.width),
        u32(win.color_buffer.height),
    )
}

resize:: proc(win: ^Window, width, height: u32) {
    xlib.DestroyImage(win.color_buffer)
    win.color_buffer = create_rgb_image(win, width, height)
}

create:: proc(win_params: WindowCreateParams) -> (Window, bool) {

    display := xlib.OpenDisplay(nil)
    if display == nil {
        return Window{
            screen = 0,
            display = nil,
            window = 0,
            color_buffer = nil,
        }, false
    }

    xlib.SetErrorHandler(error_handler)

    screen := xlib.DefaultScreen(display)
    window := xlib.CreateSimpleWindow(
        display,
        xlib.RootWindow(display, screen),
        0, 0, win_params.width, win_params.height, 1,
        0x000000,
        0xFF0000,
    )

    depth := xlib.DefaultDepth(display, screen);
    visual := xlib.DefaultVisual(display, screen)
    gc := xlib.DefaultGC(display, screen)

    assert(depth >= 0)

    // WARN: Have to use the libc malloc. This is because the XDestroyImage
    // procedure calls free on the given malloced data and it looks like it 
    // expects that it uses C's malloc. Why can't we do it with mem.alloc()?
    // Don't know really. Probably it's because it doesn't use C's malloc().
    // In that case it will crash while destroying the image.
    img_data := libc.malloc(c.size_t(win_params.width * win_params.height * 4))
    assert(img_data != nil, "Failed to allocate a Color buffer!")
    
    color_buffer := xlib.CreateImage(display, visual, u32(depth), .ZPixmap,
        0, img_data, win_params.width, win_params.height, 32, 0)

    // NOTE: When setting class hints, are strings getting copied?
    if win_params.app_name != "" || win_params.class_name != "" {
        class_hint := xlib.AllocClassHint()
        class_hint.res_name = strings.clone_to_cstring(win_params.app_name)
        class_hint.res_class = strings.clone_to_cstring(win_params.class_name)

        xlib.SetClassHint(display, window, class_hint)
    }

    return Window{
        display = display,
        window = window,
        screen = screen,
        color_buffer = color_buffer,
        gc = gc,
    }, true
}

// Tells X11 which provided events should be registered.
// Call this after creating a window!
filter_events :: proc {
    filter_events_allow_all,
    filter_events_mask,
}


// Tells X11 which provided events should be registered. Allows all of them.
// Call this after creating a window!
filter_events_allow_all :: #force_inline proc(win: ^Window) {
    xlib.SelectInput(win.display, win.window, {
        .KeyPress,
        .KeyRelease,
        .ButtonPress,
        .ButtonRelease,
        .EnterWindow,
        .LeaveWindow,
        .PointerMotion,
        .PointerMotionHint,
        .Button1Motion,
        .Button2Motion,
        .Button3Motion,
        .Button4Motion,
        .Button5Motion,
        .ButtonMotion,
        .KeymapState,
        .Exposure,
        .VisibilityChange,
        .StructureNotify,
        .ResizeRedirect,
        .SubstructureNotify,
        .SubstructureRedirect,
        .FocusChange,
        .PropertyChange,
        .ColormapChange,
        .OwnerGrabButton,
    });
}

// Tells X11 which provided events should be registered. Call this
// after creating a window!
filter_events_mask :: #force_inline proc(
    win: ^Window,
    event_mask: xlib.EventMask
) {
    xlib.SelectInput(win.display, win.window, event_mask);
}

get_attributes :: #force_inline proc(win: ^Window) -> WindowAttributes {
    attributes: xlib.XWindowAttributes
    status := xlib.GetWindowAttributes(win.display, win.window, &attributes)
    assert(status == 1, "Failed to obtain Window attributes")
    
    return WindowAttributes{
        height = u32(attributes.height),
        width = u32(attributes.width),
        depth = attributes.depth
    }
}

// ========= Draw Commands ==============

fill_rectangle :: #force_inline proc(win: ^Window, x, y, width, height: u32) {
    xlib.FillRectangle(win.display, win.window, win.gc, i32(x), i32(y),
        width, height)
}

draw_string :: #force_inline proc(
    win: ^Window,
    message: string,
    pos_x, pos_y: u32
) {
    xlib.DrawString(win.display, win.window, win.gc, i32(pos_x), i32(pos_y),
        raw_data(message), i32(len(message)))
}
