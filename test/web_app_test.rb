# frozen_string_literal: true

require_relative "test_helper"
require "rack/test"
require_relative "../web/app"

class WebAppTest < Minitest::Test
  include Rack::Test::Methods
  def app = AsciiStudio::WebApp.app
  def test_home_and_health
    get "/"
    assert last_response.ok?
    assert_includes last_response.body, "ASCII STUDIO"
    assert_equal "nosniff", last_response.headers["x-content-type-options"]
    assert_includes last_response.headers["content-security-policy"], "frame-ancestors 'none'"
    get "/health"
    assert last_response.ok?
    assert_equal "ok", JSON.parse(last_response.body)["status"]
  end
  def test_project_validation
    project = AsciiStudio::Project.blank(width: 2, height: 2)
    post "/api/project/validate", AsciiStudio::AAF::Writer.new.dump(project), "CONTENT_TYPE" => "application/json"
    assert last_response.ok?
    assert JSON.parse(last_response.body)["valid"]
  end
  def test_image_upload_uses_shared_engine
    file = Rack::Test::UploadedFile.new(File.expand_path("../examples/sample.jpg", __dir__), "image/jpeg", true)
    post "/api/convert", {"image" => file, "width" => "16", "dither" => "floyd"}
    assert last_response.ok?, last_response.body
    result = JSON.parse(last_response.body)
    assert_equal 16, result.dig("canvas", "width")
    assert_equal 16, result.fetch("text").lines.first.chomp.length
    assert_equal "ASCII-STUDIO", JSON.parse(result.fetch("aaf")).fetch("magic")
  end
  def test_websocket_origin_validation
    assert AsciiStudio::WebApp.same_origin?("HTTP_ORIGIN" => "http://localhost:9292", "SERVER_NAME" => "localhost", "SERVER_PORT" => "9292")
    refute AsciiStudio::WebApp.same_origin?("HTTP_ORIGIN" => "https://evil.example", "SERVER_NAME" => "localhost", "SERVER_PORT" => "9292")
    refute AsciiStudio::WebApp.same_origin?({})
  end
end