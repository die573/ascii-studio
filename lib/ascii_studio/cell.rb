# frozen_string_literal: true

module AsciiStudio
  class Cell
    attr_reader :character, :foreground, :background, :transparent

    def initialize(character: " ", foreground: nil, background: nil, transparent: false)
      raise ArgumentError, "character must be one Unicode character" unless character.is_a?(String) && character.each_char.count == 1
      @character = character.freeze
      @foreground = Color.parse(foreground)
      @background = Color.parse(background)
      @transparent = !!transparent
      freeze
    end

    def self.transparent = new(transparent: true)
    def with(**changes) = self.class.new(**to_h.merge(changes))
    def to_h = {character: character, foreground: foreground&.to_s, background: background&.to_s, transparent: transparent}
    def ==(other) = other.is_a?(Cell) && to_h == other.to_h
    alias eql? ==
    def hash = to_h.hash
  end
end
