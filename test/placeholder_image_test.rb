# frozen_string_literal: true

require_relative "test_helper"

class PlaceholderImageTest < Minitest::Test
  PNG_SIGNATURE = "\x89PNG\r\n\x1A\n".b

  def setup
    fallback = ->(_env) { [404, { "content-type" => "text/plain" }, ["not found"]] }
    @app = PlaceholderImage::Middleware.new(fallback)
    @request = Rack::MockRequest.new(@app)
  end

  def test_exposes_a_version
    refute_nil PlaceholderImage::VERSION
  end

  def test_n_dot_png_generates_a_png
    response = @request.get("/placeholder/40.png")

    assert_equal 200, response.status
    assert_equal "image/png", response.content_type
    assert response.body.start_with?(PNG_SIGNATURE)
    assert_equal response.body.bytesize.to_s, response["content-length"]
  end

  def test_w_x_h_dot_png_generates_a_png
    response = @request.get("/placeholder/40x20.png")

    assert_equal 200, response.status
    assert_equal "image/png", response.content_type
    assert response.body.start_with?(PNG_SIGNATURE)
    assert_equal response.body.bytesize.to_s, response["content-length"]
  end

  def test_accepts_small_images
    response = @request.get("/placeholder/3x3.png")

    assert_equal 200, response.status
    assert_equal "image/png", response.content_type
    assert response.body.start_with?(PNG_SIGNATURE)
    assert_equal response.body.bytesize.to_s, response["content-length"]
  end

  def test_accepts_color_params
    response = @request.get("/placeholder/40x20.png?bg=000&fg=#ff9900")

    assert_equal 200, response.status
    assert_equal "image/png", response.content_type
    assert response.body.start_with?(PNG_SIGNATURE)
    assert_equal response.body.bytesize.to_s, response["content-length"]
  end

  def test_accepts_hex_string_default_colors
    fallback = ->(_env) { [404, {}, []] }
    colors = {
      "#abc" => [0xAA, 0xBB, 0xCC],
      "abc" => [0xAA, 0xBB, 0xCC],
      "#aabbcc" => [0xAA, 0xBB, 0xCC],
      "aabbcc" => [0xAA, 0xBB, 0xCC]
    }

    colors.each do |hex, rgb|
      hex_app = PlaceholderImage::Middleware.new(fallback, image_default_bg: hex, image_default_fg: hex)
      rgb_app = PlaceholderImage::Middleware.new(fallback, image_default_bg: rgb, image_default_fg: rgb)

      assert_equal Rack::MockRequest.new(rgb_app).get("/placeholder/40.png").body, Rack::MockRequest.new(hex_app).get("/placeholder/40.png").body
    end
  end

  def test_rejects_invalid_color_params
    response = @request.get("/placeholder/40x20.png?bg=X")

    assert_equal 400, response.status
  end

  def test_passes_unmatched_paths_to_the_application
    response = @request.get("/other")

    assert_equal 404, response.status
    assert_equal "not found", response.body
  end

  def test_rejects_invalid_dimensions_below_min
    response = @request.get("/placeholder/0.png")

    assert_equal 400, response.status
    assert_includes response.body, "no such image"
  end

  def test_rejects_invalid_dimensions_above_max
    response = @request.get("/placeholder/9999.png")

    assert_equal 400, response.status
    assert_includes response.body, "dimensions must be between"
  end

  def test_rejects_dimensions_exceeding_total_pixel_cap
    capped = PlaceholderImage::Middleware.new(@app, image_max_total_px: 100)
    response = Rack::MockRequest.new(capped).get("/placeholder/50x50.png")

    assert_equal 400, response.status
    assert_includes response.body, "exceeds"
  end

  def test_rejects_malformed_query_strings
    response = @request.get("/placeholder/40x20.png", "QUERY_STRING" => "bg=\xFF")

    assert_equal 400, response.status
    assert_includes response.body, "malformed query string"
  end

  def test_supports_head_requests
    response = @request.request("HEAD", "/placeholder/20.png")

    assert_equal 200, response.status
    assert_empty response.body
    assert_operator response["content-length"].to_i, :positive?
  end

  def test_doesnt_include_body_when_head_request_yields_error
    response = @request.request("HEAD", "/placeholder/0.png")

    assert_equal 400, response.status
    assert_empty response.body
    assert_equal 0, response["content-length"].to_i
  end

  def test_returns_not_modified_for_a_matching_etag
    first = @request.get("/placeholder/20.png")
    response = @request.get("/placeholder/20.png", "HTTP_IF_NONE_MATCH" => first["etag"])

    assert_equal 304, response.status
    assert_empty response.body
  end

  def test_rejects_invalid_request_methods
    response = @request.request("PUT", "/placeholder/20.png")
    assert_equal 405, response.status
  end
end
