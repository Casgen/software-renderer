## Notes
---

- the `math.abs(inverted_t - t)` is to fight the color interpolation problem.
- If the triangle is connected in counter clock-wise direction, everything works fine the `t` from the left to right ranges from 0 to 1.
- However when the triangle is connected clock-wise, we have to invert the t (from 1 to 0). Otherwise it will color the triangle wrong.
- In this case we will have `inverted_t - t` to invert the range. However if it goes negative, that's a problem. So we `abs` it to work in both directions. inverted_t is set to `0` if it's CCW. This way the calculated t goes negative, but it's then absoluted. If it's CW, then the range is inverted. T will be positive so the absolute wouldn't have to be here, but to create no if branching, we can just absolute it anyway. Could be interesting to profile If-branching vs the `inverted_t` style.

```c
    t := math.abs(1 - (f32(x) - acc_min_x) / (acc_max_x - acc_min_x))
```
