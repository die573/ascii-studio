# frozen_string_literal: true

module AsciiStudio
  module Luminance
    module_function
    def from_rgb(red, green, blue) = (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    def normalize(value) = [[value.to_f / 255.0, 0.0].max, 1.0].min
    def adjust(value, brightness: 0.0, contrast: 1.0, gamma: 1.0)
      raise ArgumentError, "gamma must be positive" unless gamma.to_f.positive?
      adjusted = (((value.to_f - 0.5) * contrast.to_f) + 0.5 + brightness.to_f)
      [[adjusted, 0.0].max, 1.0].min**(1.0 / gamma.to_f)
    end
  end
end
