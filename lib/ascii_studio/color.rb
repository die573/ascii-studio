# frozen_string_literal: true

module AsciiStudio
  class Color
    attr_reader :red, :green, :blue

    def initialize(red, green, blue)
      @red, @green, @blue = [red, green, blue].map do |value|
        raise ArgumentError, "color channels must be integers from 0 to 255" unless value.is_a?(Integer) && value.between?(0, 255)
        value
      end
      freeze
    end

    def self.parse(value)
      return value if value.is_a?(self)
      return nil if value.nil?
      raise ArgumentError, "invalid color" unless value.match?(/\A#[0-9a-f]{6}\z/i)
      new(*value.delete_prefix("#").scan(/../).map { |part| part.to_i(16) })
    end

    def to_s = format("#%02X%02X%02X", red, green, blue)
    def to_a = [red, green, blue]
    def ==(other) = other.is_a?(Color) && to_a == other.to_a
    alias eql? ==
    def hash = to_a.hash
  end
end
