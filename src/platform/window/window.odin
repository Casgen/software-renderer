package platform

import "vendor:x11/xlib"
import "core:fmt"
import "core:slice"
import "base:runtime"
import "core:strings"
import "core:c/libc"
import "core:c"

import "../input"
import "../../core"
import clr "../../core/zmath/color"

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
    visual: ^xlib.Visual,
    window: xlib.Window, // Windows act as Drawables!
    ximage: ^xlib.XImage,
    image: core.Image,
    screen: i32,
    gc: xlib.GC,
    color_map: xlib.Colormap,
    color_cache: map[u64]uint, // Color value -> xlib XColor.pixel (Color ID)
    current_color: uint // Current XColor.pixel
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

poll_event :: #force_inline proc(
    window: ^Window,
    out_event: ^Event
) -> bool {
    assert(out_event != nil, "Out parameter shouldn't be nil!")

    out_event^ = Null{}
    is_pending := xlib.Pending(window.display) > 0

    if !is_pending do return false

    x_event: xlib.XEvent
    xlib.NextEvent(window.display, &x_event)

    #partial switch x_event.type {
    case .DestroyNotify:
        out_event^ = Destroy_Window{}
    case .ResizeRequest:
        resize(window, u32(x_event.xresizerequest.width),
            u32(x_event.xresizerequest.height))
        out_event^ = Resize_Window{
            image = &window.image,
            width = u32(x_event.xresizerequest.width),
            height = u32(x_event.xresizerequest.height)
        }
    case .ConfigureNotify:
        resize(window, u32(x_event.xconfigure.width),
            u32(x_event.xconfigure.height))
        out_event^ = Resize_Window{
            image = &window.image,
            width = u32(x_event.xconfigure.width),
            height = u32(x_event.xconfigure.height)
        }
    case .ButtonRelease:
        out_event^ = MouseBtn_Released{
            x = x_event.xbutton.x,
            y = x_event.xbutton.y,
            button = cast(input.MouseBtn_Code)x_event.xbutton.button
        }
    case .ButtonPress:
        out_event^ = MouseBtn_Pressed{
            x = x_event.xbutton.x,
            y = x_event.xbutton.y,
            button = cast(input.MouseBtn_Code)x_event.xbutton.button
        }
    case .KeyRelease:
        out_event^ = Key_Released{
            x = x_event.xkey.x,
            y = x_event.xkey.y,
            keycode = cast(input.Key_Code)x_event.xkey.keycode,
        }
    case .KeyPress:
        out_event^ = Key_Pressed{
            x = x_event.xkey.x,
            y = x_event.xkey.y,
            keycode = cast(input.Key_Code)x_event.xkey.keycode,
        }
    case .MotionNotify:
        out_event^ = Pointer_Moved{
            pos = {x_event.xmotion.x, x_event.xmotion.y},
        }
    }

    return true
}

next_event :: proc(window: ^Window) -> xlib.XEvent {
    event: xlib.XEvent
    xlib.NextEvent(window.display, &event)

    return event
}

show :: #force_inline proc(win: ^Window) {
    xlib.MapWindow(win.display, win.window)
    xlib.Flush(win.display)
}

hide :: #force_inline proc(win: ^Window) {
    xlib.UnmapWindow(win.display, win.window)
}

// WARN: Have to use the libc malloc. This is because the XDestroyImage
// procedure calls free on the given malloced data and it looks like it 
// expects that it uses C's malloc. Why can't we do it with mem.alloc()?
// Don't know really. Probably it's because it doesn't use C's malloc().
// In that case it will crash while destroying the image.
@private
malloc_buffer :: #force_inline proc($T: typeid, len: u64) -> []T {
    data_ptr := libc.malloc(c.size_t(len * size_of(T)))
    return slice.from_ptr(transmute(^T)data_ptr, int(len))
}

destroy:: #force_inline proc(win: ^Window) {
    xlib.DestroyImage(win.ximage)
    xlib.UnmapWindow(win.display, win.window)
    xlib.DestroyWindow(win.display, win.window)
    xlib.CloseDisplay(win.display)
    delete(win.color_cache)
}

// TODO: Have to make sure that width and height are somehow synchronized.
// Taking an image's width and height isn't probably a good idea?
clear :: #force_inline proc(win: ^Window, clear_color: u32 = 0) {
    clear_image(&win.image)
}

clear_image :: #force_inline proc(image: ^core.Image, clear_color: u32 = 0) {
    for i in 0..<len(image.buffer) do image.buffer[i] = clear_color
}

