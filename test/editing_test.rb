# frozen_string_literal: true

require_relative "test_helper"

class CommandsAndHistoryTest < Minitest::Test
  def setup
    @canvas = AsciiStudio::Canvas.new(width: 4, height: 3)
    @history = AsciiStudio::History.new(limit: 2)
    @mark = colored_cell("#")
  end
  def test_put_undo_redo
    @history.execute(AsciiStudio::Commands::PutCell.new(@canvas, 1, 1, @mark), @canvas)
    assert_equal "#", @canvas.cell_at(1, 1).character
    assert @history.undo(@canvas)
    assert_equal " ", @canvas.cell_at(1, 1).character
    assert @history.redo(@canvas)
    assert_equal "#", @canvas.cell_at(1, 1).character
  end
  def test_line_rectangle_and_bounded_history
    @history.execute(AsciiStudio::Commands::DrawLine.new(@canvas, 0, 0, 3, 2, @mark), @canvas)
    assert_equal "#", @canvas.cell_at(3, 2).character
    @history.execute(AsciiStudio::Commands::DrawRectangle.new(@canvas, 0, 0, 2, 2, @mark), @canvas)
    @history.execute(AsciiStudio::Commands::PutCell.new(@canvas, 3, 0, @mark), @canvas)
    assert_equal 2, @history.undo_stack.length
  end
  def test_bucket_fill
    @history.execute(AsciiStudio::Commands::Fill.new(@canvas, 0, 0, @mark), @canvas)
    assert @canvas.each_cell.all? { |cell| cell == @mark }
    @history.undo(@canvas)
    assert @canvas.each_cell.all? { |cell| cell.character == " " }
  end
end

class SelectionClipboardTest < Minitest::Test
  def test_copy_clear_paste_and_multiline_text
    source = canvas_from(["AB", "CD"])
    selection = AsciiStudio::Selection.new(x: 0, y: 0, width: 2, height: 2)
    clipboard = selection.copy(source)
    assert_equal "AB\nCD", clipboard.to_text
    target = AsciiStudio::Canvas.new(width: 3, height: 3)
    selection.paste_command(target, clipboard, at_x: 1, at_y: 1).apply(target)
    assert_equal "D", target.cell_at(2, 2).character
    assert_equal "xy\nz ", AsciiStudio::Clipboard.from_text("xy\nz").to_text
  end
end
