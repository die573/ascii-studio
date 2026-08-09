# Optional Zig backend

Build with Zig 0.14 or newer:

```sh
zig build -Doptimize=ReleaseFast
zig build test
```

`ascii_render` accepts caller-owned packed RGB memory and writes one palette index per pixel into caller-owned output. It allocates nothing, retains no pointers, and is thread-safe/reentrant. Return values are documented in the source. Ruby's `Engines.select(:auto)` loads the platform shared library when present and otherwise selects the pure-Ruby engine.
