package main

import "platform/window"
import "renderer"

Application :: struct {
    rndr:   renderer.Renderer,
    window: window.Window,
}

