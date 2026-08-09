# frozen_string_literal: true

require_relative "test_helper"

class LuminancePaletteTest < Minitest::Test
  def test_perceptual_luminance_and_adjustments
    assert_in_delta 54.213, AsciiStudio::Luminance.from_rgb(255, 0, 0), 0.001
    assert_in_delta 182.376, AsciiStudio::Luminance.from_rgb(0, 255, 0), 0.001
    assert_equal 0.0, AsciiStudio::Luminance.normalize(-20)
    assert_equal 1.0, AsciiStudio::Luminance.adjust(0.5, brightness: 1)
  end
  def test_palette_mapping_and_inversion
    palette = AsciiStudio::Palette.new("@. ")
    assert_equal ["@", ".", " "], [palette.character_for(0), palette.character_for(0.5), palette.character_for(1)]
    assert_equal " ", AsciiStudio::Palette.new("@. ", invert: true).character_for(0)
  end
end

class DitheringTest < Minitest::Test
  def test_floyd_steinberg_quantizes_and_clamps
    result = AsciiStudio::Dithering::FloydSteinberg.new.apply([[0.4, 0.4], [0.4, 0.4]], AsciiStudio::Palette.new("@ "))
    assert result.flatten.all? { |value| [0.0, 1.0].include?(value) }
    assert_equal [[0.0, 1.0], [0.0, 0.0]], result
  end
  def test_bayer_is_deterministic_and_bounded
    result = AsciiStudio::Dithering::Bayer.new.apply(Array.new(4) { Array.new(4, 0.5) }, AsciiStudio::Palette.new("@. "))
    assert_equal result, AsciiStudio::Dithering::Bayer.new.apply(Array.new(4) { Array.new(4, 0.5) }, AsciiStudio::Palette.new("@. "))
    assert result.flatten.all? { |v| v.between?(0, 1) }
    refute_equal 1, result.flatten.uniq.length
  end
end

class ImageImporterTest < Minitest::Test
  def test_aspect_sizing
    assert_equal [80, 20], AsciiStudio::ImageOptions.new(width: 80).dimensions(400, 200)
    assert_equal [80, 10], AsciiStudio::ImageOptions.new(width: 80, height: 10).dimensions(400, 200)
  end
  def test_rgb_integration_preserves_color
    options = AsciiStudio::ImageOptions.new(width: 2, height: 1, color: true)
    canvas = AsciiStudio::ImageImporter.new(palette: AsciiStudio::Palette.new("@ "), options: options).import_rgb([0, 0, 0, 255, 255, 255], width: 2, height: 1)
    assert_equal "@ ", AsciiStudio::Renderers::PlainText.new.render(canvas)
    assert_equal "#000000", canvas.cell_at(0, 0).foreground.to_s
  end
end

class RendererTest < Minitest::Test
  def test_plain_text_ignores_color_and_transparency
    canvas = AsciiStudio::Canvas.new(width: 2, height: 1, cells: [colored_cell("A", "#FF0000"), AsciiStudio::Cell.transparent])
    assert_equal "A ", AsciiStudio::Renderers::PlainText.new.render(canvas)
  end
  def test_ansi_truecolor_minimizes_repeated_sequences_and_resets
    c = colored_cell("X", "#010203", "#040506")
    output = AsciiStudio::Renderers::Ansi.new.render(AsciiStudio::Canvas.new(width: 2, height: 1, cells: [c, c]))
    assert_equal 1, output.scan("38;2;1;2;3").length
    assert_includes output, "48;2;4;5;6"
    assert output.end_with?("\e[0m")
  end
  def test_ansi_256_and_html_escape
    canvas = AsciiStudio::Canvas.new(width: 1, height: 1, cells: [colored_cell("<", "#FF0000")])
    assert_includes AsciiStudio::Renderers::Ansi.new(mode: :ansi256).render(canvas), "38;5;196"
    html = AsciiStudio::Renderers::Html.new.render(canvas)
    assert_includes html, "&lt;"
    assert_includes html, "#FF0000"
  end
  def test_braille_dot_mapping
    matrix = Array.new(4) { Array.new(2, 1.0) }; matrix[0][0] = 0.0
    assert_equal "⠁", AsciiStudio::Renderers::Braille.new.render(matrix)
  end
end
