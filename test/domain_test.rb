# frozen_string_literal: true

require_relative "test_helper"

class ColorAndCellTest < Minitest::Test
  def test_color_parses_and_normalizes_hex
    assert_equal [0, 127, 255], AsciiStudio::Color.parse("#007fff").to_a
    assert_equal "#007FFF", AsciiStudio::Color.parse("#007fff").to_s
    assert_raises(ArgumentError) { AsciiStudio::Color.new(-1, 0, 0) }
  end
  def test_unicode_cell_is_immutable
    cell = AsciiStudio::Cell.new(character: "█", foreground: "#112233", transparent: true)
    assert cell.frozen?
    assert_equal "█", cell.character
    assert cell.transparent
    assert_raises(ArgumentError) { AsciiStudio::Cell.new(character: "ab") }
  end
end

class CanvasTest < Minitest::Test
  def test_dimensions_bounds_duplicate_and_resize
    assert_raises(ArgumentError) { AsciiStudio::Canvas.new(width: 0, height: 1) }
    canvas = AsciiStudio::Canvas.new(width: 1, height: 1)
    canvas.put_cell(0, 0, colored_cell("X"))
    assert_equal "X", canvas.duplicate.cell_at(0, 0).character
    assert_equal [2, 2], [canvas.resize(2, 2).width, canvas.resize(2, 2).height]
    assert_raises(IndexError) { canvas.put_cell(1, 0, colored_cell("X")) }
  end
end

class LayerFrameAnimationProjectTest < Minitest::Test
  def test_transparent_layer_compositing_and_merge
    bottom = AsciiStudio::Layer.new(canvas: canvas_from(["ab"]), name: "bottom")
    top_canvas = AsciiStudio::Canvas.new(width: 2, height: 1, fill: AsciiStudio::Cell.transparent)
    top_canvas.put_cell(1, 0, colored_cell("Z"))
    frame = AsciiStudio::Frame.new(layers: [bottom, AsciiStudio::Layer.new(canvas: top_canvas)])
    assert_equal "aZ", AsciiStudio::Renderers::PlainText.new.render(frame.flatten)
    frame.merge_down(1)
    assert_equal 1, frame.layers.length
    assert_equal "aZ", AsciiStudio::Renderers::PlainText.new.render(frame.flatten)
  end
  def test_animation_operations_and_project_metadata
    project = AsciiStudio::Project.blank(width: 2, height: 1, name: "Demo")
    animation = project.animation
    animation.duplicate(0)
    assert_equal 2, animation.frames.length
    animation.move(1, 0)
    animation.delete(1)
    assert_equal 1, animation.frames.length
    assert_raises(ArgumentError) { animation.delete(0) }
    assert_equal [2, 1], [project.width, project.height]
  end
end
