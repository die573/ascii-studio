# frozen_string_literal: true

module AsciiStudio
  class Animation
    attr_accessor :loop, :default_fps
    attr_reader :frames

    def initialize(frames:, default_fps: 10, loop: true)
      raise ArgumentError, "animation needs a frame" if frames.empty? || !frames.all? { |frame| frame.is_a?(Frame) }
      raise ArgumentError, "FPS must be positive" unless default_fps.to_f.positive?
      raise ArgumentError, "all frames must match dimensions" unless frames.map { |frame| [frame.width, frame.height] }.uniq.one?
      @frames, @default_fps, @loop = frames, default_fps.to_f, !!loop
    end

    def add(frame, index: frames.length)
      raise ArgumentError, "frame dimensions differ" unless [frame.width, frame.height] == [frames.first.width, frames.first.height]
      frames.insert(index, frame)
    end
    def duplicate(index) = frames.insert(index + 1, frames.fetch(index).duplicate)
    def delete(index)
      raise ArgumentError, "animation must retain one frame" if frames.one?
      frames.delete_at(index) || raise(IndexError, "frame not found")
    end
    def move(from, to) = frames.insert(to, frames.delete_at(from) || raise(IndexError, "frame not found"))
  end
end
