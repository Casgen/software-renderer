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
-   [x] Setup Transformation pipeline. (Partialy done)
-   [x] Setup a drawing phase. (partialy done. Needs to be improved)

## Optimization

- The rasterization portion of the code could be drastically SIMDed.
- Try to approach the color interpolation differently.
- Experiment with fixed-point transformation of vertices onto the screen.
- It is for consideration, whether we want to just calculate the t's between the vertices and just calculates all the color and coordinates just by interpolation, or if we should really stick just adding by incremental steps.
