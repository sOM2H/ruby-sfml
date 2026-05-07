#!/usr/bin/env ruby
# frozen_string_literal: true

# Paint individual pixels with the mouse onto a CPU-side Image, then
# upload it to a GPU Texture and draw it through a Sprite. Demonstrates:
#   - SFML::Image as a writable pixel buffer (img[x, y] = color)
#   - Texture#update for re-uploading the image to the same GPU texture
#     each frame (no allocation in the hot path)
#   - Sprite displaying the texture stretched to fill the window
#
# Controls:
#   left mouse drag    paint with the current colour
#   right mouse drag   erase (paint transparent)
#   1 / 2 / 3 / 4      pick colour: white / red / green / blue
#   c                  clear the canvas
#   s                  save canvas to ./pixel_paint.png
#   Esc                quit
#
#     bundle exec ruby examples/10_pixel_paint/pixel_paint.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

CANVAS_W, CANVAS_H = 200, 150     # low-res buffer; the sprite scales it up
SCALE              = 4            # so the window is 800x600
WINDOW_W           = CANVAS_W * SCALE
WINDOW_H           = CANVAS_H * SCALE

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Pixel paint")

# CPU-side canvas + GPU-side mirror.
canvas  = SFML::Image.new(CANVAS_W, CANVAS_H, fill: SFML::Color["#0e0e10"])
texture = SFML::Texture.from_image(canvas)
sprite  = SFML::Sprite.new(texture, scale: [SCALE, SCALE])

# A small HUD swatch showing the active colour.
font     = SFML::Font.default
hud_text = SFML::Text.new(font, "", character_size: 14,
                          fill_color: SFML::Color.white, position: [10, 10])
swatch   = SFML::RectangleShape.new(size: [14, 14], position: [10, WINDOW_H - 24],
                                    fill_color: SFML::Color.white,
                                    outline_color: SFML::Color["#666"],
                                    outline_thickness: 1)

current_color = SFML::Color.white
clean         = true   # tracks whether we need to re-upload texture

def paint_at(canvas, window_pos, color)
  # Window pixel → canvas pixel via the SCALE factor.
  x = window_pos.x / SCALE
  y = window_pos.y / SCALE
  return false unless (0...CANVAS_W).cover?(x) && (0...CANVAS_H).cover?(y)
  canvas[x, y] = color
  true
end

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                              then window.close
    in {type: :key_pressed, code: :escape}          then window.close

    in {type: :key_pressed, code: :num1}            then current_color = SFML::Color.white
    in {type: :key_pressed, code: :num2}            then current_color = SFML::Color.red
    in {type: :key_pressed, code: :num3}            then current_color = SFML::Color.green
    in {type: :key_pressed, code: :num4}            then current_color = SFML::Color.cornflower_blue

    in {type: :key_pressed, code: :c}
      CANVAS_H.times { |y| CANVAS_W.times { |x| canvas[x, y] = SFML::Color["#0e0e10"] } }
      clean = false

    in {type: :key_pressed, code: :s}
      out = "pixel_paint.png"
      canvas.save(out)
      puts "saved canvas → #{out}"

    else
    end
  end

  # Mouse painting (polling-based — feels smoother than clicks-only)
  pos = SFML::Mouse.position(window)
  if SFML::Mouse.button_pressed?(:left)
    clean = false if paint_at(canvas, pos, current_color)
  elsif SFML::Mouse.button_pressed?(:right)
    clean = false if paint_at(canvas, pos, SFML::Color["#0e0e10"])
  end

  # Re-upload only when the canvas actually changed this frame.
  unless clean
    texture.update(canvas)
    clean = true
  end

  hud_text.string = "1/2/3/4 colour  •  LMB paint  •  RMB erase  •  C clear  •  S save  •  Esc quit"
  swatch.fill_color = current_color

  window.clear(SFML::Color["#0a0a0a"])
  window.draw(sprite)
  window.draw(hud_text)
  window.draw(swatch)
  window.display
end
