#!/usr/bin/env ruby
# frozen_string_literal: true

# A ball bouncing inside the window. Demonstrates:
#   - per-frame dt-based integration via SFML::Clock
#   - CircleShape with origin set to its center for natural positioning
#   - RectangleShape used as a static "court" outline
#   - case/in pattern matching for events
#
# Esc or close button to quit.
#
#     bundle exec ruby examples/04_bouncing_ball/bouncing_ball.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

WIDTH, HEIGHT = 800, 600
RADIUS        = 25

window = SFML::RenderWindow.new(WIDTH, HEIGHT, "Bouncing ball", framerate: 60)

court = SFML::RectangleShape.new(
  size:              [WIDTH - 20, HEIGHT - 20],
  position:          [10, 10],
  fill_color:        SFML::Color.transparent,
  outline_color:     SFML::Color["#444"],
  outline_thickness: 2,
)

ball = SFML::CircleShape.new(
  radius:     RADIUS,
  origin:     [RADIUS, RADIUS], # so position = center
  position:   [WIDTH / 2, HEIGHT / 2],
  fill_color: SFML::Color.cornflower_blue,
)

velocity = SFML::Vector2[280, 220]
clock    = SFML::Clock.new

while window.open?
  dt = clock.restart.as_seconds

  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    in {type: :key_pressed, code: :space}
      # spacebar: re-center and re-launch
      ball.position = [WIDTH / 2, HEIGHT / 2]
      velocity      = SFML::Vector2[280, 220]
    else
      # ignore
    end
  end

  # Integrate, then resolve wall collisions by clamping + reversing.
  next_pos = ball.position + velocity * dt
  vx, vy   = velocity.x, velocity.y

  if next_pos.x < RADIUS
    next_pos = SFML::Vector2[RADIUS, next_pos.y]
    vx = vx.abs
  elsif next_pos.x > WIDTH - RADIUS
    next_pos = SFML::Vector2[WIDTH - RADIUS, next_pos.y]
    vx = -vx.abs
  end

  if next_pos.y < RADIUS
    next_pos = SFML::Vector2[next_pos.x, RADIUS]
    vy = vy.abs
  elsif next_pos.y > HEIGHT - RADIUS
    next_pos = SFML::Vector2[next_pos.x, HEIGHT - RADIUS]
    vy = -vy.abs
  end

  velocity      = SFML::Vector2[vx, vy]
  ball.position = next_pos

  window.clear(SFML::Color["#1a1a1a"])
  window.draw(court)
  window.draw(ball)
  window.display
end
