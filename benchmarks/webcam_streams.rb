# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ascii_studio"
require "benchmark"

streams = Integer(ENV.fetch("STREAMS", "4"))
frames = Integer(ENV.fetch("FRAMES", "60"))
width, height = ENV.fetch("SIZE", "120x60").split("x").map(&:to_i)
raise "invalid SIZE" unless width.positive? && height.positive?
rgb = Array.new(width * height * 3) { |i| (i * 17) % 256 }.freeze
options = AsciiStudio::ImageOptions.new(width: width, height: height)
elapsed = Benchmark.realtime do
  Array.new(streams) do
    Thread.new do
      importer = AsciiStudio::ImageImporter.new(options: options)
      frames.times { AsciiStudio::Renderers::PlainText.new.render(importer.import_rgb(rgb, width: width, height: height)) }
    end
  end.each(&:join)
end
total = streams * frames
puts "Simulated streams=#{streams} frames/stream=#{frames} size=#{width}x#{height}"
puts format("Elapsed %.3fs; throughput %.2f frames/s", elapsed, total / elapsed)
