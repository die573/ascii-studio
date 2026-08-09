# frozen_string_literal: true

module AsciiStudio
  class Clipboard
    attr_reader :width, :height, :cells
    def initialize(width:, height:, cells:)
      raise ArgumentError, "clipboard dimensions mismatch" unless cells.length == width * height
      @width, @height, @cells = width, height, cells.dup.freeze
    end
    def cell_at(x, y) = cells[(y * width) + x]
    def self.from_text(text, foreground: nil, background: nil)
      rows = text.to_s.gsub("\r\n", "\n").split("\n", -1)
      rows.pop if rows.last == ""
      rows = [""] if rows.empty?
      width = [rows.map { |row| row.each_char.count }.max, 1].max
      cells = rows.flat_map do |row|
        glyphs = row.each_char.map { |char| Cell.new(character: char, foreground: foreground, background: background) }
        glyphs + Array.new(width - glyphs.length) { Cell.transparent }
      end
      new(width: width, height: rows.length, cells: cells)
    end
    def to_text = (0...height).map { |y| (0...width).map { |x| cell_at(x, y).transparent ? " " : cell_at(x, y).character }.join }.join("\n")
  end

  class Selection
    attr_reader :x, :y, :width, :height
    def initialize(x:, y:, width:, height:)
      raise ArgumentError, "selection dimensions must be positive" unless width.positive? && height.positive?
      @x, @y, @width, @height = x, y, width, height
    end
    def copy(canvas)
      cells = height.times.flat_map do |dy|
        width.times.map { |dx| canvas.in_bounds?(x + dx, y + dy) ? canvas.cell_at(x + dx, y + dy) : Cell.transparent }
      end
      Clipboard.new(width: width, height: height, cells: cells)
    end
    def clear_command(canvas) = Commands::CellChanges.capture(canvas, coordinates, Cell.transparent)
    def paste_command(canvas, clipboard, at_x: x, at_y: y, transparent: true)
      changes = clipboard.height.times.flat_map do |dy|
        clipboard.width.times.filter_map do |dx|
          cell = clipboard.cell_at(dx, dy)
          tx, ty = at_x + dx, at_y + dy
          next if !canvas.in_bounds?(tx, ty) || (transparent && cell.transparent)
          Commands::Change.new(x: tx, y: ty, before: canvas.cell_at(tx, ty), after: cell)
        end
      end
      Commands::CellChanges.new(changes)
    end
    def coordinates = height.times.flat_map { |dy| width.times.map { |dx| [x + dx, y + dy] } }
  end
end
