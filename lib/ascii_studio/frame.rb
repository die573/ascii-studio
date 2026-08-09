# frozen_string_literal: true

module AsciiStudio
  class Frame
    attr_accessor :duration_ms
    attr_reader :layers

    def initialize(layers:, duration_ms: 100)
      raise ArgumentError, "frame needs at least one layer" if layers.empty? || !layers.all? { |layer| layer.is_a?(Layer) }
      raise ArgumentError, "frame duration must be positive" unless duration_ms.to_i.positive?
      dimensions = layers.map { |layer| [layer.canvas.width, layer.canvas.height] }.uniq
      raise ArgumentError, "all layers must have matching dimensions" unless dimensions.one?
      @layers, @duration_ms = layers, duration_ms.to_i
    end

    def width = layers.first.canvas.width
    def height = layers.first.canvas.height
    def duplicate = self.class.new(layers: layers.map(&:duplicate), duration_ms: duration_ms)

    def flatten
      result = Canvas.new(width: width, height: height, fill: Cell.transparent)
      layers.each do |layer|
        next unless layer.visible
        layer.canvas.each_row.with_index do |row, y|
          row.each_with_index { |cell, x| result.put_cell(x, y, cell) unless cell.transparent }
        end
      end
      result
    end

    def merge_down(index)
      raise IndexError, "cannot merge bottom layer" unless index.between?(1, layers.length - 1)
      upper, lower = layers[index], layers[index - 1]
      upper.canvas.each_row.with_index do |row, y|
        row.each_with_index { |cell, x| lower.canvas.put_cell(x, y, cell) unless cell.transparent }
      end
      layers.delete_at(index)
      lower
    end
  end
end
