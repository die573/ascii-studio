# frozen_string_literal: true

module AsciiStudio
  class Canvas
    MAX_CELLS = 1_000_000
    attr_reader :width, :height

    def initialize(width:, height:, fill: Cell.new, cells: nil)
      raise ArgumentError, "canvas dimensions must be positive" unless width.is_a?(Integer) && height.is_a?(Integer) && width.positive? && height.positive?
      raise ArgumentError, "canvas is too large" if width * height > MAX_CELLS
      @width, @height = width, height
      @cells = cells ? cells.dup : Array.new(width * height, fill)
      raise ArgumentError, "cell count does not match dimensions" unless @cells.length == width * height && @cells.all? { |cell| cell.is_a?(Cell) }
    end

    def cell_at(x, y) = @cells[index(x, y)]
    def put_cell(x, y, cell)
      raise ArgumentError, "expected Cell" unless cell.is_a?(Cell)
      @cells[index(x, y)] = cell
    end
    def in_bounds?(x, y) = x.is_a?(Integer) && y.is_a?(Integer) && x.between?(0, width - 1) && y.between?(0, height - 1)
    def each_cell(&block) = block ? @cells.each(&block) : @cells.each
    def each_row
      return enum_for(__method__) unless block_given?
      height.times { |y| yield @cells.slice(y * width, width) }
    end
    def duplicate = self.class.new(width: width, height: height, cells: @cells)
    def fill(cell) = @cells.fill(cell)

    def resize(new_width, new_height, fill: Cell.new)
      replacement = self.class.new(width: new_width, height: new_height, fill: fill)
      [height, new_height].min.times do |y|
        [width, new_width].min.times { |x| replacement.put_cell(x, y, cell_at(x, y)) }
      end
      replacement
    end

    def ==(other) = other.is_a?(Canvas) && width == other.width && height == other.height && each_cell.to_a == other.each_cell.to_a

    private

    def index(x, y)
      raise IndexError, "cell (#{x}, #{y}) outside #{width}x#{height}" unless in_bounds?(x, y)
      (y * width) + x
    end
  end
end
