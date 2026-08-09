# Benchmarks

Run:

```sh
ITERATIONS=10 bundle exec rake benchmark
```

The runner uses deterministic RGB buffers at 80×40, 120×60, 200×100, and 320×180. It independently measures luminance, quantization, Floyd–Steinberg, Bayer, Cell creation, Canvas creation, full RGB-to-Canvas conversion, and ANSI rendering.

When the Zig shared library is built, the same run also measures its RGB buffer mapping. Simulate concurrent server-render workloads without physical cameras using STREAMS=4 FRAMES=60 SIZE=120x60 bundle exec ruby benchmarks/webcam_streams.rb; this exercises independent full RGB-to-Canvas-to-text streams with bounded frame counts.

When recording output under `benchmarks/results/`, include the printed date, OS, Ruby version and platform, iteration count, CPU/hardware, command, and (for native comparisons) Zig version. Run Ruby and Zig against identical buffers. No benchmark result ships until it has actually been measured, and no universal speed claim follows from one machine.
