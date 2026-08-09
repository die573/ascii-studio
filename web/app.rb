# frozen_string_literal: true

require "roda"
require "json"
require "base64"
require "tempfile"
require "faye/websocket"
require "uri"
require_relative "../lib/ascii_studio"

module AsciiStudio
  class WebApp < Roda
    MAX_UPLOAD = 12 * 1024 * 1024
    plugin :public, root: File.expand_path("public", __dir__)
    plugin :json
    plugin :default_headers,
           "X-Content-Type-Options" => "nosniff",
           "Referrer-Policy" => "no-referrer",
           "Permissions-Policy" => "camera=(self)",
           "Content-Security-Policy" => "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self' ws: wss:; img-src 'self' data: blob:; media-src 'self' blob:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'"

    route do |route|
      route.public
      route.root { File.read(File.expand_path("views/index.html", __dir__)) }
      route.on "api" do
        route.post "convert" do
          route.halt [413, {"content-type" => "application/json"}, [{error: "upload exceeds 12 MB"}.to_json]] if request.content_length.to_i > MAX_UPLOAD
          upload = route.params["image"]
          route.halt [422, {"content-type" => "application/json"}, [{error: "image is required"}.to_json]] unless upload && upload[:tempfile]
          route.halt [413, {"content-type" => "application/json"}, [{error: "upload exceeds 12 MB"}.to_json]] if upload[:tempfile].size > MAX_UPLOAD
          canvas = self.class.importer(route.params).import(upload[:tempfile].path)
          project = self.class.project_for(canvas, upload[:filename].to_s)
          {text: Renderers::PlainText.new.render(canvas), html: Renderers::Html.new.render(canvas, document: false),
           ansi: Renderers::Ansi.new.render(canvas), aaf: AAF::Writer.new.dump(project), canvas: self.class.canvas_hash(canvas)}
        rescue ArgumentError, LoadError => error
          response.status = 422
          {error: error.message}
        end

        route.post "project/validate" do
          body = request.body.read(MAX_UPLOAD + 1)
          route.halt [413, {"content-type" => "application/json"}, [{valid: false, error: "project exceeds 12 MB"}.to_json]] if body.bytesize > MAX_UPLOAD
          project = AAF::Reader.new.load(body)
          {valid: true, name: project.name, width: project.width, height: project.height, frames: project.animation.frames.length}
        rescue ArgumentError => error
          response.status = 422
          {valid: false, error: error.message}
        end
      end

      route.on "ws" do
        route.halt [426, {"content-type" => "text/plain"}, ["WebSocket required"]] unless Faye::WebSocket.websocket?(env)
        route.halt [403, {"content-type" => "text/plain"}, ["WebSocket origin rejected"]] unless self.class.same_origin?(env)
        socket = Faye::WebSocket.new(env, nil, ping: 20)
        busy = false
        socket.on :message do |event|
          if busy
            socket.send({type: "dropped"}.to_json)
            next
          end
          busy = true
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          begin
            raise ArgumentError, "WebSocket message exceeds 1.5 MB" unless event.data.is_a?(String) && event.data.bytesize <= 1_572_864
            message = JSON.parse(event.data)
            bytes = Base64.strict_decode64(message.fetch("jpeg"))
            raise ArgumentError, "frame exceeds 1 MB" if bytes.bytesize > 1_048_576
            Tempfile.create(["ascii-frame", ".jpg"], binmode: true) do |file|
              file.write(bytes); file.flush
              canvas = self.class.importer(message).import(file.path)
              elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000
              socket.send({type: "frame", id: message["id"], sent_at: message["sent_at"], render_ms: elapsed.round(2),
                           width: canvas.width, height: canvas.height, text: Renderers::PlainText.new.render(canvas), html: self.class.truthy?(message["color"]) ? Renderers::Html.new.render(canvas, document: false) : nil}.to_json)
            end
          rescue JSON::ParserError, KeyError, ArgumentError, LoadError => error
            socket.send({type: "error", error: error.message}.to_json)
          ensure
            busy = false
          end
        end
        socket.rack_response
      end

      route.get "health" do
        {status: "ok", version: VERSION, zig: Engines.select(:auto).is_a?(Engines::ZigEngine)}
      end
    end

    def importer(params) = WebApp.importer(params)
    def project_for(canvas, name) = WebApp.project_for(canvas, name)
    def canvas_hash(canvas) = WebApp.canvas_hash(canvas)
    def truthy?(value) = WebApp.truthy?(value)
    def self.importer(params)
      palette = Palette.new(params.fetch("charset", Palette::BUILT_INS[Palette::DEFAULT_NAME]), invert: truthy?(params["invert"]))
      options = ImageOptions.new(width: integer(params["width"], 80, 1, 320), height: optional_integer(params["height"], 1, 240),
                                 aspect: float(params["aspect"], 0.5), brightness: float(params["brightness"], 0),
                                 contrast: float(params["contrast"], 1), gamma: float(params["gamma"], 1),
                                 dither: params.fetch("dither", "none"), color: truthy?(params["color"]), background: truthy?(params["background"]))
      ImageImporter.new(palette: palette, options: options, engine: Engines.select(params.fetch("engine", "auto")))
    end
    def self.integer(value, default, min, max) = [[Integer(value || default), min].max, max].min
    def self.optional_integer(value, min, max) = value.to_s.empty? ? nil : integer(value, min, min, max)
    def self.float(value, default) = Float(value || default)
    def self.truthy?(value) = %w[1 true on yes].include?(value.to_s)
    def self.project_for(canvas, name) = Project.new(name: name.empty? ? "Imported image" : name, animation: Animation.new(frames: [Frame.new(layers: [Layer.new(canvas: canvas)])]))
    def self.canvas_hash(canvas) = {width: canvas.width, height: canvas.height, cells: canvas.each_cell.map(&:to_h)}
    def self.same_origin?(env)
      origin = URI.parse(env.fetch("HTTP_ORIGIN"))
      origin.host&.casecmp?(env.fetch("SERVER_NAME")) && origin.port == Integer(env.fetch("SERVER_PORT"))
    rescue KeyError, URI::InvalidURIError, ArgumentError
      false
    end
  end
end
