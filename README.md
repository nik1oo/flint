
![Flint](flint.png)

# Flint

Software renderer for simple 2D games.

 * Front buffer and back buffer.
 * Procedures that draw to a buffer.
 * Every procedures has a blend-mode parameter, which determines how the new value of every pixel blends with the current value.
 * You can create arbitrarily many auxiliary buffers to render to.

# How-to

To open the documentation execute `make doc-host` from inside `flint/src` and go to `http://localhost:8000/`.

# Checklist

- [x] Fill buffer with solid color.
- [ ] Fill a pixel (or slice of pixels) in a buffer with color.
- [ ] Fill a rectangle (or slice of rectangles) with a solid color.
- [ ] Texture sampler with filtering and scaling.
- [ ] Fill a pixel (or slice of pixels) with a texture.
- [ ] Fill a rectangle (or slice of rectangles) with a texture.
- [ ] Fill buffer with a pixel shader.
- [ ] Fill a pixel (or slice of pixels) with a pixel shader.
- [ ] Fill a rectangle (or slice of rectangles) with a pixel shader.
- [ ] Implement all the blend modes from Photoshop.
