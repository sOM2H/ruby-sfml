#!/usr/bin/env ruby
# frozen_string_literal: true

# SpriteSheet + Animation — the bread-and-butter pair for any 2D
# game with character animation. Here we **procedurally generate**
# an 8-frame walk cycle (a coloured square that pulses + shifts
# hue) so the example has no external dependencies. In your own
# code you'd hand `SpriteSheet.load("hero.png", frame_size: 32)`
# a real spritesheet — and reach for `SFML::TextureAtlas.load
# ("hero.json")` for Aseprite/TexturePacker exports.
#
# Demonstrates:
#   - Procedurally building an image, then `Texture.from_image`
#   - `SFML::SpriteSheet.new(texture:, frame_size:)` — grid slice
#   - `SFML::Animation#update(dt)` driving `texture_rect`
#   - Sprite-style transform passthrough on Animation
#     (anim.position = ..., anim.scale = ...)
#
# Esc to quit.
#
#     bundle exec ruby examples/12_sprite_animation/sprite_animation.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

CELL  = 32
FRAMES = 8

# Build a CPU image with FRAMES cells laid out horizontally.
def build_sheet_image
  img = SFML::Image.new(CELL * FRAMES, CELL, fill: SFML::Color.transparent)
  FRAMES.times do |f|
    t      = f / FRAMES.to_f
    base_r = (Math.sin(t * 2 * Math::PI) * 100 + 155).to_i.clamp(0, 255)
    base_g = (Math.sin(t * 2 * Math::PI + 2) * 100 + 155).to_i.clamp(0, 255)
    base_b = (Math.sin(t * 2 * Math::PI + 4) * 100 + 155).to_i.clamp(0, 255)
    color  = SFML::Color.new(base_r, base_g, base_b)

    # Filled square + a "leg" pulse below for the walk-cycle vibe.
    cx, cy = f * CELL + CELL / 2, CELL / 2
    radius = 10 + (Math.sin(t * 2 * Math::PI) * 3).round
    (-radius..radius).each do |dy|
      (-radius..radius).each do |dx|
        next if dx**2 + dy**2 > radius**2
        x = cx + dx; y = cy + dy
        img[x, y] = color if x >= 0 && y >= 0 && x < CELL * FRAMES && y < CELL
      end
    end

    # Foot — alternates left/right per frame.
    foot_x = cx + (f.even? ? -5 : 5)
    foot_y = cy + 10
    (-2..2).each do |dy|
      (-2..2).each do |dx|
        x = foot_x + dx; y = foot_y + dy
        img[x, y] = SFML::Color.new(30, 30, 30) if x >= 0 && y >= 0 && x < CELL * FRAMES && y < CELL
      end
    end
  end
  img
end

class AnimationDemo < SFML::App
  width  640
  height 360
  title  "SpriteSheet + Animation"
  background SFML::Color["#1f2229"]

  on_key :escape, :quit
  on_key :space, :toggle_pause_anim

  def setup
    sheet_img      = build_sheet_image
    texture        = SFML::Texture.from_image(sheet_img)
    @sheet         = SFML::SpriteSheet.new(texture: texture, frame_size: CELL)
    @walk          = @sheet.animation(fps: 10, loop: true)
    @walk.scale    = [4, 4]
    @walk.position = [width / 2 - CELL * 2, height / 2 - CELL * 2]
    @anim_paused   = false

    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 14,
                           fill_color: SFML::Color.white, position: [10, 10])
  end

  def update(dt)
    @walk.update(dt) unless @anim_paused
    @hud.string =
      "8-frame walk cycle (procedural).  Space to pause/resume animation.\n" \
      "frame: #{@walk.frame_index + 1}/#{@sheet.frame_count}  •  fps: 10  •  " \
      "Animation#duration = #{@walk.duration}s"
  end

  def draw
    window.draw(@walk)
    window.draw(@hud)
  end

  def toggle_pause_anim
    @anim_paused = !@anim_paused
  end
end

AnimationDemo.new.run
