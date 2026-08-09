# frozen_string_literal: true

module AsciiStudio
  class Palette
    BUILT_INS = {
      "classic" => "@%#*+=-:. ",
      "ascending" => " .:-=+*#%@",
      "blocks" => "█▓▒░ ",
      "compact" => "@#:. ",
      "detailed" => "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/|()1{}[]?-_+~<>i!lI;:,\"^`'. "
    }.freeze
    DEFAULT_NAME = "classic"
    attr_reader :characters

    def initialize(characters = BUILT_INS.fetch(DEFAULT_NAME), invert: false)
      raise ArgumentError, "palette needs at least two characters" unless characters.is_a?(String) && characters.each_char.count >= 2
      @characters = (invert ? characters.each_char.to_a.reverse : characters.each_char.to_a).freeze
    end
    def self.named(name, invert: false) = new(BUILT_INS.fetch(name) { raise ArgumentError, "unknown palette #{name}" }, invert: invert)
    def character_for(value) = characters[index_for(value)]
    def index_for(value) = ([[value.to_f, 0.0].max, 1.0].min * (characters.length - 1)).round
    def level(index) = index.to_f / (characters.length - 1)
    def to_s = characters.join
  end
end
