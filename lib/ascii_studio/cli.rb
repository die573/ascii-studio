# frozen_string_literal: true

require "optparse"
require_relative "../ascii_studio"

module AsciiStudio
  class CLI
    FORMATS = %w[text ansi html aaf].freeze
    def self.run(argv, output: $stdout, error: $stderr)
      values = {width: 80, charset: Palette::BUILT_INS[Palette::DEFAULT_NAME], invert: false, brightness: 0.0, contrast: 1.0,
                gamma: 1.0, aspect: 0.5, dither: "none", color: false, ansi256: false, background: false, format: nil, engine: "auto"}
      parser = OptionParser.new do |flags|
        flags.banner = "Usage: ascii IMAGE [options]"
        flags.on("-w", "--width N", Integer) { |v| values[:width] = v }
        flags.on("--height N", Integer) { |v| values[:height] = v }
        flags.on("-c", "--charset CHARS") { |v| values[:charset] = v }
        flags.on("--palette NAME", Palette::BUILT_INS.keys) { |v| values[:charset] = Palette::BUILT_INS[v] }
        flags.on("--invert") { values[:invert] = true }
        flags.on("--brightness N", Float) { |v| values[:brightness] = v }
        flags.on("--contrast N", Float) { |v| values[:contrast] = v }
        flags.on("--gamma N", Float) { |v| values[:gamma] = v }
        flags.on("--aspect N", Float) { |v| values[:aspect] = v }
        flags.on("--dither MODE", ImageOptions::DITHERS.map(&:to_s)) { |v| values[:dither] = v }
        flags.on("--color") { values[:color] = true }
        flags.on("--ansi256") { values[:color] = values[:ansi256] = true }
        flags.on("--background") { values[:background] = values[:color] = true }
        flags.on("--engine NAME", %w[auto ruby zig]) { |v| values[:engine] = v }
        flags.on("-f", "--format FORMAT", FORMATS) { |v| values[:format] = v }
        flags.on("-o", "--output PATH") { |v| values[:output] = v }
        flags.on("-h", "--help") { output.puts flags; return 0 }
      end
      parser.parse!(argv)
      raise OptionParser::MissingArgument, "IMAGE" unless argv.one?
      values[:format] ||= values[:color] ? "ansi" : "text"
      keys = %i[width height aspect brightness contrast gamma color background]
      options = ImageOptions.new(**values.slice(*keys).merge(dither: values[:dither]))
      canvas = ImageImporter.new(palette: Palette.new(values[:charset], invert: values[:invert]), options: options, engine: Engines.select(values[:engine])).import(argv.first)
      project = Project.new(name: File.basename(argv.first), animation: Animation.new(frames: [Frame.new(layers: [Layer.new(canvas: canvas, name: "Imported image")])]))
      result = case values[:format]
               when "text" then Exporters::Text.new.export(project)
               when "ansi" then Exporters::Ansi.new(mode: values[:ansi256] ? :ansi256 : :truecolor).export(project)
               when "html" then Exporters::Html.new.export(project)
               when "aaf" then Exporters::AAF.new.export(project)
               end
      values[:output] ? File.binwrite(values[:output], result) : output.puts(result)
      0
    rescue OptionParser::ParseError, ArgumentError, LoadError, Errno::ENOENT => exception
      error.puts "ascii: #{exception.message}", parser
      1
    end
  end
end
