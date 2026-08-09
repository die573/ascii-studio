# frozen_string_literal: true

module AsciiStudio
  module Exporters
    class Text
      def export(project) = Renderers::PlainText.new.render(project.animation.frames.first.flatten)
    end
    class Ansi
      def initialize(mode: :truecolor) = @renderer = Renderers::Ansi.new(mode: mode)
      def export(project) = @renderer.render(project.animation.frames.first.flatten)
    end
    class Html
      def export(project)
        frames = project.animation.frames.map do |frame|
          {duration: frame.duration_ms, html: Renderers::Html.new.render(frame.flatten, document: false)}
        end
        encoded = JSON.generate(frames).gsub("</", "<\\/")
        <<~HTML
          <!doctype html><meta charset="utf-8"><title>#{CGI.escapeHTML(project.name)}</title>
          <style>body{margin:0;display:grid;place-items:center;min-height:100vh;background:#111;color:#eee}.ascii-studio{font:12px/1 monospace}</style>
          <main id="stage"></main><script>const f=#{encoded};let i=0,s=document.querySelector('#stage');function n(){s.innerHTML=f[i].html;setTimeout(n,f[i=(i+1)%f.length].duration)}n()</script>
        HTML
      end
    end
    class AAF
      def export(project) = AsciiStudio::AAF::Writer.new.dump(project)
    end
  end
end
