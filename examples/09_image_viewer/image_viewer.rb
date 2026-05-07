#!/usr/bin/env ruby
# frozen_string_literal: true

# Loads a PNG and displays it as an animated sprite. The canonical
# "load and draw" flow:
#   SFML::Texture.load(path)      → GPU copy for rendering
#   SFML::Image.load(path)        → CPU copy for live mutation
#   SFML::Sprite.new(texture)     → drawable with origin/scale/rotation
#
# Controls:
#   H / V    flip the image horizontally / vertically and re-upload to GPU
#   Esc      quit
#
#     bundle exec ruby examples/09_image_viewer/image_viewer.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 800, 600
ASSET_PATH = File.expand_path("assets/sample.png", __dir__)

window  = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Image viewer", framerate: 60)
texture = SFML::Texture.load(ASSET_PATH, smooth: true)

# Keep a CPU-side copy of the image around so H/V flip can mutate it
# and Texture#update can re-upload without re-loading from disk.
image = SFML::Image.load(ASSET_PATH)

sprite = SFML::Sprite.new(texture, scale: [4, 4])
sprite.origin = [texture.size.x / 2, texture.size.y / 2]

font = SFML::Font.default
hud  = SFML::Text.new(font, "", character_size: 14, fill_color: SFML::Color.white,
                      position: [10, 10])

clock = SFML::Clock.new

while window.open?
  t = clock.elapsed.as_seconds

  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close

    in {type: :key_pressed, code: :h}
      image.flip_horizontally
      texture.update(image)
    in {type: :key_pressed, code: :v}
      image.flip_vertically
      texture.update(image)
    else
    end
  end

  sprite.position = [
    WINDOW_W / 2 + Math.sin(t) * 200,
    WINDOW_H / 2 + Math.cos(t * 1.5) * 80,
  ]
  sprite.rotation = t * 30

  hud.string = "loaded from #{ASSET_PATH.sub(Dir.pwd + "/", "")}\n" \
               "size: #{texture.size.x}×#{texture.size.y}  •  scale: 4x  •  rotation: #{sprite.rotation.round}°\n" \
               "H/V flip the image  •  Esc quit"

  window.clear(SFML::Color["#101218"])
  window.draw(sprite)
  window.draw(hud)
  window.display
end
