# frozen_string_literal: true

require_relative "test_helper"

class AAFTest < Minitest::Test
  def project
    p = AsciiStudio::Project.blank(width: 2, height: 1, name: "Round trip")
    p.animation.frames[0].layers[0].canvas.put_cell(0, 0, colored_cell("Ω", "#123456", "#654321"))
    p.animation.duplicate(0); p.animation.frames[1].duration_ms = 250; p
  end
  def test_round_trip_reproduces_project
    loaded = AsciiStudio::AAF::Reader.new.load(AsciiStudio::AAF::Writer.new.dump(project))
    assert_equal "Round trip", loaded.name
    assert_equal 2, loaded.animation.frames.length
    assert_equal 250, loaded.animation.frames[1].duration_ms
    assert_equal project.animation.frames[0].flatten, loaded.animation.frames[0].flatten
  end
  def test_rejects_malformed_magic_version_and_dimensions
    assert_raises(ArgumentError) { AsciiStudio::AAF::Reader.new.load("not json") }
    assert_match(/magic/, assert_raises(ArgumentError) { AsciiStudio::AAF::Reader.new.load('{"magic":"BAD","version":1}') }.message)
    data = JSON.parse(AsciiStudio::AAF::Writer.new.dump(project)); data["version"] = 9
    assert_match(/unsupported/, assert_raises(ArgumentError) { AsciiStudio::AAF::Reader.new.load(data.to_json) }.message)
  end
end

class ExporterAndEngineTest < Minitest::Test
  def setup
    @project = AsciiStudio::Project.blank(width: 1, height: 1)
    @project.animation.frames.first.layers.first.canvas.put_cell(0, 0, colored_cell("X", "#FF0000"))
  end
  def test_all_exporters
    assert_equal "X", AsciiStudio::Exporters::Text.new.export(@project)
    assert_includes AsciiStudio::Exporters::Ansi.new.export(@project), "\e[38;2;255;0;0m"
    assert_includes AsciiStudio::Exporters::Html.new.export(@project), "setTimeout"
    assert_equal "ASCII-STUDIO", JSON.parse(AsciiStudio::Exporters::AAF.new.export(@project))["magic"]
  end
  def test_ruby_engine_and_auto_fallback
    palette = AsciiStudio::Palette.new("@ ")
    assert_equal [0, 1], AsciiStudio::Engines::RubyEngine.new.indices([0, 1], palette)
    assert_includes [AsciiStudio::Engines::RubyEngine, AsciiStudio::Engines::ZigEngine], AsciiStudio::Engines.select(:auto).class
  end
end
