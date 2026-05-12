#!/usr/bin/env ruby
# frozen_string_literal: true

# Particle fountain — thousands of points simulated and rendered in a
# single draw call via SFML::VertexArray. The "ground" is a SFML::ConvexShape
# (a custom polygon, not a rectangle) just to show off both APIs in one demo.
#
# Demonstrates:
#   - VertexArray with :points primitive — one vertex per particle
#   - Mutating vertex storage in place (va[i] = ...) every frame instead
#     of clearing + re-appending, which matters at this particle count
#   - ConvexShape for the irregular ground silhouette
#   - Holding LMB sprays from the cursor; otherwise particles fall from a
#     fixed nozzle near the top of the window
#
# Esc to quit.
#
#     bundle exec ruby examples/21_particles/particles.rb
$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 800, 600
PARTICLE_COUNT     = 4000
GRAVITY            = 540.0   # px/s²
LIFE_MIN           = 1.5
LIFE_MAX           = 3.5

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Particles", framerate: 300)

# Ground: an irregular skyline-ish silhouette built from points.
ground_pts = (0..16).map do |i|
  x = WINDOW_W * i / 16.0
  y = WINDOW_H - 40 - (Math.sin(i * 0.7) * 25 + (i.even? ? 0 : 12))
  [x, y]
end
ground_pts += [[WINDOW_W, WINDOW_H], [0, WINDOW_H]]

ground = SFML::ConvexShape.new(
  points:        ground_pts,
  fill_color:    SFML::Color["#1a2b1a"],
  outline_color: SFML::Color["#3a5a3a"],
  outline_thickness: 2,
)

# One vertex per live particle; the parallel `particles` Array stores the
# Ruby-side simulation state. We pre-allocate both so the hot path never
# allocates.
particles = Array.new(PARTICLE_COUNT) { { life: 0.0 } }
va        = SFML::VertexArray.new(:points)
va.resize(PARTICLE_COUNT)

# All-zero alpha = invisible; until a particle is alive we keep its
# vertex parked off-screen.
PARKED = SFML::Vertex.new([-1, -1], color: SFML::Color.transparent)
PARTICLE_COUNT.times { |i| va[i] = PARKED }

font = SFML::Font.default
hud  = SFML::Text.new(font, "", character_size: 14,
                      fill_color: SFML::Color.white, position: [10, 10])

# Spawn cursor for stdout-free feedback when no LMB.
spawn_default = SFML::Vector2[WINDOW_W / 2, 80]

clock     = SFML::Clock.new
fps_count = 0
fps_secs  = 0.0
fps       = 0
spawn_idx = 0

def random_velocity
  angle = (rand * 2.0 - 1.0) * 0.6 - Math::PI / 2  # mostly upward, ±~35°
  speed = 240 + rand * 240
  SFML::Vector2[Math.cos(angle) * speed, Math.sin(angle) * speed]
end

def spawn(particle, origin)
  particle[:pos]    = SFML::Vector2[origin.x, origin.y]
  particle[:vel]    = random_velocity
  particle[:life]   = LIFE_MIN + rand * (LIFE_MAX - LIFE_MIN)
  particle[:max]    = particle[:life]
  particle[:hue]    = rand * 360
end

while window.open?
  dt = clock.restart.as_seconds

  fps_count += 1
  fps_secs  += dt
  if fps_secs >= 0.25
    fps       = (fps_count / fps_secs).round
    fps_count = 0
    fps_secs  = 0.0
  end

  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else
    end
  end

  # Spawn point: cursor while LMB held, otherwise a fixed nozzle.
  origin = SFML::Mouse.button_pressed?(:left) ? SFML::Mouse.position(window) : spawn_default

  # Spawn a few new particles per frame (round-robin reusing slots whose
  # life expired so we never grow beyond PARTICLE_COUNT).
  spawned_this_frame = 0
  spawn_quota        = (240 * dt).ceil
  while spawned_this_frame < spawn_quota
    if particles[spawn_idx][:life] <= 0.0
      spawn(particles[spawn_idx], origin)
      spawned_this_frame += 1
    end
    spawn_idx = (spawn_idx + 1) % PARTICLE_COUNT
    spawned_this_frame += 1 if spawned_this_frame.zero? && spawn_idx == 0
    break if spawned_this_frame >= spawn_quota
  end

  alive = 0
  particles.each_with_index do |p, i|
    if p[:life] > 0.0
      p[:vel] += SFML::Vector2[0, GRAVITY] * dt
      p[:pos] += p[:vel] * dt
      p[:life] -= dt

      if p[:life] <= 0.0 || p[:pos].y > WINDOW_H + 10
        p[:life] = 0.0
        va[i] = PARKED
      else
        # Colour: warm-to-cool sweep over the particle's life.
        t       = 1.0 - (p[:life] / p[:max])  # 0..1
        r       = (255 * (1.0 - t * 0.5)).clamp(0, 255).to_i
        g       = (180 - 120 * t).clamp(0, 255).to_i
        b       = (40 + 200 * t).clamp(0, 255).to_i
        a       = (255 * (p[:life] / p[:max])).clamp(0, 255).to_i
        va[i]   = SFML::Vertex.new([p[:pos].x, p[:pos].y],
                                   color: SFML::Color.new(r, g, b, a))
        alive += 1
      end
    end
  end

  hud.string = "fps: #{fps}  •  alive: #{alive}/#{PARTICLE_COUNT}\n" \
               "Hold LMB anywhere to redirect the fountain  •  Esc quits"

  window.clear(SFML::Color["#0a0d12"])
  window.draw(va)         # one draw call for all #{alive} particles
  window.draw(ground)
  window.draw(hud)
  window.display
end
