# frozen_string_literal: true

module AsciiStudio
  class ImageOptions
    DITHERS = %i[none floyd bayer edge].freeze
    attr_reader :width, :height, :aspect, :brightness, :contrast, :gamma, :dither, :color, :background

    def initialize(width: 80, height: nil, aspect: 0.5, brightness: 0.0, contrast: 1.0, gamma: 1.0, dither: :none, color: false, background: false)
      raise ArgumentError, "width must be positive" unless width.to_i.positive?
      raise ArgumentError, "height must be positive" if height && !height.to_i.positive?
      raise ArgumentError, "aspect must be positive" unless aspect.to_f.positive?
      raise ArgumentError, "unknown dither mode" unless DITHERS.include?(dither.to_sym)
      raise ArgumentError, "gamma must be positive" unless gamma.to_f.positive?
      @width, @height, @aspect = width.to_i, height&.to_i, aspect.to_f
      @brightness, @contrast, @gamma = brightness.to_f, contrast.to_f, gamma.to_f
      @dither, @color, @background = dither.to_sym, !!color, !!background
    end

    def dimensions(source_width, source_height)
      return [width, height] if height
      [width, [(source_height.to_f / source_width * width * aspect).round, 1].max]
    end
  end
end
