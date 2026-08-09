# Architecture

The reusable library is dependency-inward: HTTP and CLI code call the domain, never the reverse.

```text
                  ┌───────────────┐
Image ───────────▶│ ImageImporter │◀── CLI / HTTP / webcam adapter
                  └───────┬───────┘
                          ▼
                     ┌────────┐
                     │ Canvas │
                     └───┬────┘
       ┌─────────────────┼──────────────────┐
       ▼                 ▼                  ▼
 Plain text             ANSI               HTML
```

`Color` and `Cell` are immutable values. `Canvas` is mutable through bounds-checked logical operations and caps allocations at one million cells. A `Layer` owns a canvas. A `Frame` composites visible layers bottom-to-top using explicit transparent cells. `Animation` owns dimension-compatible frames. `Project` carries metadata and settings.

```text
Project
 └── Animation
      ├── Frame
      │    ├── Layer ── Canvas ── Cell[]
      │    └── Layer ── Canvas ── Cell[]
      └── Frame
```

Ruby editor commands store only before/after deltas. The browser maintains the same AAF-shaped model and renders it to a `<canvas>`; conversion output uses `<pre>`. This avoids thousands of editor DOM nodes while keeping document state separate from drawing and input handling.

AAF is the interoperability boundary between Ruby and browser models. Image decoding stays in `ImageImporter`; `import_rgb` also enables benchmarks and raw frame callers without filesystem coupling in the domain.
