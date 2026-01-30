# Software Renderer
---

A software renderer made in Odinlang and with X11.

## TODOs
---
[x] Make the window work.
[x] Make an off-window pixel buffer.
[x] Render a simple Triangle.
[ ] Do a rendering pipeline.
    [ ] Setup a scene.
    [ ] Setup Transformation pipeline.
    [ ] Setup a drawing phase.

## Optimization

- the T's while rasterizing a trinagle could be optimized further. Specifically this
```c
// Calculate the T not from top->down but from bottom->up to recycle the numerator?
//
//   C  ^
//  /|  |
// A |  |
//  \|  |
//   C  |
//
t_bc := (f32(y) - trans_b.y) / (trans_c.y - trans_b.y) // T between B-C
t_ac := (u32(y) - trans_a.y) / (trans_c.y - trans_a.y) // T between A-C
```

- The rasterization portion of the code could be drastically SIMDed.
- Try to approach the color interpolation differently.
- Experiment with fixed-point transformation of vertices onto the screen.
