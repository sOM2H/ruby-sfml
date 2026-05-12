#!/usr/bin/env ruby
# frozen_string_literal: true

# A burst of line segments from the cursor to a fixed set of anchors,
# rebuilt every frame and rendered with a single call to
# RenderTarget#draw_primitives — the lower-level alternative to
# constructing a SFML::VertexArray when you don't need to keep the
# vertex data around between frames.
#
# Esc to quit.
#
#     bundle exec ruby examples/08_draw_primitives/draw_primitives.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 800, 600
ANCHOR_COUNT       = 40

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "draw_primitives", framerate: 60)

# Random anchor points scattered across the window — fixed for the
# session, deterministic seeding so the layout is the same each run.
prng    = Random.new(42)
anchors = Array.new(ANCHOR_COUNT) do
  [prng.rand(WINDOW_W), prng.rand(WINDOW_H)]
end

font = SFML::Font.default
hud  = SFML::Text.new(font, "draw_primitives — move the mouse  •  Esc quits",
                      character_size: 14, fill_color: SFML::Color.white,
                      position: [10, 10])

clock = SFML::Clock.new

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else
    end
  end

  cursor = SFML::Mouse.position(window)
  t      = clock.elapsed.as_seconds

  # Build a fresh array of vertex pairs per frame: each anchor gets a
  # line from the cursor, with a colour that shifts over time. Each
  # line = 2 vertices for the :lines primitive.
  vertices = []
  anchors.each_with_index do |(ax, ay), i|
    hue   = (i * 0.16 + t * 0.5) % 1.0
    color = SFML::Color.new(
      (255 * (Math.sin(hue * 6.283).abs)).to_i,
      (255 * (Math.sin((hue + 0.33) * 6.283).abs)).to_i,
      (255 * (Math.sin((hue + 0.66) * 6.283).abs)).to_i,
    )
    vertices << SFML::Vertex.new([cursor.x, cursor.y], color: color)
    vertices << SFML::Vertex.new([ax, ay],             color: color)
  end

  window.clear(SFML::Color["#0a0c12"])
  window.draw_primitives(vertices, :lines)
  window.draw(hud)
  window.display
end
