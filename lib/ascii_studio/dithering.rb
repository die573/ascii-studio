# frozen_string_literal: true

module AsciiStudio
  module Dithering
    class None
      def apply(matrix, _palette) = matrix.map(&:dup)
    end

    class FloydSteinberg
      def apply(matrix, palette)
        values = matrix.map(&:dup)
        height, width = values.length, values.first.length
        height.times do |y|
          width.times do |x|
            old = values[y][x]
            level = palette.level(palette.index_for(old))
            error = old - level
            values[y][x] = level
            distribute(values, x + 1, y, error, 7.0 / 16, width, height)
            distribute(values, x - 1, y + 1, error, 3.0 / 16, width, height)
            distribute(values, x, y + 1, error, 5.0 / 16, width, height)
            distribute(values, x + 1, y + 1, error, 1.0 / 16, width, height)
          end
        end
        values
      end

      private
      def distribute(values, x, y, error, weight, width, height)
        return unless x.between?(0, width - 1) && y.between?(0, height - 1)
        values[y][x] = [[values[y][x] + (error * weight), 0.0].max, 1.0].min
      end
    end

    class Bayer
      MATRIX = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]].freeze
      def apply(matrix, palette)
        steps = palette.characters.length - 1
        matrix.each_with_index.map do |row, y|
          row.each_with_index.map do |value, x|
            threshold = ((MATRIX[y % 4][x % 4] + 0.5) / 16.0 - 0.5) / steps
            [[value + threshold, 0.0].max, 1.0].min
          end
        end
      end
    end
  end
end
