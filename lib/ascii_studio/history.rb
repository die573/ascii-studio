# frozen_string_literal: true

module AsciiStudio
  module Commands
    Change = Data.define(:x, :y, :before, :after)

    class CellChanges
      attr_reader :changes
      def initialize(changes) = @changes = changes.freeze
      def apply(canvas) = changes.each { |change| canvas.put_cell(change.x, change.y, change.after) }
      def undo(canvas) = changes.reverse_each { |change| canvas.put_cell(change.x, change.y, change.before) }

      def self.capture(canvas, coordinates, cell)
        changes = coordinates.uniq.filter_map do |x, y|
          next unless canvas.in_bounds?(x, y)
          Change.new(x: x, y: y, before: canvas.cell_at(x, y), after: cell)
        end
        CellChanges.new(changes)
      end
    end

    class PutCell < CellChanges
      def initialize(canvas, x, y, cell) = super([Change.new(x: x, y: y, before: canvas.cell_at(x, y), after: cell)])
    end

    class DrawLine < CellChanges
      def initialize(canvas, x0, y0, x1, y1, cell)
        points, dx, dy = [], (x1 - x0).abs, -(y1 - y0).abs
        sx, sy, error = x0 < x1 ? 1 : -1, y0 < y1 ? 1 : -1, (x1 - x0).abs - (y1 - y0).abs
        loop do
          points << [x0, y0]
          break if x0 == x1 && y0 == y1
          twice = 2 * error
          error += dy and x0 += sx if twice >= dy
          error += dx and y0 += sy if twice <= dx
        end
        super(self.class.capture(canvas, points, cell).changes)
      end
    end

    class DrawRectangle < CellChanges
      def initialize(canvas, x0, y0, x1, y1, cell, filled: false)
        left, right = [x0, x1].minmax
        top, bottom = [y0, y1].minmax
        points = (top..bottom).flat_map do |y|
          (left..right).filter_map { |x| [x, y] if filled || y == top || y == bottom || x == left || x == right }
        end
        super(self.class.capture(canvas, points, cell).changes)
      end
    end

    class Fill < CellChanges
      def initialize(canvas, x, y, replacement)
        target, queue, seen, points = canvas.cell_at(x, y), [[x, y]], {}, []
        until queue.empty?
          cx, cy = queue.shift
          next unless canvas.in_bounds?(cx, cy) && !seen[[cx, cy]] && canvas.cell_at(cx, cy) == target
          seen[[cx, cy]] = true
          points << [cx, cy]
          queue.concat([[cx + 1, cy], [cx - 1, cy], [cx, cy + 1], [cx, cy - 1]])
        end
        super(self.class.capture(canvas, points, replacement).changes)
      end
    end
  end

  class History
    attr_reader :undo_stack, :redo_stack
    def initialize(limit: 200) = (@limit, @undo_stack, @redo_stack = limit, [], [])
    def execute(command, target)
      command.apply(target)
      undo_stack << command
      undo_stack.shift while undo_stack.length > @limit
      redo_stack.clear
      command
    end
    def undo(target)
      return false unless (command = undo_stack.pop)
      command.undo(target)
      redo_stack << command
      true
    end
    def redo(target)
      return false unless (command = redo_stack.pop)
      command.apply(target)
      undo_stack << command
      true
    end
  end
end
