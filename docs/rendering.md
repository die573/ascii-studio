# Rendering pipeline

1. libvips loads JPEG, PNG, PPM, or supported WebP and applies embedded orientation.
2. `ImageOptions` calculates height from source proportions and character aspect (default `0.5`) unless an explicit height is supplied.
3. libvips resizes in sRGB and flattens alpha over white.
4. `0.2126R + 0.7152G + 0.0722B` produces perceptual luminance.
5. Brightness offset, contrast around 0.5, and gamma are applied and clamped.
6. No dithering, standard Floyd–Steinberg, 4×4 Bayer, or isolated Sobel-like edge glyph selection runs.
7. A density-ordered `Palette` maps normalized values into Unicode glyphs; source RGB may be retained on each Cell.
8. plain text, optimized 24-bit/256-color ANSI, or escaped HTML renders the canvas.

Floyd–Steinberg distributes quantization error right and onto the next row with `7/16, 3/16, 5/16, 1/16`. Bayer offsets each sample using a fixed 4×4 threshold matrix. The experimental edge mode uses gradient magnitude and direction for `|`, `-`, `/`, and `\` while flat regions use density glyphs.

The Braille renderer treats each 2×4 sample block as the eight correctly ordered Unicode Braille dots. Dark samples set dots, yielding higher spatial resolution than one glyph per source sample.
