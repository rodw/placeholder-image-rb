# frozen_string_literal: true

require_relative "../test_helper"
require "chunky_png"

# Decodes rendered output with ChunkyPNG to verify the hand-rolled PNG encoder
# produces valid images with the expected dimensions, border, and label.
# Individual renderer internals are covered indirectly here and by the
# end-to-end middleware tests.
class RendererTest < Minitest::Test
  BG = [0x11, 0x22, 0x33].freeze
  FG = [0xEE, 0x99, 0x00].freeze

  def render(width, height, text: "#{width}x#{height}")
    png = PlaceholderImage::Renderer.call(width: width, height: height, bg: BG, fg: FG, text: text)
    ChunkyPNG::Image.from_blob(png)
  end

  def assert_pixel(image, x, y, rgb)
    assert_equal ChunkyPNG::Color.rgb(*rgb), image[x, y], "expected #{rgb.inspect} at (#{x}, #{y})"
  end

  def test_decodes_with_the_requested_dimensions
    image = render(200, 100)

    assert_equal 200, image.width
    assert_equal 100, image.height
  end

  def test_draws_the_border_in_the_foreground_color
    image = render(200, 100) # 200x100 -> border thickness min(200,100)/40 = 2

    [[0, 0], [199, 0], [0, 99], [199, 99], [100, 0], [100, 99], [0, 50], [199, 50]].each do |x, y|
      assert_pixel(image, x, y, FG)
    end
  end

  def test_fills_the_background_inside_the_border
    image = render(200, 100)

    # Just inside the 2px border, away from the centered label.
    [[10, 10], [189, 10], [10, 89], [189, 89]].each do |x, y|
      assert_pixel(image, x, y, BG)
    end
  end

  def test_draws_label_pixels_in_the_interior
    image = render(200, 100)
    fg = ChunkyPNG::Color.rgb(*FG)
    label_pixels = (10...190).sum { |x| (10...90).count { |y| image[x, y] == fg } }

    assert_operator label_pixels, :>, 0, "expected foreground label pixels inside the border"
  end

  def test_renders_tiny_images_as_background_only
    image = render(3, 3) # too small for a border or label

    3.times { |x| 3.times { |y| assert_pixel(image, x, y, BG) } }
  end

  def test_custom_colors_round_trip
    png = PlaceholderImage::Renderer.call(width: 40, height: 40, bg: [255, 0, 0], fg: [0, 0, 255], text: "")
    image = ChunkyPNG::Image.from_blob(png)

    assert_equal ChunkyPNG::Color.rgb(255, 0, 0), image[20, 20]
    assert_equal ChunkyPNG::Color.rgb(0, 0, 255), image[0, 0]
  end
end
