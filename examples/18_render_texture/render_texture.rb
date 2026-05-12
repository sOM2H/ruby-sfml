#!/usr/bin/env ruby
# frozen_string_literal: true

# Trail / motion-blur effect via SFML::RenderTexture. The classic
# "don't clear, fade" trick: every frame we paint a slightly transparent
# black rectangle over the whole offscreen texture (so old pixels decay
# toward black) and then draw new shape positions on top. The window
# just displays the texture each frame.
#
# Demonstrates:
#   - RenderTexture as a persistent off-screen buffer
#   - Drawing the same drawables (CircleShape, etc.) on a texture target
#     instead of the window — no API change in the drawable
#   - Sprite backed by rt.texture (borrowed lifetime — RenderTexture owns
#     the underlying sf::Texture, so we keep `rt` alive in main scope)
#
# Controls:
#   click anywhere    spawn a bright burst at the cursor
#   space             clear the trail buffer
#   Esc               quit
#
#     bundle exec ruby examples/18_render_texture/render_texture.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 800, 600

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Render texture", framerate: 60)

# The off-screen buffer the trail builds up on. Same size as the window
# so the displayed sprite maps 1:1.
rt = SFML::RenderTexture.new(WINDOW_W, WINDOW_H, smooth: true)
rt.clear(SFML::Color.black)
rt.display

# Sprite that displays the trail buffer in the window. Backed by the
# borrowed rt.texture — `rt` must outlive `trail_sprite`.
trail_sprite = SFML::Sprite.new(rt.texture)

# Faded overlay: each frame we draw this over the whole RT to gradually
# darken old trail pixels. Lower alpha = longer trail.
fade = SFML::RectangleShape.new(
  size:       [WINDOW_W, WINDOW_H],
  fill_color: SFML::Color.new(0, 0, 0, 14),
)

# The "head" — moves in a Lissajous curve so the trail draws figure-8s.
head = SFML::CircleShape.new(
  radius:     8,
  origin:     [8, 8],
  fill_color: SFML::Color.cornflower_blue,
)

# Smaller bright dots for click bursts.
burst_template = SFML::CircleShape.new(
  radius:     4,
  origin:     [4, 4],
  fill_color: SFML::Color.new(255, 220, 80),
)

font = SFML::Font.default
hud  = SFML::Text.new(font, "", character_size: 14, fill_color: SFML::Color.white,
                      position: [10, 10])

clock = SFML::Clock.new

while window.open?
  t = clock.elapsed.as_seconds

  click_pos = nil
  window.each_event do |event|
    case event
    in {type: :closed}                              then window.close
    in {type: :key_pressed, code: :escape}          then window.close
    in {type: :key_pressed, code: :space}
      rt.clear(SFML::Color.black)
      rt.display
    in {type: :mouse_button_pressed, button: :left, position: {x:, y:}}
      click_pos = SFML::Vector2[x, y]
    else
    end
  end

  # 1. Fade old trail toward black (don't full-clear).
  rt.draw(fade)

  # 2. Paint the moving head onto the buffer.
  head.position = [
    WINDOW_W / 2 + Math.sin(t * 0.9) * (WINDOW_W * 0.4),
    WINDOW_H / 2 + Math.cos(t * 1.7) * (WINDOW_H * 0.35),
  ]
  # Hue-shift via sin: cyan -> magenta -> yellow -> ...
  head.fill_color = SFML::Color.new(
    (128 + Math.sin(t)         * 127).to_i.clamp(0, 255),
    (128 + Math.sin(t + 2.094) * 127).to_i.clamp(0, 255),
    (128 + Math.sin(t + 4.188) * 127).to_i.clamp(0, 255),
  )
  rt.draw(head)

  # 3. Click burst (one frame, bright, sticks until faded).
  if click_pos
    burst_template.position = [click_pos.x, click_pos.y]
    rt.draw(burst_template)
  end

  # 4. Commit the offscreen buffer.
  rt.display

  # 5. Show the buffer in the window.
  window.clear(SFML::Color.black)
  window.draw(trail_sprite)

  hud.string = "rendered via SFML::RenderTexture\n" \
               "click to spark  •  space to clear  •  Esc quits"
  window.draw(hud)

  window.display
end
