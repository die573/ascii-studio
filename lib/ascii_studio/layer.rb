# frozen_string_literal: true

module AsciiStudio
  class Layer
    attr_accessor :name, :visible, :locked, :opacity
    attr_reader :canvas

    def initialize(canvas:, name: "Layer", visible: true, locked: false, opacity: 1.0)
      raise ArgumentError, "expected Canvas" unless canvas.is_a?(Canvas)
      raise ArgumentError, "opacity must be between 0 and 1" unless opacity.to_f.between?(0.0, 1.0)
      @canvas, @name, @visible, @locked, @opacity = canvas, name.to_s, !!visible, !!locked, opacity.to_f
    end

    def duplicate = self.class.new(canvas: canvas.duplicate, name: "#{name} copy", visible: visible, locked: locked, opacity: opacity)
  end
end
