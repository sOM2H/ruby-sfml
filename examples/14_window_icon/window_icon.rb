#!/usr/bin/env ruby
# frozen_string_literal: true

# Set a custom title-bar / taskbar icon on a window. The icon can come
# from a file (load with SFML::Image.load) or be generated procedurally
# — this example builds a 64×64 ruby-style gem in code so there's no
# asset to ship.
#
#     bundle exec ruby examples/14_window_icon/window_icon.rb
#
# CAVEAT — where the icon shows up depends on your OS / window manager:
#
#   * Windows / macOS  — appears in the title bar + taskbar / dock.
#   * KDE on X11       — appears in the title bar.
#   * GNOME on X11     — usually ignored; GNOME pulls the icon from
#                        the `.desktop` file's StartupWMClass instead.
#   * Wayland          — the windowing protocol has NO concept of a
#                        per-window icon — it's always taken from
#                        a `.desktop` file. SFML's setIcon is a no-op.
#
# To make the icon visible regardless of WM, this demo also draws the
# **same image** at 6× inside the window. If you see the gem in the
# window content, the icon was built correctly — whether your DE
# chose to also paint it on the title bar is a separate question.
#
# Esc to quit.

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

ICON_SIZE = 64

# Build a 64×64 hexagonal ruby silhouette with a vertical gradient.
def build_icon
  img = SFML::Image.new(ICON_SIZE, ICON_SIZE, fill: SFML::Color.transparent)

  cx, cy = (ICON_SIZE - 1) / 2.0, (ICON_SIZE - 1) / 2.0
  r      = ICON_SIZE / 2.0 - 2
  verts  = (0..5).map do |i|
    angle = (60 * i - 30) * Math::PI / 180.0
    [cx + r * Math.cos(angle), cy + r * Math.sin(angle)]
  end

  ICON_SIZE.times do |y|
    ICON_SIZE.times do |x|
      next unless point_in_hex?(x, y, verts)

      # Vertical gradient — light at the top, dark at the bottom — to
      # hint at facets without us drawing them per-pixel.
      t = (y / ICON_SIZE.to_f).clamp(0, 1)
      r_byte = (240 * (1 - t) + 90 * t).to_i
      g_byte = (60  * (1 - t) + 5  * t).to_i
      b_byte = (90  * (1 - t) + 20 * t).to_i
      img[x, y] = SFML::Color.new(r_byte, g_byte, b_byte, 255)
    end
  end

  # White highlight stripe near the top to make it look glassy.
  (ICON_SIZE / 8..ICON_SIZE / 4).each do |y|
    (ICON_SIZE / 3..ICON_SIZE * 2 / 3).each do |x|
      next unless point_in_hex?(x, y, verts)
      img[x, y] = SFML::Color.new(255, 220, 230, 200)
    end
  end

  img
end

# Even-odd point-in-polygon test against the hex vertices.
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

window = SFML::RenderWindow.new(560, 380, "ruby-sfml — custom window icon",
                                framerate: 60, antialiasing: 4)
icon_image = build_icon

# 1. The actual icon-set call. On supported platforms this updates the
#    title-bar / dock / taskbar icon. On others it's a no-op.
window.icon = icon_image

# 2. Show the same image inside the window so you can see it was built
#    correctly regardless of how the WM treats it.
icon_texture = SFML::Texture.from_image(icon_image)
icon_sprite  = SFML::Sprite.new(icon_texture,
                                position: [380, 130],
                                scale:    [3, 3])

# 3. Same image scaled up bigger, to make the colours obvious.
big_sprite   = SFML::Sprite.new(icon_texture,
                                position: [50, 50],
                                scale:    [4.5, 4.5])

font  = SFML::Font.default
title = SFML::Text.new(font,
                       "Procedural icon: 64×64 hex ruby",
                       character_size: 18,
                       fill_color: SFML::Color.white,
                       position: [50, 340])

hint = SFML::Text.new(font,
                      "↑ this image is what was handed to\n" \
                      "  window.icon = ...\n" \
                      "  (also visible in the title bar on\n" \
                      "   Windows / macOS / KDE)\n\n" \
                      "Esc to quit",
                      character_size: 14,
                      fill_color: SFML::Color.new(200, 200, 210),
                      position: [380, 60])

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else
    end
  end

  window.clear(SFML::Color.new(20, 22, 28))
  window.draw(big_sprite)
  window.draw(icon_sprite)
  window.draw(hint)
  window.draw(title)
  window.display
end
