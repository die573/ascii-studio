# Zig integration

The optional Zig library exports one reentrant C-ABI function. It maps packed RGB bytes to one palette index per pixel. All buffers and their lengths are caller-provided; Zig allocates nothing, retains nothing, and can be called concurrently on independent buffers.

Return codes: `0` success, `1` null pointer, `2` invalid dimensions/stride or overflow, `3` invalid palette length, and `4` short output.

Build using `bundle exec rake native:build` or from `native/zig` with `zig build -Doptimize=ReleaseFast`. Ruby FFI searches the installed Zig output for the platform library. `auto` catches missing-library/symbol failures and selects `RubyEngine`; explicitly selecting `zig` reports the load error.

Image decoding and Canvas creation remain in Ruby. The native boundary is intentionally small and measurable.
