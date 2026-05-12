#!/usr/bin/env ruby
# frozen_string_literal: true

# Custom drawable polygon via `SFML::Shape` — the callback-driven
# abstract base class. Subclass it, override `#point_count` and
# `#point(i)` to return polygon vertices, and CSFML samples them
# each time the geometry is rebuilt.
#
# Use this when none of the built-in shapes (Circle / Rectangle /
# Convex) fits — typically because:
#   - The point set isn't convex (Convex doesn't handle that).
#   - The shape's vertices change over time as a function of
#     simulation state, and you want CSFML to re-sample on demand.
#
# Here we ship three parametric shapes (star, heart, gear); the
# Heart subclass animates its scale field which feeds `#point(i)`,
# and we call `#update` to invalidate the cached outline.
#
# Demonstrates:
#   - Subclassing `SFML::Shape` with #point_count + #point(i)
#   - `#update` to re-sample the callbacks after parameters change
#   - Shared transform / fill / outline / texture surface (via
#     the `Graphics::Transformable` + `ShapeInspectable` mixins)
#
# Keys: 1 / 2 / 3 — star / heart / gear. Esc to quit.
#
#     bundle exec ruby examples/09_custom_shape/custom_shape.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

class Star < SFML::Shape
  def initialize(points: 5, outer: 100, inner: 40, **opts)
    @points, @outer, @inner = points, outer, inner
    super(**opts)
    update   # CSFML samples #point(i) on first draw; #update primes it now
  end

  def point_count = @points * 2

  def point(i)
    angle = (i.to_f / point_count) * 2 * Math::PI - Math::PI / 2
    r     = i.even? ? @outer : @inner
    [Math.cos(angle) * r, Math.sin(angle) * r]
  end
end

class Heart < SFML::Shape
  attr_accessor :scale_factor

  def initialize(scale_factor: 1.0, **opts)
    @scale_factor = scale_factor
    super(**opts)
    update
  end

  def point_count = 64

  # Classic parametric heart:
  #   x = 16 sin³(t)
  #   y = -(13 cos(t) - 5 cos(2t) - 2 cos(3t) - cos(4t))
  def point(i)
    t = (i / point_count.to_f) * 2 * Math::PI
    x = 16 * Math.sin(t) ** 3
    y = -(13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t))
    [x * @scale_factor, y * @scale_factor]
  end
end

class Gear < SFML::Shape
  def initialize(teeth: 12, root_r: 70, tip_r: 95, **opts)
    @teeth, @root_r, @tip_r = teeth, root_r, tip_r
    super(**opts)
    update
  end

  # 4 points per tooth: root-up, tip-up, tip-down, root-down.
  def point_count = @teeth * 4

  def point(i)
    tooth   = i / 4
    sub     = i % 4
    base_a  = (tooth.to_f / @teeth) * 2 * Math::PI
    tooth_a = (1.0 / @teeth) * 2 * Math::PI
    a = base_a + tooth_a * [0.0, 0.15, 0.35, 0.5][sub]
    r = [@root_r, @tip_r, @tip_r, @root_r][sub]
    [Math.cos(a) * r, Math.sin(a) * r]
  end
end

class CustomShapeDemo < SFML::App
  width  720
  height 480
  title  "Custom SFML::Shape — star / heart / gear"
  background SFML::Color["#0c1014"]
  antialiasing 8

  on_key :escape, :quit
  on_key :one,    -> (a) { a.mode = :star  }
  on_key :two,    -> (a) { a.mode = :heart }
  on_key :three,  -> (a) { a.mode = :gear  }

  attr_accessor :mode

  def setup
    @shapes = {
      star:  Star.new(points: 7, outer: 100, inner: 38,
                      fill_color: SFML::Color.new(255, 200, 60),
                      outline_color: SFML::Color.white,
                      outline_thickness: 2,
                      position: [width / 2, height / 2]),
      heart: Heart.new(scale_factor: 7,
                       fill_color: SFML::Color.new(220, 50, 80),
                       outline_color: SFML::Color.white,
                       outline_thickness: 2,
                       position: [width / 2, height / 2]),
      gear:  Gear.new(teeth: 14,
                      fill_color: SFML::Color.new(150, 170, 220),
                      outline_color: SFML::Color.white,
                      outline_thickness: 2,
                      position: [width / 2, height / 2]),
    }
    @mode = :star
    @t    = 0.0

    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 14,
                           fill_color: SFML::Color.white, position: [10, 10])
  end

  def update(dt)
    @t += dt.as_seconds
    shape = @shapes[@mode]

    case @mode
    when :star
      shape.rotation = @t * 30
    when :heart
      # Pulse the scale field on the Heart subclass — then call
      # #update so CSFML re-samples #point(i) on the next draw.
      shape.scale_factor = 7 + Math.sin(@t * 3) * 1.2
      shape.update
    when :gear
      shape.rotation = -@t * 60
    end

    @hud.string =
      "[1] star  [2] heart  [3] gear  •  current: #{@mode}\n" \
      "point_count: #{shape.point_count}  •  local_bounds: " \
      "#{shape.local_bounds.width.round(1)}×#{shape.local_bounds.height.round(1)}\n" \
      "geometric_center: #{shape.geometric_center.inspect}"
  end

  def draw
    window.draw(@shapes[@mode])
    window.draw(@hud)
  end
end

CustomShapeDemo.new.run
