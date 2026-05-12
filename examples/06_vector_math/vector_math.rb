#!/usr/bin/env ruby
# frozen_string_literal: true

# Tour of SFML::Vector2 math helpers added in 3.0.0.6. A "seeker"
# orbits, lerps toward, or steers around the mouse cursor depending
# on which mode you pick. Tap [1]/[2]/[3] to swap behaviours.
#
# Demonstrates:
#   - `Vector2#distance`, `#angle_to`, `#rotated`, `#lerp`,
#     `#normalize`, `#clamp_length` used in a real movement loop
#   - Float-axis steering math without resorting to manual trig
#
# Esc to quit.
#
#     bundle exec ruby examples/06_vector_math/vector_math.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

class VectorMath < SFML::App
  width  800
  height 600
  title  "Vector math — 1/2/3 swap modes"
  background SFML::Color["#0d1117"]
  antialiasing 4

  on_key :escape, :quit
  on_key :one,    -> (a) { a.mode = :orbit  }
  on_key :two,    -> (a) { a.mode = :lerp   }
  on_key :three,  -> (a) { a.mode = :steer  }

  MODES = {
    orbit: "orbit:  rotate around the cursor at fixed radius",
    lerp:  "lerp:   ease toward the cursor (10%/frame)",
    steer: "steer:  accelerate toward cursor, capped speed",
  }.freeze

  attr_accessor :mode

  def setup
    @seeker = SFML::CircleShape.new(
      radius: 18, origin: [18, 18],
      position: [width / 2, height / 2],
      fill_color: SFML::Color.new(255, 180, 40),
    )
    @velocity = SFML::Vector2.zero
    @mode = :orbit
    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 14,
                           fill_color: SFML::Color.white, position: [10, 10])

    # A trail of fading dots to make the math visible.
    @trail = []
  end

  def update(dt)
    seconds = dt.as_seconds
    cursor  = SFML::Vector2.from_native(SFML::C::System::Vector2f.new.tap do |v|
      m = SFML::Mouse.position(window)
      v[:x] = m.x.to_f; v[:y] = m.y.to_f
    end)
    pos = @seeker.position

    case @mode
    when :orbit
      # angle_to + rotated: orbit at a fixed radius, 90° tangential
      # to the cursor direction.
      radius = pos.distance(cursor).clamp(40, 220)
      angle  = cursor.angle_to(pos) + seconds * 1.5   # 1.5 rad/s spin
      dir    = SFML::Vector2[Math.cos(angle), Math.sin(angle)]
      @seeker.position = cursor + dir * radius

    when :lerp
      # Constant-fraction ease — frame-rate sensitive but cheap.
      @seeker.position = pos.lerp(cursor, 0.1)

    when :steer
      # Accelerate toward target; clamp_length caps top speed.
      to_target = cursor - pos
      desired   = to_target.normalize * 400.0
      @velocity = (@velocity + (desired - @velocity) * 4.0 * seconds).clamp_length(400)
      @seeker.position = pos + @velocity * seconds
    end

    @trail.unshift(@seeker.position)
    @trail.pop while @trail.size > 60

    @hud.string = "[1] orbit  [2] lerp  [3] steer  |  current: #{MODES[@mode]}\n" \
                  "dist to cursor: #{pos.distance(cursor).round(1)}px"
  end

  def draw
    @trail.each_with_index do |p, i|
      alpha = (255 * (1.0 - i / @trail.size.to_f)).to_i
      dot = SFML::CircleShape.new(
        radius: 3, origin: [3, 3], position: [p.x, p.y],
        fill_color: SFML::Color.new(120, 180, 255, alpha),
      )
      window.draw(dot)
    end
    window.draw(@seeker)
    window.draw(@hud)
  end
end

VectorMath.new.run
