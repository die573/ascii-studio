# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ascii_studio"
require "benchmark"
require "rbconfig"

SIZES = [[80, 40], [120, 60], [200, 100], [320, 180]].freeze
ITERATIONS = Integer(ENV.fetch("ITERATIONS", "10"))
palette = AsciiStudio::Palette.new
zig = AsciiStudio::Engines.select(:auto)
zig = nil unless zig.is_a?(AsciiStudio::Engines::ZigEngine)
puts "ASCII Studio #{AsciiStudio::VERSION} benchmark"
puts "Ruby #{RUBY_VERSION} #{RUBY_PLATFORM}; #{RbConfig::CONFIG['host_os']}; iterations=#{ITERATIONS}"
puts "Run at #{Time.now.utc.iso8601}"

SIZES.each do |width, height|
  rgb = Array.new(width * height * 3) { |i| (i * 31) % 256 }
  luminances = rgb.each_slice(3).map { |r, g, b| AsciiStudio::Luminance.normalize(AsciiStudio::Luminance.from_rgb(r, g, b)) }
  matrix = luminances.each_slice(width).map(&:dup)
  canvas = AsciiStudio::ImageImporter.new(palette: palette, options: AsciiStudio::ImageOptions.new(width: width, height: height, color: true)).import_rgb(rgb, width: width, height: height)
  puts "\n#{width}x#{height}"
  Benchmark.bm(18) do |x|
    x.report("luminance") { ITERATIONS.times { rgb.each_slice(3) { |r, g, b| AsciiStudio::Luminance.from_rgb(r, g, b) } } }
    x.report("quantization") { ITERATIONS.times { AsciiStudio::Engines::RubyEngine.new.indices(luminances, palette) } }
    x.report("Zig RGB mapping") { ITERATIONS.times { zig.indices(rgb, width: width, height: height, stride: width * 3, palette: palette) } } if zig
    x.report("floyd") { ITERATIONS.times { AsciiStudio::Dithering::FloydSteinberg.new.apply(matrix, palette) } }
    x.report("bayer") { ITERATIONS.times { AsciiStudio::Dithering::Bayer.new.apply(matrix, palette) } }
    x.report("cell creation") { ITERATIONS.times { luminances.map { |v| AsciiStudio::Cell.new(character: palette.character_for(v)) } } }
    x.report("canvas creation") { ITERATIONS.times { AsciiStudio::Canvas.new(width: width, height: height) } }
    x.report("RGB full frame") { ITERATIONS.times { AsciiStudio::ImageImporter.new(palette: palette, options: AsciiStudio::ImageOptions.new(width: width, height: height)).import_rgb(rgb, width: width, height: height) } }
    x.report("ANSI rendering") { ITERATIONS.times { AsciiStudio::Renderers::Ansi.new.render(canvas) } }
  end
end
