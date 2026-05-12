#!/usr/bin/env ruby
# frozen_string_literal: true

# Capture the rendered scene with `RenderWindow#screenshot` or
# `#capture_image`. The two methods cover the common cases:
#
#   * `screenshot("path.png")` — write a file in one line. Format
#     is inferred from the extension (png / jpg / bmp / tga).
#   * `capture_image` — return an in-memory `SFML::Image` if you
#     want to encode it yourself, attach it to a chat message,
#     hash it for golden-image tests, etc.
#
# Demonstrates:
#   - Saving a screenshot to disk on a key press
#   - Capturing the back-buffer into a CPU `Image` and re-encoding
#     it as raw PNG bytes (for sockets / pasted into messages)
#
# Keys:
#   F5           — save screenshot to /tmp/screenshot-<n>.png
#   F6           — encode to PNG bytes, print first 32 bytes' hash
#   Esc          — quit
#
#     bundle exec ruby examples/16_screenshot/screenshot.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"
require "digest"

class ScreenshotDemo < SFML::App
  width  640
  height 480
  title  "Screenshot — F5 saves, F6 hashes"
  background SFML::Color["#161a1f"]
  antialiasing 4

  on_key :escape, :quit
  on_key :f5,     :save_to_disk
  on_key :f6,     :hash_in_memory

  def setup
    # A few colourful shapes so the screenshot isn't empty.
    @shapes = 5.times.map do |i|
      SFML::CircleShape.new(
        radius:     30,
        origin:     [30, 30],
        position:   [120 + i * 100, 240],
        fill_color: SFML::Color.new(
          (Math.sin(i * 0.9) * 127 + 128).to_i,
          (Math.sin(i * 0.9 + 2) * 127 + 128).to_i,
          (Math.sin(i * 0.9 + 4) * 127 + 128).to_i,
        ),
      )
    end

    @font   = SFML::Font.default
    @hud    = SFML::Text.new(@font, "", character_size: 14,
                             fill_color: SFML::Color.white, position: [10, 10])
    @status = "Press F5 to save a screenshot, F6 to hash one in memory."
    @count  = 0
    @t      = 0.0
  end

  def update(dt)
    @t += dt.as_seconds
    @shapes.each_with_index do |s, i|
      s.position = SFML::Vector2[120 + i * 100, 240 + Math.sin(@t * 2 + i) * 80]
    end
    @hud.string = "#{@status}\n[F5] save  •  [F6] hash"
  end

  def draw
    @shapes.each { |s| window.draw(s) }
    window.draw(@hud)
  end

  def save_to_disk
    @count += 1
    path = File.join(Dir.tmpdir, "screenshot-#{@count}.png")
    window.screenshot(path)
    @status = "Saved #{path} (#{File.size(path)} bytes)"
  end

  def hash_in_memory
    img    = window.capture_image
    bytes  = img.save_to_memory("png")
    digest = Digest::SHA256.hexdigest(bytes)
    @status = "Captured #{img.size.x}×#{img.size.y} image, #{bytes.bytesize} bytes, sha256=#{digest[0..15]}…"
  end
end

require "tmpdir"
ScreenshotDemo.new.run
