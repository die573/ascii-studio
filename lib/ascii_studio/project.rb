# frozen_string_literal: true

require "time"

module AsciiStudio
  class Project
    attr_accessor :name, :author, :updated_at, :palette, :settings
    attr_reader :created_at, :animation

    def initialize(name:, animation:, author: nil, created_at: Time.now.utc, updated_at: created_at, palette: Palette::DEFAULT_NAME, settings: {})
      @name, @author, @animation = name.to_s, author, animation
      @created_at, @updated_at = time(created_at), time(updated_at)
      @palette, @settings = palette.to_s, settings.dup
    end
    def width = animation.frames.first.width
    def height = animation.frames.first.height

    def self.blank(width:, height:, name: "Untitled")
      canvas = Canvas.new(width: width, height: height, fill: Cell.transparent)
      new(name: name, animation: Animation.new(frames: [Frame.new(layers: [Layer.new(canvas: canvas)])]))
    end

    private
    def time(value) = value.is_a?(Time) ? value.utc : Time.iso8601(value.to_s)
  end
end
