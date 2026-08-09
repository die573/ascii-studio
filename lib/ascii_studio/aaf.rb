# frozen_string_literal: true

require "json"

module AsciiStudio
  module AAF
    MAGIC = "ASCII-STUDIO"
    VERSION = 1

    module Codec
      module_function
      def project_hash(project)
        {
          magic: MAGIC, version: VERSION,
          project: {name: project.name, author: project.author, created_at: project.created_at.iso8601, updated_at: project.updated_at.iso8601,
                    width: project.width, height: project.height, palette: project.palette, settings: project.settings},
          animation: {default_fps: project.animation.default_fps, loop: project.animation.loop},
          frames: project.animation.frames.map { |frame| frame_hash(frame) }
        }
      end
      def frame_hash(frame)
        {duration_ms: frame.duration_ms, layers: frame.layers.map { |layer| layer_hash(layer) }}
      end
      def layer_hash(layer)
        {name: layer.name, visible: layer.visible, locked: layer.locked, opacity: layer.opacity,
         cells: layer.canvas.each_row.map { |row| row.map(&:to_h) }}
      end
      def cell(hash)
        Cell.new(character: hash.fetch("character"), foreground: hash["foreground"], background: hash["background"], transparent: hash.fetch("transparent", false))
      end
    end

    class Writer
      def dump(project, pretty: true) = pretty ? JSON.pretty_generate(Codec.project_hash(project)) : JSON.generate(Codec.project_hash(project))
      def write(project, path) = File.write(path, dump(project))
    end

    class Reader
      def load(source)
        data = source.respond_to?(:read) ? JSON.parse(source.read) : JSON.parse(source.to_s)
        validate_root!(data)
        metadata = data.fetch("project")
        width, height = Integer(metadata.fetch("width")), Integer(metadata.fetch("height"))
        Canvas.new(width: width, height: height) # validates allocation before nested content
        frames = data.fetch("frames").map { |frame| read_frame(frame, width, height) }
        anim = data.fetch("animation")
        Project.new(name: metadata.fetch("name"), author: metadata["author"], created_at: metadata.fetch("created_at"), updated_at: metadata.fetch("updated_at"),
                    palette: metadata.fetch("palette", Palette::DEFAULT_NAME), settings: metadata.fetch("settings", {}),
                    animation: Animation.new(frames: frames, default_fps: anim.fetch("default_fps"), loop: anim.fetch("loop")))
      rescue JSON::ParserError, KeyError, TypeError, ArgumentError => error
        raise ArgumentError, "invalid AAF: #{error.message}"
      end
      def read(path) = File.open(path, "r:utf-8") { |file| load(file) }

      private
      def validate_root!(data)
        raise ArgumentError, "invalid magic" unless data["magic"] == MAGIC
        version = data["version"]
        raise ArgumentError, "unsupported AAF version #{version.inspect}" unless version == VERSION
      end
      def read_frame(data, width, height)
        layers = data.fetch("layers").map do |layer|
          rows = layer.fetch("cells")
          raise ArgumentError, "cell matrix dimensions mismatch" unless rows.length == height && rows.all? { |row| row.length == width }
          canvas = Canvas.new(width: width, height: height, cells: rows.flatten.map { |cell| Codec.cell(cell) })
          Layer.new(canvas: canvas, name: layer.fetch("name"), visible: layer.fetch("visible"), locked: layer.fetch("locked"), opacity: layer.fetch("opacity", 1.0))
        end
        Frame.new(layers: layers, duration_ms: data.fetch("duration_ms"))
      end
    end
  end
end