@private
create_rgb_image :: proc(
    win: ^Window,
    width, height: u32
) -> (core.Image, ^xlib.XImage) {
    depth := xlib.DefaultDepth(win.display, win.screen);

    assert(depth >= 0)

    img_buffer := malloc_buffer(u32, u64(width * height))
    x_img := xlib.CreateImage(win.display, win.visual, u32(depth), .ZPixmap,
        0, raw_data(img_buffer), width, height, 32, 0)

    return core.Image{
        width = width,
        height = height,
        buffer = img_buffer
    }, x_img
}

present :: #force_inline proc(win: ^Window) {
    xlib.PutImage(
        win.display,
        win.window,
        win.gc,
        win.ximage,
        0, 0, 0, 0,
        u32(win.image.width),
        u32(win.image.height),
    )
}

resize :: proc(win: ^Window, width, height: u32) {
    xlib.DestroyImage(win.ximage)
    win.image, win.ximage = create_rgb_image(win, width, height)
}

create :: proc(win_params: WindowCreateParams) -> (Window, bool) {
    display := xlib.OpenDisplay(nil)
    if display == nil {
        return Window{
            screen = 0,
            display = nil,
            window = 0,
            image = core.Image{},
            ximage = nil,
            color_map = 0
        }, false
    }

    xlib.SetErrorHandler(error_handler)

    root := xlib.DefaultRootWindow(display)
    screen := xlib.DefaultScreen(display)
    visual := xlib.DefaultVisual(display, screen)
    depth := xlib.DefaultDepth(display, screen);
    assert(depth >= 0)

    color_map := xlib.DefaultColormap(display, screen)

    window_attr: xlib.XSetWindowAttributes 
    window_attr.bit_gravity = .StaticGravity
    window_attr.background_pixel = 0
    window_attr.backing_pixel = 0
    window_attr.colormap = xlib.CreateColormap(display, root, visual,
         .AllocNone)
    // NOTE: ResizeRedirect is not appropriate for getting resized window
    // notification. That's for events when XResizeWindow(), XMoveResizeWindow()
    // or XConfigureWindow() is called. For resizing by a window manager,
    // .StructureNotify has to be set.
    window_attr.event_mask = { .StructureNotify } 

    window := xlib.CreateWindow(display, root, 0, 0, u32(win_params.width),
        u32(win_params.height), 0, depth, .InputOutput, visual,
        { .CWBitGravity , .CWBackPixel , .CWColormap , .CWEventMask },
        &window_attr)

    gc := xlib.DefaultGC(display, screen)
    gc_values: xlib.XGCValues

    // WARN: Implementation is weird. When the retrieval is successful, it
    // returns a non-zero result. From the outside, it feels like it failed
    // with BadRequest but that means success (implementation of xlib
    // returns True == BadRequest or False == Success). Was this is intentional
    // or a mistake? Manual describes what I described which is nonsense.
    assert(xlib.GetGCValues(display, gc, { .GCForeground }, &gc_values) ==
        xlib.Status.BadRequest, "Failed to retrieve Xlib GC Values!")

    pixel_count := win_params.width * win_params.height
    img_buffer := malloc_buffer(u32, u64(win_params.width * win_params.height))
    
    image := xlib.CreateImage(display, visual, u32(depth), .ZPixmap,
        0, raw_data(img_buffer), win_params.width, win_params.height, 32, 0)

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
        visual = visual,
        ximage = image,
        image = core.Image{
            width = win_params.width,
            height = win_params.height,
            buffer = img_buffer
        },
        gc = gc,
        color_map = color_map,
        color_cache = {},
        current_color = gc_values.foreground
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

@private
create_color_cache_key :: proc(color: clr.Color3xU16) -> u64 {
    return u64(color.r) | u64(color.g) << 16 | u64(color.b) << 32
}

draw_string :: #force_inline proc(
    win: ^Window,
    message: string,
    pos_x, pos_y: u32,
    color: clr.Color3xU8
) {
    mapped_color := clr.map_color3xU8_to_color3xU16(color)
    key := create_color_cache_key(mapped_color)

    color_id, ok := win.color_cache[key]
    xcolor: xlib.XColor

    if !ok {
        xcolor = xlib.XColor{
            red = mapped_color.r,
            green = mapped_color.g,
            blue = mapped_color.b,
        }

        // WARN: Same thing with the weird declaration/definition. BadRequest
        // is success (non-zero = 1 result is successful)
        assert(xlib.AllocColor(win.display, win.color_map, &xcolor) ==
            xlib.Status.BadRequest, "Failed to allocate XColor!")
        win.color_cache[key] = xcolor.pixel
        color_id = xcolor.pixel
    }

    xlib.SetForeground(win.display, win.gc, color_id)
    xlib.Sync(win.display, true)
    xlib.DrawString(win.display, win.window, win.gc, i32(pos_x), i32(pos_y),
        raw_data(message), i32(len(message)))

    // Revert back to the previous color
    xlib.SetForeground(win.display, win.gc, win.current_color)
    xlib.Sync(win.display, true)
}
