#!/usr/bin/env ruby
# frozen_string_literal: true

# A tilemap rendered as a single textured VertexArray, plus an additive-
# blended "torch" that follows the cursor. Two things this example
# unlocks that weren't possible before SFML::RenderStates:
#
#   1. SFML::VertexArray + a texture: pass `texture:` to window.draw and
#      every vertex's tex_coords now samples the supplied bitmap. One
#      draw call paints the whole map.
#   2. blend_mode:: SFML::BlendMode::ADD makes the torch *add* light to
#      pixels under it instead of overpainting them — proper glow.
#
# The 4-tile tileset (grass / dirt / stone / water) is generated
# procedurally on first run; nothing is bundled.
#
# Esc to quit.
#
#     bundle exec ruby examples/19_tilemap/tilemap.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 800, 600
TILE      = 40
MAP_W     = WINDOW_W / TILE
MAP_H     = WINDOW_H / TILE
TILE_PX   = 32  # size of one tile inside the tileset image

# ---- Procedural tileset --------------------------------------------------
# 4 tiles laid out horizontally in a 128×32 image. Each tile gets a base
# colour plus deterministic per-pixel noise so the surface looks textured.

PALETTE = [
  SFML::Color.new(46,  90,  35),   # 0 grass
  SFML::Color.new(110, 70,  40),   # 1 dirt
  SFML::Color.new(80,  85,  95),   # 2 stone
  SFML::Color.new(30,  80,  140),  # 3 water
].freeze

def build_tileset_image
  img = SFML::Image.new(TILE_PX * PALETTE.length, TILE_PX)
  PALETTE.each_with_index do |base, idx|
    TILE_PX.times do |y|
      TILE_PX.times do |x|
        # Stable hash → 0..255, used to perturb each channel by ±15.
        n = (x * 73 + y * 41 + idx * 17) & 31
        shade = (n - 16)   # -16..15
        c = SFML::Color.new(
          (base.r + shade).clamp(0, 255),
          (base.g + shade).clamp(0, 255),
          (base.b + shade).clamp(0, 255),
        )
        img[idx * TILE_PX + x, y] = c
      end
    end
  end
  img
end

# ---- Map generation ------------------------------------------------------

def generate_map
  Array.new(MAP_H) do |gy|
    Array.new(MAP_W) do |gx|
      cx = MAP_W / 2.0
      cy = MAP_H / 2.0
      d  = Math.sqrt((gx - cx)**2 + (gy - cy)**2)

      if    d > [MAP_W, MAP_H].min / 2.2 then 3   # water around the rim
      elsif d > [MAP_W, MAP_H].min / 3.0 then 0   # grass ring
      elsif d > [MAP_W, MAP_H].min / 6.0 then 1   # dirt
      else                                    2   # stone in the middle
      end
    end
  end
end

# ---- VertexArray construction --------------------------------------------
# Two triangles per tile, six vertices total. Tex-coords address the
# tileset in pixels — we set coordinate_type: :pixels in the draw call
# so SFML uses raw integer offsets instead of normalised UVs.

def build_tilemap_vertex_array(map)
  va = SFML::VertexArray.new(:triangles)
  va.resize(MAP_H * MAP_W * 6)

  i = 0
  map.each_with_index do |row, gy|
    row.each_with_index do |tile, gx|
      x0 = gx * TILE
      x1 = x0 + TILE
      y0 = gy * TILE
      y1 = y0 + TILE

      tx0 = tile * TILE_PX
      tx1 = tx0 + TILE_PX
      ty0 = 0
      ty1 = TILE_PX

      # tri 1: TL, TR, BR
      va[i + 0] = SFML::Vertex.new([x0, y0], tex_coords: [tx0, ty0])
      va[i + 1] = SFML::Vertex.new([x1, y0], tex_coords: [tx1, ty0])
      va[i + 2] = SFML::Vertex.new([x1, y1], tex_coords: [tx1, ty1])
      # tri 2: TL, BR, BL
      va[i + 3] = SFML::Vertex.new([x0, y0], tex_coords: [tx0, ty0])
      va[i + 4] = SFML::Vertex.new([x1, y1], tex_coords: [tx1, ty1])
      va[i + 5] = SFML::Vertex.new([x0, y1], tex_coords: [tx0, ty1])
      i += 6
    end
  end
  va
end

# ---- Setup ----------------------------------------------------------------

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Tilemap", framerate: 60)

tileset_image   = build_tileset_image
tileset_texture = SFML::Texture.from_image(tileset_image)

map = generate_map
va  = build_tilemap_vertex_array(map)

# Torch — drawn with additive blending, follows the mouse.
torch = SFML::CircleShape.new(
  radius:     120,
  origin:     [120, 120],
  fill_color: SFML::Color.new(255, 220, 120, 90),
)

font = SFML::Font.default
hud  = SFML::Text.new(font, "", character_size: 14, fill_color: SFML::Color.white,
                      position: [10, 10])

# ---- Main loop ------------------------------------------------------------

clock     = SFML::Clock.new
fps_count = 0
fps_secs  = 0.0
fps       = 0

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

  pos = SFML::Mouse.position(window)
  torch.position = [pos.x, pos.y]

  hud.string = "fps: #{fps}  •  tiles: #{MAP_W}×#{MAP_H} (#{MAP_W * MAP_H * 6} vertices)\n" \
               "VertexArray + texture in one draw call  •  torch uses BlendMode::ADD"

  window.clear(SFML::Color.black)

  # World pass: textured VertexArray. coordinate_type: :pixels makes
  # the tex_coords above mean "pixel offsets in the tileset" rather
  # than the normalised [0..1] UV space.
  window.draw(va, texture: tileset_texture, coordinate_type: :pixels)

  # Glow pass: bright torch added to whatever's underneath.
  window.draw(torch, blend_mode: SFML::BlendMode::ADD)

  window.draw(hud)
  window.display
end
