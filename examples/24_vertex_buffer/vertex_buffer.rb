#!/usr/bin/env ruby
# frozen_string_literal: true

# GPU-resident vertex buffer (VBO). A `VertexArray` ships its
# vertices to the GPU every frame; `SFML::VertexBuffer` uploads
# them **once** at construction and just hands the GPU a handle
# on each draw. For static geometry — tilemaps, baked particles,
# 2D mesh decorations — this is a clean win.
#
# Here we generate **120 000 vertices** (3000 each across 40 Lissajous
# curves) once, store them in a single `VertexBuffer`, and animate
# the **camera (View)** instead of the geometry: the buffer never
# re-uploads, so per-frame CPU work is essentially zero regardless
# of vertex count.
#
# Compare with `examples/21_particles/particles.rb` and
# `examples/19_tilemap/tilemap.rb`, which both rebuild a
# `VertexArray` every frame because their geometry changes.
#
# Demonstrates:
#   - `SFML::VertexBuffer.new(vertices, primitive_type:, usage:)`
#   - `VertexBuffer.available?` (some GPUs / drivers say no)
#   - Animating via `View` rotation/zoom — the VBO data never moves
#
# Esc to quit.  +/- zooms,  R toggles rotation.
#
#     bundle exec ruby examples/24_vertex_buffer/vertex_buffer.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

unless SFML::VertexBuffer.available?
  abort "this GPU/driver doesn't expose OpenGL VBOs — fall back to VertexArray"
end

WINDOW_W    = 800
WINDOW_H    = 800
POINTS_PER  = 3000
N_CURVES    = 40
TOTAL       = POINTS_PER * N_CURVES

# Build 40 concentric Lissajous curves once.
def build_vertices
  vertices = Array.new(TOTAL)
  N_CURVES.times do |c|
    radius_scale = (c + 1) / N_CURVES.to_f          # 0..1
    a            = 3 + (c % 4)
    b            = 4 + ((c + 1) % 5)
    delta        = (c.to_f / N_CURVES) * Math::PI
    hue_off      = c.to_f / N_CURVES

    POINTS_PER.times do |i|
      t  = i / POINTS_PER.to_f * 2 * Math::PI
      x  = Math.sin(a * t + delta) * radius_scale * 360
      y  = Math.sin(b * t)         * radius_scale * 360
      h  = (i.to_f / POINTS_PER + hue_off) * 2 * Math::PI
      r  = (255 * (0.5 + 0.5 * Math.sin(h))).to_i
      g  = (255 * (0.5 + 0.5 * Math.sin(h + 2))).to_i
      bl = (255 * (0.5 + 0.5 * Math.sin(h + 4))).to_i
      vertices[c * POINTS_PER + i] =
        SFML::Vertex.new([x, y], color: SFML::Color.new(r, g, bl, 160))
    end
  end
  vertices
end

window = SFML::RenderWindow.new(
  WINDOW_W, WINDOW_H, "VertexBuffer — 120k vertices, 1 draw call",
  framerate: 240, antialiasing: 8,
)

# `usage: :static` tells the GPU we won't be re-uploading. Use
# `:stream` for per-frame re-uploads, `:dynamic` for occasional.
print "Building #{TOTAL} vertices ... "
buffer = SFML::VertexBuffer.new(
  build_vertices, primitive_type: :line_strip, usage: :static,
)
puts "uploaded to GPU."

# A View centred at the origin (where our vertices live).
view = SFML::View.new(center: [0, 0], size: [WINDOW_W, WINDOW_H])

font     = SFML::Font.default
hud      = SFML::Text.new(font, "", character_size: 14,
                          fill_color: SFML::Color.white, position: [10, 10])
clock    = SFML::Clock.new
last_fps = 0
fps_buf  = []
zoom     = 1.0
rotating = true
angle    = 0.0

while window.open?
  dt = clock.restart.as_seconds

  fps_buf << dt
  fps_buf.shift while fps_buf.size > 60
  last_fps = (fps_buf.size / fps_buf.sum).round if fps_buf.sum > 0

  window.each_event do |event|
    case event
    in {type: :closed}                       then window.close
    in {type: :key_pressed, code: :escape}   then window.close
    in {type: :key_pressed, code: :r}        then rotating = !rotating
    in {type: :key_pressed, code: :equal}    then zoom *= 0.9   # `=` key (often `+`)
    in {type: :key_pressed, code: :hyphen}   then zoom *= 1.1
    else
    end
  end

  if rotating
    angle = (angle + 20 * dt) % 360
  end

  view.rotation = angle
  view.size     = SFML::Vector2[WINDOW_W * zoom, WINDOW_H * zoom]
  window.view   = view

  hud.string =
    "VBO: #{TOTAL} vertices, drawn in one call  •  fps: #{last_fps}\n" \
    "rotation: #{rotating ? "on" : "off"} (R toggles)  •  zoom: #{(1.0 / zoom).round(2)}x ([-]/[=])\n" \
    "GPU re-uploads per frame: 0  (the buffer is static-usage)"

  window.clear(SFML::Color["#080a10"])
  window.draw(buffer)
  # HUD lives in default-view space, not zoomed.
  window.view = window.default_view
  window.draw(hud)
  window.display
end
