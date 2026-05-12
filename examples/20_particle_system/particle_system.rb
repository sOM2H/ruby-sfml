#!/usr/bin/env ruby
# frozen_string_literal: true

# Particle fountain using `SFML::ParticleSystem` — the class added
# in 3.0.0.6 that wraps a VertexArray-backed pool. Compare with
# `examples/21_particles/particles.rb`, which builds the same
# effect by hand on top of VertexArray — same idea, ~100 fewer
# lines.
#
# Demonstrates:
#   - Subclassing `SFML::ParticleSystem` and overriding
#     `#update_particle` to layer custom behaviour (here: hue
#     shift over a particle's life)
#   - `gravity:` on the constructor — no per-frame integration
#     code needed
#   - LMB to redirect the fountain to the cursor
#
# Esc to quit.
#
#     bundle exec ruby examples/20_particle_system/particle_system.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

class Sparks < SFML::ParticleSystem
  # Hue-shift each particle's stored colour over time. The base
  # ParticleSystem already fades alpha to zero; this hook adds
  # a warm-to-cool colour ramp on top.
  def update_particle(p, _dt)
    t  = p.normalized_age
    p.r = (255 * (1.0 - t * 0.5)).clamp(0, 255).to_i
    p.g = (180 - 120 * t).clamp(0, 255).to_i
    p.b = (40  + 200 * t).clamp(0, 255).to_i
  end
end

class ParticlesDemo < SFML::App
  width  800
  height 600
  title  "ParticleSystem — fountain"
  background SFML::Color["#0a0d12"]

  on_key :escape, :quit
  on_key :c,      :clear_particles

  SPAWN_RATE = 600  # particles per second

  def setup
    @particles = Sparks.new(max: 4000, gravity: [0, 540])

    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 14,
                           fill_color: SFML::Color.white, position: [10, 10])
  end

  def update(dt)
    seconds = dt.as_seconds

    # Emit position: cursor while LMB held, otherwise a fixed nozzle.
    origin =
      if SFML::Mouse.button_pressed?(:left)
        m = SFML::Mouse.position(window)
        SFML::Vector2[m.x, m.y]
      else
        SFML::Vector2[width / 2, 80]
      end

    # Emit count for this frame, accumulated to avoid integer-rate
    # quantisation at low dt.
    @spawn_acc ||= 0.0
    @spawn_acc += SPAWN_RATE * seconds
    while @spawn_acc >= 1.0
      angle = (rand * 2.0 - 1.0) * 0.6 - Math::PI / 2   # ~upward ±35°
      speed = 240 + rand * 240
      @particles.spawn(
        position: origin,
        velocity: SFML::Vector2[Math.cos(angle), Math.sin(angle)] * speed,
        lifetime: 1.5 + rand * 2.0,
        color:    SFML::Color.new(255, 180, 40),
        size:     2,
      )
      @spawn_acc -= 1.0
    end

    @particles.update(dt)

    @hud.string =
      "Hold LMB to redirect the fountain  •  C to clear  •  Esc to quit\n" \
      "live: #{@particles.size}/#{@particles.instance_variable_get(:@max)}  •  gravity: 540 px/s²"
  end

  def draw
    window.draw(@particles)
    window.draw(@hud)
  end

  def clear_particles
    @particles.clear
  end
end

ParticlesDemo.new.run
