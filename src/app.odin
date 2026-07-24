package main

import "renderer"
import "platform/window"

Application :: struct {
    rndr: renderer.Renderer,
    window: window.Window,
}

