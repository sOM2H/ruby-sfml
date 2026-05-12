#!/usr/bin/env ruby
# frozen_string_literal: true

# Real `TextureAtlas` workflow — load a JSON descriptor (the same
# shape Aseprite / TexturePacker export) plus its sheet image, then
# switch between named animations.
#
# Most game projects bake their character art with Aseprite or
# TexturePacker. Both export a JSON file like:
#
#   {
#     "frames": {
#       "idle-0.png": { "frame": {"x": 0, "y": 0, "w": 32, "h": 32}, "duration": 120 },
#       "idle-1.png": { ... },
#       "walk-0.png": { ... },
#       ...
#     },
#     "meta": { "image": "hero.png", "size": {"w": 256, "h": 32}, ... }
#   }
#
# `SFML::TextureAtlas.load("hero.json")` parses that, resolves the
# image, and gives you `region(name)` / `sprite(name)` /
# `animation(names, fps:)`. When per-frame `duration` is present
# (Aseprite always emits it), `animation` auto-derives fps so your
# code doesn't have to mirror the artist's timings.
#
# For this example we **synthesise** the atlas at runtime (so the
# example needs no checked-in PNG): three "animations" (idle / walk
# / blink) all on one 12-cell strip.
#
# Demonstrates:
#   - `SFML::TextureAtlas.load(json_path)`
#   - `#region(name)` / `#sprite(name)` / `#animation(names, fps:)`
#   - Multiple named animations from a single atlas + duration-aware fps
#
# Keys: 1 / 2 / 3 — switch idle / walk / blink. Esc to quit.
#
#     bundle exec ruby examples/13_texture_atlas/texture_atlas.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"
require "json"
require "tmpdir"

CELL_W = 32
CELL_H = 32

# Three animations laid out left-to-right: idle (4) + walk (6) + blink (2).
ANIMATIONS = {
  "idle"  => 4,
  "walk"  => 6,
  "blink" => 2,
}.freeze

# Build the spritesheet image + JSON descriptor in a tmpdir.
def build_atlas
  total_cells = ANIMATIONS.values.sum                              # 12
  img = SFML::Image.new(CELL_W * total_cells, CELL_H, fill: SFML::Color.transparent)

  frames_json = {}
  x_cell = 0
  ANIMATIONS.each do |name, count|
    count.times do |i|
      cx = x_cell * CELL_W + CELL_W / 2
      cy = CELL_H / 2

      # Visually distinct hue per animation, gentle pulse over its frames.
      base_hue = case name
                 when "idle"  then 200   # cool blue
                 when "walk"  then 30    # warm orange
                 when "blink" then 320   # magenta
                 end
      t  = i / count.to_f
      r  = (Math.sin((base_hue + t * 90) * Math::PI / 180) * 100 + 155).to_i.clamp(0, 255)
      g  = (Math.sin((base_hue + t * 90 + 120) * Math::PI / 180) * 100 + 155).to_i.clamp(0, 255)
      b  = (Math.sin((base_hue + t * 90 + 240) * Math::PI / 180) * 100 + 155).to_i.clamp(0, 255)
      color = SFML::Color.new(r, g, b)

      # Body — filled circle, radius pulses with the animation.
      radius = 11 + (Math.sin(t * 2 * Math::PI) * 2).round
      (-radius..radius).each do |dy|
        (-radius..radius).each do |dx|
          next if dx**2 + dy**2 > radius**2
          x, y = cx + dx, cy + dy
          img[x, y] = color if x >= 0 && y >= 0 && x < img.width && y < img.height
        end
      end

      # Eye-blink for the "blink" cycle.
      if name == "blink" && i == 1
        (-2..2).each do |dx|
          x, y = cx + dx, cy - 3
          img[x, y] = SFML::Color.black
        end
      end

      frames_json["#{name}-#{i}.png"] = {
        "frame"    => { "x" => x_cell * CELL_W, "y" => 0, "w" => CELL_W, "h" => CELL_H },
        "duration" => (name == "walk" ? 90 : 160),
      }
      x_cell += 1
    end
  end

  dir       = Dir.mktmpdir("ruby-sfml-atlas-")
  png_path  = File.join(dir, "hero.png")
  json_path = File.join(dir, "hero.json")
  img.save(png_path)
  File.write(json_path, JSON.pretty_generate({
    "frames" => frames_json,
    "meta"   => { "image" => "hero.png", "size" => { "w" => img.width, "h" => img.height } },
  }))
  json_path
end

class AtlasDemo < SFML::App
  width  640
  height 360
  title  "TextureAtlas — idle / walk / blink"
  background SFML::Color["#1f2229"]

  on_key :escape, :quit
  on_key :one,    -> (a) { a.switch("idle")  }
  on_key :two,    -> (a) { a.switch("walk")  }
  on_key :three,  -> (a) { a.switch("blink") }

  def setup
    json_path = build_atlas
    @atlas = SFML::TextureAtlas.load(json_path)

    @animations = {}
    ANIMATIONS.each do |name, count|
      frame_names = count.times.map { |i| "#{name}-#{i}" }
      anim = @atlas.animation(frame_names, loop: true)  # fps auto from durations
      anim.scale = [5, 5]
      anim.position = [width / 2 - CELL_W * 2.5, height / 2 - CELL_H * 2.5]
      @animations[name] = anim
    end

    @current = "idle"

    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 14,
                           fill_color: SFML::Color.white, position: [10, 10])
  end

  def update(dt)
    @animations[@current].update(dt)
    @hud.string =
      "[1] idle  [2] walk  [3] blink  •  current: #{@current}\n" \
      "atlas source: #{File.basename(@atlas.source)}  " \
      "(#{@atlas.frame_names.size} frames total)\n" \
      "frame #{@animations[@current].frame_index + 1} / #{@animations[@current].instance_variable_get(:@frames).size}"
  end

  def draw
    window.draw(@animations[@current])
    window.draw(@hud)
  end

  def switch(name)
    return unless @animations.key?(name)
    @animations[name].reset
    @current = name
  end
end

AtlasDemo.new.run
