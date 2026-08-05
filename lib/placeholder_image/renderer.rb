# frozen_string_literal: true

require "zlib"

module PlaceholderImage
  # Generates a placeholder PNG from dimensions, colors, and label text.
  module Renderer
    LABEL_WIDTH_PCT = 0.80
    LABEL_HEIGHT_PCT = 0.50

    # Minimal 8-bit truecolor PNG encoder.
    class Canvas
      SIGNATURE = "\x89PNG\r\n\x1A\n".b

      attr_reader :width, :height

      def initialize(width, height, rgb)
        @width = width
        @height = height
        @row_bytes = width * 3
        @data = (rgb.pack("C3") * (width * height)).b
      end

      def []=(x, y, rgb)
        return unless x.between?(0, @width - 1) && y.between?(0, @height - 1)

        i = ((y * @width) + x) * 3
        @data.setbyte(i, rgb[0])
        @data.setbyte(i + 1, rgb[1])
        @data.setbyte(i + 2, rgb[2])
      end

      def fill_rect(x, y, width, height, rgb)
        y.upto(y + height - 1) do |py|
          x.upto(x + width - 1) { |px| self[px, py] = rgb }
        end
      end

      def to_png
        raw = String.new(capacity: (@row_bytes + 1) * @height, encoding: Encoding::BINARY)
        @height.times { |y| raw << 0.chr << @data.byteslice(y * @row_bytes, @row_bytes) }
        ihdr = [@width, @height, 8, 2, 0, 0, 0].pack("NNC5") # 8-bit, color type 2 (RGB)

        SIGNATURE +
          chunk("IHDR", ihdr) +
          chunk("IDAT", Zlib::Deflate.deflate(raw, Zlib::BEST_SPEED)) +
          chunk("IEND", "".b)
      end

      private

      def chunk(type, data)
        type = type.b
        [data.bytesize].pack("N") + type + data + [Zlib.crc32(type + data)].pack("N")
      end
    end

    # 5x7 bitmap font, just enough to render dimension labels such as "1024x768".
    module Font
      FONT_WIDTH = 5
      FONT_HEIGHT = 7

      GLYPHS = {
        "0" => %w[01110 10001 10011 10101 11001 10001 01110],
        "1" => %w[00100 01100 00100 00100 00100 00100 01110],
        "2" => %w[01110 10001 00001 00010 00100 01000 11111],
        "3" => %w[11111 00010 00100 00010 00001 10001 01110],
        "4" => %w[00010 00110 01010 10010 11111 00010 00010],
        "5" => %w[11111 10000 11110 00001 00001 10001 01110],
        "6" => %w[00110 01000 10000 11110 10001 10001 01110],
        "7" => %w[11111 00001 00010 00100 01000 01000 01000],
        "8" => %w[01110 10001 10001 01110 10001 10001 01110],
        "9" => %w[01110 10001 10001 01111 00001 00010 01100],
        "x" => %w[00000 00000 10001 01010 00100 01010 10001]
      }.freeze

      def self.advance(scale) = (FONT_WIDTH + 1) * scale
      def self.text_width(text, scale) = text.empty? ? 0 : (advance(scale) * text.length) - scale

      def self.draw(canvas, text, x, y, scale, color)
        text.each_char.with_index do |char, i|
          glyph = GLYPHS[char] or next
          ox = x + (advance(scale) * i)
          glyph.each_with_index do |row, ry|
            row.each_char.with_index do |bit, rx|
              next if bit == "0"

              canvas.fill_rect(ox + (rx * scale), y + (ry * scale), scale, scale, color)
            end
          end
        end
      end
    end

    module_function

    # Render a placeholder PNG.
    #
    # @param width [Integer] image width in pixels.
    # @param height [Integer] image height in pixels.
    # @param bg [Array(Integer, Integer, Integer)] background color as RGB bytes.
    # @param fg [Array(Integer, Integer, Integer)] foreground color, used for the border and label.
    # @param text [String] label drawn centered on the image (digits and "x" only).
    # @return [String] binary PNG data.
    # @example
    #   Renderer.call(width: 320, height: 240, bg: [238, 238, 238], fg: [153, 153, 153], text: "320x240")
    def call(width:, height:, bg:, fg:, text:)
      canvas = Canvas.new(width, height, bg)
      draw_border(canvas, fg)
      draw_label(canvas, text, fg)
      canvas.to_png
    end

    def draw_border(canvas, color)
      width = canvas.width
      height = canvas.height
      thickness = ([width, height].min / 40).clamp(1, 6)
      return if width < 4 * thickness || height < 4 * thickness

      canvas.fill_rect(0, 0, width, thickness, color)
      canvas.fill_rect(0, height - thickness, width, thickness, color)
      canvas.fill_rect(0, 0, thickness, height, color)
      canvas.fill_rect(width - thickness, 0, thickness, height, color)
    end

    def draw_label(canvas, text, color)
      return if text.empty?

      natural_width = Font.text_width(text, 1)
      scale = [(canvas.width * LABEL_WIDTH_PCT / natural_width).floor,
               (canvas.height * LABEL_HEIGHT_PCT / Font::FONT_HEIGHT).floor].min
      return if scale < 1

      Font.draw(canvas,
                text,
                (canvas.width - Font.text_width(text, scale)) / 2,
                (canvas.height - (Font::FONT_HEIGHT * scale)) / 2,
                scale,
                color)
    end

    private_class_method :draw_border, :draw_label

    private_constant :Canvas, :Font
  end
end
