#!/usr/bin/env ruby
# frozen_string_literal: true

# Set a custom title-bar / taskbar icon on a window. The icon can come
# from a file (load with SFML::Image.load) or be generated procedurally
# — this example builds a 32×32 ruby-style gem in code so there's no
# asset to ship.
#
#     bundle exec ruby examples/21_window_icon/window_icon.rb
#
# Look at the title bar / dock / taskbar (location depends on OS) to
# see the icon. Esc to quit.

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

def build_icon
  size = 32
  img = SFML::Image.new(size, size, fill: SFML::Color.new(0, 0, 0, 0))

  # Hexagonal ruby silhouette: 6 vertices around a center at (16, 16).
  cx, cy = 15.5, 15.5
  r      = 14.0
  verts  = (0..5).map do |i|
    angle = (60 * i - 30) * Math::PI / 180.0
    [cx + r * Math.cos(angle), cy + r * Math.sin(angle)]
  end

  size.times do |y|
    size.times do |x|
      next unless point_in_hex?(x, y, verts)

      # Vertical gradient — light at the top, dark at the bottom — to
      # hint at facets without us drawing them per-pixel.
      t = (y / size.to_f).clamp(0, 1)
      r_byte = (240 * (1 - t) + 90 * t).to_i
      g_byte = (60  * (1 - t) + 5  * t).to_i
      b_byte = (90  * (1 - t) + 20 * t).to_i
      img[x, y] = SFML::Color.new(r_byte, g_byte, b_byte, 255)
    end
  end

  img
end

# Even-odd point-in-polygon test against the 6 hex vertices.
def point_in_hex?(x, y, verts)
  inside = false
  j = verts.size - 1
  verts.each_with_index do |(xi, yi), i|
    xj, yj = verts[j]
    if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
      inside = !inside
    end
    j = i
  end
  inside
end

window = SFML::RenderWindow.new(480, 320, "ruby-sfml — custom window icon", framerate: 60)
window.icon = build_icon

hint = SFML::Text.new(
  SFML::Font.default,
  "look at the title bar / dock\nEsc to quit",
  character_size: 22,
  fill_color:     SFML::Color.white,
  position:       [40, 120],
)

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else
    end
  end

  window.clear(SFML::Color.new(20, 22, 28))
  window.draw(hint)
  window.display
end
