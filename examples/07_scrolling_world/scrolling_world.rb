#!/usr/bin/env ruby
# frozen_string_literal: true

# A world wider than the window, panned and zoomed with a SFML::View.
# Demonstrates:
#   - View as a 2D camera (move/zoom)
#   - Two-pass rendering: world pass through the camera, then HUD pass
#     through window.default_view so on-screen text stays pixel-aligned
#   - window.map_pixel_to_coords for "where is the mouse in world space?"
#   - Drag-to-pan and wheel-to-zoom that anchor on the cursor — the world
#     point under the mouse stays under the mouse the whole time
#
# Controls:
#   WASD / arrows         pan
#   right mouse drag      pan (anchored on cursor)
#   mouse wheel           zoom around cursor
#   + / - or numpad +/-   zoom (centred)
#   Esc                   quit
#
#     bundle exec ruby examples/07_scrolling_world/scrolling_world.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 800, 600
WORLD_COLS, WORLD_ROWS = 16, 12
TILE = 100

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Scrolling world", framerate: 280)

camera = SFML::View.new(
  center: [WINDOW_W / 2, WINDOW_H / 2],
  size:   [WINDOW_W,     WINDOW_H],
)

# Build a grid of differently-coloured rectangles. World extent ends up
# at WORLD_COLS*TILE × WORLD_ROWS*TILE = 1600×1200 (twice the window size).
tiles = []
WORLD_COLS.times do |gx|
  WORLD_ROWS.times do |gy|
    checker = (gx + gy).even?
    base = checker ? 60 : 90
    tiles << SFML::RectangleShape.new(
      size:       [TILE - 4, TILE - 4],
      position:   [gx * TILE + 2, gy * TILE + 2],
      fill_color: SFML::Color.new(base + (gx * 7) % 80, base + (gy * 11) % 80, 120),
    )
  end
end

# A landmark to confirm we're really moving in world space.
landmark = SFML::CircleShape.new(
  radius:     30,
  origin:     [30, 30],
  position:   [WORLD_COLS * TILE / 2, WORLD_ROWS * TILE / 2],
  fill_color: SFML::Color.cornflower_blue,
)

# HUD draws in window-pixel space via window.default_view.
hud = SFML::Text.new(SFML::Font.default, "",
  character_size: 16,
  fill_color:     SFML::Color.white,
  position:       [10, 10],
)

clock = SFML::Clock.new
drag_anchor_world = nil   # set when RMB held: the world point that should
                          # stay locked under the cursor while dragging

# FPS counter: count frames over a rolling window and refresh the
# displayed value every 0.25s. Avoids the jitter of `1 / dt` per frame.
fps             = 0
fps_frames      = 0
fps_window_secs = 0.0

while window.open?
  dt = clock.restart.as_seconds

  fps_frames      += 1
  fps_window_secs += dt
  if fps_window_secs >= 0.25
    fps             = (fps_frames / fps_window_secs).round
    fps_frames      = 0
    fps_window_secs = 0.0
  end

  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close

    in {type: :mouse_wheel_scrolled, delta:, position: {x:, y:}}
      # Zoom around the cursor: pin the world point under the mouse,
      # zoom, then shift the camera so that point lands back under it.
      before = window.map_pixel_to_coords([x, y], view: camera)
      camera.zoom(delta.positive? ? 0.9 : 1.1)
      after  = window.map_pixel_to_coords([x, y], view: camera)
      camera.move(before - after)
    else
    end
  end

  # Keyboard pan
  pan = 400 * dt
  camera.move([-pan, 0]) if SFML::Keyboard.key_pressed?(:left)  || SFML::Keyboard.key_pressed?(:a)
  camera.move([pan,  0]) if SFML::Keyboard.key_pressed?(:right) || SFML::Keyboard.key_pressed?(:d)
  camera.move([0, -pan]) if SFML::Keyboard.key_pressed?(:up)    || SFML::Keyboard.key_pressed?(:w)
  camera.move([0,  pan]) if SFML::Keyboard.key_pressed?(:down)  || SFML::Keyboard.key_pressed?(:s)

  # Keyboard zoom (centred on view origin, not cursor)
  zoom_step = 1.0 + dt * 0.5
  camera.zoom(1.0 / zoom_step) if SFML::Keyboard.key_pressed?(:add)      || SFML::Keyboard.key_pressed?(:equal)
  camera.zoom(zoom_step)       if SFML::Keyboard.key_pressed?(:subtract) || SFML::Keyboard.key_pressed?(:hyphen)

  # Left-mouse drag-to-pan: keep the world point grabbed at press time
  # locked under the cursor for as long as RMB is held.
  if SFML::Mouse.button_pressed?(:left)
    cursor_world = window.map_pixel_to_coords(SFML::Mouse.position(window), view: camera)
    if drag_anchor_world
      camera.move(drag_anchor_world - cursor_world)
    else
      drag_anchor_world = cursor_world
    end
  else
    drag_anchor_world = nil
  end

  # Where is the mouse pointing in world coordinates?
  mouse_world = window.map_pixel_to_coords(SFML::Mouse.position(window), view: camera)

  hud.string = "fps: #{fps}  •  " \
               "camera: (#{camera.center.x.round}, #{camera.center.y.round})  •  " \
               "zoom: #{(WINDOW_W / camera.size.x).round(2)}x\n" \
               "mouse in world: (#{mouse_world.x.round}, #{mouse_world.y.round})\n" \
               "WASD/arrows pan  •  RMB drag pans  •  wheel zooms  •  +/- centred zoom  •  Esc quits"

  window.clear(SFML::Color["#0e0e10"])

  # World pass — apply the camera, draw scene.
  window.view = camera
  tiles.each { |t| window.draw(t) }
  window.draw(landmark)

  # HUD pass — restore the default view so on-screen text doesn't scroll.
  window.view = window.default_view
  window.draw(hud)

  window.display
end
