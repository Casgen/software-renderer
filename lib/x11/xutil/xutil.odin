#+build linux, openbsd, freebsd
package xutil

import vxlib "vendor:x11/xlib"

foreign import xlib "system:X11"

@(default_calling_convention="c", link_prefix="X")
foreign xlib {
    SaveContext :: proc(display: ^vxlib.Display, resource_id: vxlib.XID, ctx: vxlib.XContext, data: rawptr) -> vxlib.Status ---
    FindContext :: proc(display: ^vxlib.Display, resource_id: vxlib.XID, ctx: vxlib.XContext, return_data: rawptr) -> vxlib.Status ---
    DeleteContext :: proc(display: ^vxlib.Display, resource_id: vxlib.XID, ctx: vxlib.XContext) -> vxlib.Status ---
    // TODO: For some reason i can not link to this UniqueContext procedure?? But other ones are allright?
    UniqueContext :: proc() -> vxlib.XContext ---
}
