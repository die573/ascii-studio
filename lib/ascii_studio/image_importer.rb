# frozen_string_literal: true

module AsciiStudio
  class ImageImporter
    def initialize(palette: Palette.new, options: ImageOptions.new, engine: Engines.select(:auto))
      @palette, @options, @engine = palette, options, engine
    end

    def import(path)
      require "vips"
      image = Vips::Image.new_from_file(path.to_s, access: :sequential).autorot
      width, height = @options.dimensions(image.width, image.height)
      image = image.colourspace("srgb").resize(width.to_f / image.width, vscale: height.to_f / image.height)
      image = image.flatten(background: [255, 255, 255]) if image.has_alpha?
      memory = image.extract_band(0, n: 3).cast("uchar").write_to_memory.unpack("C*")
      import_rgb(memory, width: width, height: height, stride: width * 3)
    rescue LoadError => error
      raise LoadError, "ruby-vips/libvips unavailable: #{error.message}"
    rescue Vips::Error => error
      raise ArgumentError, "could not decode image: #{error.message}"
    end

    def import_rgb(bytes, width:, height:, stride: width * 3)
      raise ArgumentError, "invalid RGB dimensions" unless width.to_i.positive? && height.to_i.positive? && stride >= width * 3
      raise ArgumentError, "RGB buffer is too short" if bytes.length < stride * height
      rows, colors = [], []
      height.times do |y|
        row, color_row = [], []
        width.times do |x|
          offset = (y * stride) + (x * 3)
          rgb = bytes.slice(offset, 3)
          value = Luminance.adjust(Luminance.normalize(Luminance.from_rgb(*rgb)), brightness: @options.brightness, contrast: @options.contrast, gamma: @options.gamma)
          row << value
          color_row << Color.new(*rgb)
        end
        rows << row
        colors << color_row
      end
      dithered = ditherer.apply(rows, @palette)
      indices = @engine.quantize(dithered.flatten, @palette).each
      cells = dithered.each_with_index.flat_map do |row, y|
        row.each_with_index.map do |value, x|
          foreground = @options.color ? colors[y][x] : nil
          background = @options.background ? colors[y][x] : nil
          Cell.new(character: edge_character(rows, x, y) || @palette.characters[indices.next], foreground: foreground, background: background)
        end
      end
      Canvas.new(width: width, height: height, cells: cells)
    end

    private
    def ditherer
      {none: Dithering::None, floyd: Dithering::FloydSteinberg, bayer: Dithering::Bayer, edge: Dithering::None}.fetch(@options.dither).new
    end

    def edge_character(matrix, x, y)
      return unless @options.dither == :edge && x.positive? && y.positive? && x < matrix.first.length - 1 && y < matrix.length - 1
      gx = -matrix[y - 1][x - 1] + matrix[y - 1][x + 1] - (2 * matrix[y][x - 1]) + (2 * matrix[y][x + 1]) - matrix[y + 1][x - 1] + matrix[y + 1][x + 1]
      gy = matrix[y - 1][x - 1] + (2 * matrix[y - 1][x]) + matrix[y - 1][x + 1] - matrix[y + 1][x - 1] - (2 * matrix[y + 1][x]) - matrix[y + 1][x + 1]
      return if Math.hypot(gx, gy) < 0.55
      angle = Math.atan2(gy, gx) * 180 / Math::PI
      return "|" if angle.abs < 22.5 || angle.abs > 157.5
      return "-" if angle.abs.between?(67.5, 112.5)
      angle.positive? ? "/" : "\\"
    end
  end
end
