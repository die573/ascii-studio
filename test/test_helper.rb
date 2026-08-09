# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "minitest/autorun"
require "ascii_studio"

module TestFactory
  def colored_cell(char, fg = nil, bg = nil, transparent: false) = AsciiStudio::Cell.new(character: char, foreground: fg, background: bg, transparent: transparent)
  def canvas_from(rows)
    AsciiStudio::Canvas.new(width: rows.first.length, height: rows.length, cells: rows.join.each_char.map { |char| colored_cell(char) })
  end
end

class Minitest::Test
  include TestFactory
end
