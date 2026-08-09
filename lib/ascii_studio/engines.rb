# frozen_string_literal: true

module AsciiStudio
  module Engines
    class RubyEngine
      def indices(luminances, palette)
        luminances.map { |value| palette.index_for(value) }
      end
      alias quantize indices
    end

    class ZigEngine
      LIBRARY_NAMES = ["ascii_studio.dll", "libascii_studio.so", "libascii_studio.dylib"].freeze
      attr_reader :library_path

      def initialize(path: nil)
        require "ffi"
        @library_path = path || candidate_paths.find { |candidate| File.file?(candidate) }
        raise LoadError, "ASCII Studio Zig shared library not found" unless library_path
        native_path = library_path
        @native = Module.new do
          extend FFI::Library
          ffi_lib native_path
          attach_function :ascii_render, %i[pointer size_t size_t size_t pointer size_t pointer size_t], :int
        end
      end

      def indices(rgb, width:, height:, stride:, palette:)
        input = FFI::MemoryPointer.new(:uint8, rgb.length).write_array_of_uint8(rgb)
        output = FFI::MemoryPointer.new(:uint8, width * height)
        chars = palette.to_s.b
        pal = FFI::MemoryPointer.new(:uint8, chars.bytesize).write_bytes(chars)
        code = @native.ascii_render(input, width, height, stride, pal, palette.characters.length, output, width * height)
        raise RuntimeError, "Zig renderer failed with error #{code}" unless code.zero?
        output.read_array_of_uint8(width * height)
      end
      def quantize(luminances, palette)
        rgb = luminances.flat_map do |value|
          channel = ([[value, 0.0].max, 1.0].min * 255).round
          [channel, channel, channel]
        end
        indices(rgb, width: luminances.length, height: 1, stride: luminances.length * 3, palette: palette)
      end

      private
      def candidate_paths
        root = File.expand_path("../..", __dir__)
        output = File.join(root, "native", "zig", "zig-out")
        LIBRARY_NAMES.flat_map { |name| [File.join(output, "lib", name), File.join(output, "bin", name)] }
      end
    end

    def self.select(name = :auto)
      return RubyEngine.new if name.to_sym == :ruby
      return ZigEngine.new if name.to_sym == :zig
      ZigEngine.new
    rescue LoadError, FFI::NotFoundError
      RubyEngine.new
    end
  end
end
