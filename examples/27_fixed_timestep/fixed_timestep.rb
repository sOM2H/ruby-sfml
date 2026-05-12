#!/usr/bin/env ruby
# frozen_string_literal: true

# Fixed-timestep physics with interpolated rendering — the standard
# pattern for deterministic game loops. With `fixed_timestep N`,
# `update(dt)` is called exactly N times per second (with a fixed
# dt), regardless of frame rate. The renderer reads
# `interpolation_alpha` to smoothly interpolate between the
# previous and current physics state.
#
# This is the foundation that makes physics behave identically
# whether you run at 60 FPS or 240 FPS — and lets multi-second
# slow frames not break the simulation.
#
# Demonstrates:
#   - `fixed_timestep 30` class macro on `SFML::App`
#   - Reading `interpolation_alpha` from `#draw` for smooth visuals
#     between coarse 30 Hz physics ticks
#   - The "prev_state" trick: store last-tick state in `update`,
#     interpolate against the current state in `draw`
#
# Watch the ball: physics runs at 30 Hz, but rendering at 60+
# FPS keeps the motion buttery-smooth thanks to interpolation.
# Tap [I] to toggle interpolation off and see the difference —
# you'll see the ball jump in 30 Hz steps.
#
# Esc to quit.
#
#     bundle exec ruby examples/27_fixed_timestep/fixed_timestep.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

class FixedTimestepDemo < SFML::App
  width  800
  height 600
  title  "Fixed timestep — 30 Hz physics, 60+ FPS render"
  background SFML::Color["#101216"]
  framerate  240   # render as fast as the display allows

  fixed_timestep 30   # physics ticks per second

  on_key :escape, :quit
  on_key :i,      :toggle_interpolation
  on_key :space,  :randomize_velocity

  RADIUS = 28

  def setup
    @prev_pos = @curr_pos = SFML::Vector2[width / 2, height / 2]
    @velocity = SFML::Vector2[420, 320]

    @ball = SFML::CircleShape.new(
      radius: RADIUS, origin: [RADIUS, RADIUS],
      fill_color: SFML::Color.cornflower_blue,
    )

    @interpolate = true
    @phys_ticks  = 0
    @render_frames = 0
    @ticker_clock  = SFML::Clock.new

    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 14,
                           fill_color: SFML::Color.white, position: [10, 10])
  end

  # Called exactly 30 times per second by SFML::App.
  def update(dt)
    seconds   = dt.as_seconds
    @prev_pos = @curr_pos
    @curr_pos = @curr_pos + @velocity * seconds

    # Bounce off the walls.
    vx, vy = @velocity.x, @velocity.y
    if @curr_pos.x < RADIUS || @curr_pos.x > width - RADIUS
      vx = -vx
      @curr_pos = SFML::Vector2[@curr_pos.x.clamp(RADIUS, width - RADIUS), @curr_pos.y]
    end
    if @curr_pos.y < RADIUS || @curr_pos.y > height - RADIUS
      vy = -vy
      @curr_pos = SFML::Vector2[@curr_pos.x, @curr_pos.y.clamp(RADIUS, height - RADIUS)]
    end
    @velocity = SFML::Vector2[vx, vy]

    @phys_ticks += 1
  end

  def draw
    # Smooth between the previous and current physics state. Without
    # this, the ball would visibly step at 30 Hz.
    @ball.position =
      if @interpolate
        @prev_pos.lerp(@curr_pos, interpolation_alpha)
      else
        @curr_pos
      end

    @render_frames += 1
    elapsed = @ticker_clock.elapsed.as_seconds
    if elapsed >= 0.5
      @last_phys_hz   = (@phys_ticks / elapsed).round
      @last_render_hz = (@render_frames / elapsed).round
      @phys_ticks = 0; @render_frames = 0
      @ticker_clock.restart
    end

    @hud.string =
      "fixed_timestep 30  •  interpolation_alpha: #{interpolation_alpha.round(3)}\n" \
      "physics: #{@last_phys_hz || "—"} Hz  •  render: #{@last_render_hz || "—"} FPS\n" \
      "interpolate: #{@interpolate ? "ON" : "OFF — watch the stutter"}  " \
      "[I] toggle  •  [Space] randomise velocity"

    window.draw(@ball)
    window.draw(@hud)
  end

  def toggle_interpolation
    @interpolate = !@interpolate
  end

  def randomize_velocity
    angle = rand * 2 * Math::PI
    speed = 300 + rand * 300
    @velocity = SFML::Vector2[Math.cos(angle), Math.sin(angle)] * speed
  end
end

FixedTimestepDemo.new.run
