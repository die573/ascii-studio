# frozen_string_literal: true

require "cgi"

module AsciiStudio
  module Renderers
    class PlainText
      def render(canvas) = canvas.each_row.map { |row| row.map { |cell| cell.transparent ? " " : cell.character }.join }.join("\n")
    end

    class Ansi
      RESET = "\e[0m"
      def initialize(mode: :truecolor) = @mode = mode.to_sym
      def render(canvas)
        state = {foreground: nil, background: nil}
        lines = canvas.each_row.map do |row|
          row.map { |cell| ansi_cell(cell, state) }.join + RESET
        ensure
          state.replace(foreground: nil, background: nil)
        end
        lines.join("\n")
      end

      private
      def ansi_cell(cell, state)
        return " " if cell.transparent
        prefix = +""
        {foreground: 38, background: 48}.each do |field, code|
          color = cell.public_send(field)
          next if color == state[field]
          prefix << (color ? sequence(code, color) : "\e[#{field == :foreground ? 39 : 49}m")
          state[field] = color
        end
        prefix + cell.character
      end
      def sequence(code, color)
        return "\e[#{code};2;#{color.to_a.join(';')}m" if @mode == :truecolor
        "\e[#{code};5;#{ansi256(color)}m"
      end
      def ansi256(color)
        r, g, b = color.to_a.map { |channel| (channel / 255.0 * 5).round }
        16 + (36 * r) + (6 * g) + b
      end
    end

    class Html
      def render(canvas, document: true)
        content = canvas.each_row.map do |row|
          row.map do |cell|
            next " " if cell.transparent
            styles = []
            styles << "color:#{cell.foreground}" if cell.foreground
            styles << "background-color:#{cell.background}" if cell.background
            glyph = CGI.escapeHTML(cell.character)
            styles.empty? ? glyph : %(<span style="#{styles.join(';')}">#{glyph}</span>)
          end.join
        end.join("\n")
        pre = %(<pre class="ascii-studio">#{content}</pre>)
        document ? "<!doctype html><meta charset=\"utf-8\"><title>ASCII Studio Export</title><style>body{background:#111;color:#eee}.ascii-studio{font:12px/1 monospace;white-space:pre}</style>#{pre}" : pre
      end
    end

    class Braille
      DOTS = [[0, 0, 1], [0, 1, 2], [0, 2, 4], [1, 0, 8], [1, 1, 16], [1, 2, 32], [0, 3, 64], [1, 3, 128]].freeze
      def render(matrix, threshold: 0.5)
        (0...matrix.length).step(4).map do |y|
          (0...matrix.first.length).step(2).map do |x|
            bits = DOTS.sum { |dx, dy, bit| matrix.dig(y + dy, x + dx).to_f < threshold ? bit : 0 }
            (0x2800 + bits).chr(Encoding::UTF_8)
          end.join
        end.join("\n")
      end
    end
  end
end
