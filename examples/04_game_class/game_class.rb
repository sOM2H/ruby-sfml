#!/usr/bin/env ruby
# frozen_string_literal: true

# Same idea as bouncing_ball.rb but built on top of SFML::Game. Compare the
# two files to see how much boilerplate the lifecycle class removes.
#
#     bundle exec ruby examples/04_game_class/game_class.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

class BouncingBall < SFML::Game
  RADIUS = 25

  def setup
    @ball = SFML::CircleShape.new(
      radius:     RADIUS,
      origin:     [RADIUS, RADIUS],
      position:   [width / 2, height / 2],
      fill_color: SFML::Color.cornflower_blue,
    )
    @velocity = SFML::Vector2[280, 220]
  end

  def update(dt)
    seconds  = dt.as_seconds
    next_pos = @ball.position + @velocity * seconds
    vx, vy   = @velocity.x, @velocity.y

    if next_pos.x < RADIUS || next_pos.x > width - RADIUS
      vx = -vx
      next_pos = SFML::Vector2[next_pos.x.clamp(RADIUS, width - RADIUS), next_pos.y]
    end
    if next_pos.y < RADIUS || next_pos.y > height - RADIUS
      vy = -vy
      next_pos = SFML::Vector2[next_pos.x, next_pos.y.clamp(RADIUS, height - RADIUS)]
    end

    @velocity      = SFML::Vector2[vx, vy]
    @ball.position = next_pos
  end

  def draw
    window.draw(@ball)
  end

  def on_event(event)
    case event
    in {type: :key_pressed, code: :space}
      @ball.position = [width / 2, height / 2]
    else # ignore
    end
  end
end

BouncingBall.new(
  width:      800,
  height:     600,
  title:      "SFML::Game — bouncing ball",
  background: SFML::Color["#1a1a1a"],
).run
