# ASCII Studio

ASCII Studio is a Ruby ASCII/ANSI graphics workstation: an image converter, color renderer, live webcam renderer, Canvas-based editor, layer/frame animation tool, JSON AAF project format, exporters, benchmarks, and optional Zig pixel mapper. The web UI uses semantic HTML, CSS, and vanilla ES modules; no database or frontend framework is required.

```text
      @@@@%*=-.                 ┌ Convert ┐ ┌ Webcam ┐ ┌ Editor ┐
   @@%*=-:     .                true-color ANSI · layers · frames
  @#=.   ASCII STUDIO           local-first camera and projects
```

## Install

Requirements are Ruby 3.2+, Bundler, and libvips 8.14+. WebP works when the installed libvips was built with WebP support.

macOS:

```sh
brew install ruby vips
gem install bundler
bundle install
```

Debian/Ubuntu:

```sh
sudo apt update
sudo apt install ruby-full build-essential libvips-dev
gem install bundler
bundle install
```

Windows (RubyInstaller UCRT with MSYS2):

```powershell
ridk exec pacman -S --needed mingw-w64-ucrt-x86_64-libvips
gem install bundler
bundle install
bundle exec rake test
bundle exec puma
```

Then open `http://localhost:9292`. Zig is optional and never required for normal use.

## Commands

```sh
bundle exec rake test
bundle exec puma                         # http://localhost:9292
bin/ascii examples/sample.jpg --width 80
bin/ascii photo.jpg --width 120 --dither floyd --color
bin/ascii photo.png --format html --output art.html
bin/ascii photo.webp --ansi256 --background --output art.ansi
bin/ascii-studio play examples/sample.aaf --loop
```

The CLI supports `--width`, `--height`, `--charset`, `--palette`, `--invert`, `--brightness`, `--contrast`, `--gamma`, `--aspect`, `--dither none|floyd|bayer|edge`, `--engine auto|ruby|zig`, `--color`, `--ansi256`, `--background`, `--format text|ansi|html|aaf`, and `--output`.

## Web workstation

- **Convert:** drop JPEG/PNG/WebP, tune palette and tone/dithering, copy, download text/ANSI/HTML/AAF, or import the resulting Cell grid into Editor.
- **Webcam:** choose browser-local or Ruby/Puma rendering; control camera, resolution, FPS, palette, inversion, color, and mirroring. Diagnostics show effective FPS, processing/server time, and grid size.
- **Editor:** Canvas-rendered grid with pencil, eraser, keyboard text, Bresenham line, outline/filled rectangle, bucket, eyedropper, and rectangular selection. It supports delta-based undo/redo, copy/cut/paste, transparency, colors, zoom/grid, layer visibility/locking/duplication/merge, and frames.
- **Animations:** frame duration, navigation, loop, and playback.
- **Projects:** open/save `.aaf`, text export, and self-contained animated HTML export.
- **About:** real browser Canvas glyph-density calibration for the chosen browser monospace font.

Common shortcuts are Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z, Ctrl/Cmd+C/X/V, and Delete.

## Architecture

```text
Image ─▶ ImageImporter ─▶ Canvas<Cell> ─┬─▶ Plain text
              │                        ├─▶ ANSI 24-bit / 256
      luminance / adjustments          └─▶ HTML
      quantizer / dithering

Project
 └─ Animation
     └─ Frame[]
         └─ Layer[]
             └─ Canvas<Cell>
```

The domain in `lib/ascii_studio` knows nothing about HTTP, Puma, browser APIs, or image filenames. Importers and renderers form its adapters. Commands store changed cells only. See [architecture](docs/architecture.md), [rendering](docs/rendering.md), and [editor internals](docs/editor.md).

## AAF, benchmarks, and native acceleration

AAF v1 is readable validated JSON; see [the specification](docs/aaf-format.md). Run benchmarks with `ITERATIONS=10 bundle exec rake benchmark`. Results print to stdout so measured output can be recorded with machine metadata under `benchmarks/results/`; the repository does not invent numbers.

Files created under `benchmarks/results/` are intentionally ignored by Git. Keep measurements local unless you deliberately publish them with complete hardware, OS, toolchain, date, and command metadata.


## Security model

ASCII Studio is a local-first creative tool. It validates AAF dimensions before allocation, bounds HTTP uploads and WebSocket messages, requires same-origin WebSockets, uses JSON instead of Ruby object deserialization, escapes markup, and sends restrictive browser security headers. Do not expose Puma directly to an untrusted network; put a correctly configured reverse proxy in front if remote access is ever required.

With Zig 0.16.0 installed:

```sh
bundle exec rake native:build
cd native/zig && zig build test
```

`Engines.select(:auto)` uses the shared library if present and otherwise falls back to Ruby. See [native details](docs/native-zig.md) and [benchmark protocol](docs/benchmarks.md).

## Repository layout

```text
bin/            CLI converter and terminal animation player
lib/            reusable Ruby domain and adapters
web/            Roda app and vanilla browser workstation
test/           deterministic unit and integration tests
examples/       sample PPM and AAF
benchmarks/     reproducible benchmark runner
native/zig/     optional allocation-free C ABI library
docs/           implementation documentation
```

Released under the MIT License.
