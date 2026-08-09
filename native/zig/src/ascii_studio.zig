const std = @import("std");

/// Maps packed RGB pixels to palette indices. All memory is caller-owned.
/// Returns 0 on success, 1 for null pointers, 2 for invalid dimensions/stride,
/// 3 for invalid palette, and 4 when output is too short. This is reentrant.
export fn ascii_render(pixels: ?[*]const u8, width: usize, height: usize, stride: usize, palette: ?[*]const u8, palette_len: usize, output: ?[*]u8, output_len: usize) callconv(.c) c_int {
    const input = pixels orelse return 1;
    _ = palette orelse return 1; // ABI carries bytes so future multi-byte palettes can be validated.
    const out = output orelse return 1;
    if (width == 0 or height == 0 or stride < width * 3) return 2;
    if (palette_len < 2 or palette_len > 256) return 3;
    const needed = std.math.mul(usize, width, height) catch return 2;
    if (output_len < needed) return 4;
    for (0..height) |y| {
        for (0..width) |x| {
            const offset = y * stride + x * 3;
            const luminance: usize = 54 * @as(usize, input[offset]) + 183 * @as(usize, input[offset + 1]) + 19 * @as(usize, input[offset + 2]);
            out[y * width + x] = @intCast(((luminance / 256) * (palette_len - 1) + 127) / 255);
        }
    }
    return 0;
}

test "maps black and white" {
    const pixels = [_]u8{ 0, 0, 0, 255, 255, 255 };
    const palette = "@ ";
    var output = [_]u8{ 9, 9 };
    try std.testing.expectEqual(@as(c_int, 0), ascii_render(&pixels, 2, 1, 6, palette.ptr, palette.len, &output, output.len));
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0, 1 }, &output);
}

test "rejects short output" {
    const pixels = [_]u8{ 0, 0, 0 };
    const palette = "@ ";
    var output = [_]u8{};
    try std.testing.expectEqual(@as(c_int, 4), ascii_render(&pixels, 1, 1, 3, palette.ptr, palette.len, &output, 0));
}
