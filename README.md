# Software Renderer
---

A software renderer made in Odinlang and with X11.

## TODOs
---
- [x] Make the window work.
- [x] Make an off-window pixel buffer.
- [x] Render a simple Triangle.
- [ ] Do a rendering pipeline.
-   [ ] Setup a scene.
-   [ ] Setup Transformation pipeline.
-   [ ] Setup a drawing phase.

## Optimization

- The rasterization portion of the code could be drastically SIMDed.
- Try to approach the color interpolation differently.
- Experiment with fixed-point transformation of vertices onto the screen.
- It is for consideration, whether we want to just calculate the t's between the vertices and just calculates all the color and coordinates just by interpolation, or if we should really stick just adding by incremental steps.

 t_ab f32 = 0.996116518
 t_ac f32 = 0.498058259
 color_ab f32[4] = (0.00388348103, 0.996116518, 0, 0)
 color_ac f32[4] = (0.501941741, 0, 0.498058259, 0)
 color_abc f32[4] = (0.00388348103, 0.996116518, 0, 0)
