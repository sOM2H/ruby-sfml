#!/usr/bin/env ruby
# frozen_string_literal: true

# A tiny paint app: hold the LEFT mouse button to draw, RIGHT to clear.
# Demonstrates SFML::Mouse:
#   - Mouse.position(window) for window-relative pointer coords each frame
#   - Mouse.button_pressed?(:left) for "is currently held" — distinct from
#     :mouse_button_pressed events which fire once per click.
#
#     bundle exec ruby examples/05_mouse_demo/mouse_demo.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

window = SFML::RenderWindow.new(800, 600, "ruby-sfml mouse demo", framerate: 60)

strokes = []  # CircleShapes accumulated since last clear
last_pos = nil

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                              then window.close
    in {type: :key_pressed, code: :escape}          then window.close
    in {type: :mouse_button_pressed, button: :right} then strokes.clear
    else
    end
  end

  if SFML::Mouse.button_pressed?(:left)
    pos = SFML::Mouse.position(window)
    # Skip duplicate frames where the cursor hasn't moved — keeps the
    # stroke array from growing unbounded while idle-clicking.
    if pos != last_pos
      strokes << SFML::CircleShape.new(
        radius:     6,
        origin:     [6, 6],
        position:   [pos.x, pos.y],
        fill_color: SFML::Color.cornflower_blue,
      )
      last_pos = pos
    end
  else
    last_pos = nil
  end

  window.clear(SFML::Color["#0a0a0a"])
  strokes.each { |s| window.draw(s) }
  window.display
end
