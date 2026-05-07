#!/usr/bin/env ruby
# frozen_string_literal: true

# A grid of cursor-type tiles + a clipboard demo. Hover a tile to swap
# the window's cursor to that system shape; click a tile to copy its
# name onto the system clipboard. Press V to paste whatever's currently
# on the clipboard back into the on-screen log.
#
# Demonstrates:
#   - SFML::Cursor.system(:hand) and the full sfCursorType catalogue
#   - window.cursor=, window.cursor_visible=, window.cursor_grabbed=
#   - SFML::Clipboard.text getter / setter (UTF-8 round-trip)
#
# Controls:
#   hover a tile     change the window cursor to that system shape
#   click a tile     copy the cursor name onto the system clipboard
#   V                paste the current clipboard text into the log
#   H                toggle cursor visibility
#   G                toggle cursor grab (lock pointer to window)
#   Esc              quit
#
#     bundle exec ruby examples/15_cursors_clipboard/cursors_clipboard.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 900, 600

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Cursor + Clipboard", framerate: 60)

font = SFML::Font.default

# ---- Build a tile per cursor type ----------------------------------------

COLS  = 4
ROWS  = (SFML::Cursor::TYPES.length / COLS.to_f).ceil
CELL_W = WINDOW_W / COLS
CELL_H = 50
HEADER_H = 60

tiles = SFML::Cursor::TYPES.each_with_index.map do |type, i|
  col = i % COLS
  row = i / COLS
  x   = col * CELL_W
  y   = HEADER_H + row * CELL_H

  rect = SFML::RectangleShape.new(
    size:              [CELL_W - 4, CELL_H - 4],
    position:          [x + 2, y + 2],
    fill_color:        SFML::Color["#1a1d24"],
    outline_color:     SFML::Color["#2c3340"],
    outline_thickness: 1,
  )
  label = SFML::Text.new(font, type.to_s, character_size: 13,
                         fill_color: SFML::Color["#cfd4dc"],
                         position: [x + 12, y + (CELL_H - 18) / 2])
  { type: type, rect: rect, label: label, x: x, y: y, w: CELL_W, h: CELL_H }
end

# Cursor objects are cheap but creating one every frame would be wasteful;
# pre-build all 21 once. Some cursor types aren't supported by every
# window manager (X11 in particular omits a few of the diagonal-resize
# variants) — those return NULL and we fall back to :arrow on hover.
cursors = SFML::Cursor::TYPES.each_with_object({}) do |type, h|
  h[type] = SFML::Cursor.system(type)
rescue SFML::Error
  h[type] = nil
end

# Mark tiles whose cursor isn't available so the user knows hovering
# them won't change anything.
tiles.each do |t|
  if cursors[t[:type]].nil?
    t[:label].fill_color = SFML::Color["#555"]
    t[:label].string     = "#{t[:type]} (n/a)"
  end
end

window.cursor = cursors[:arrow]

# ---- HUD + clipboard log -------------------------------------------------

header = SFML::Text.new(font, "hover a tile  •  click to copy name to clipboard  •  V paste",
                        character_size: 14, fill_color: SFML::Color.white,
                        position: [12, 12])
flags  = SFML::Text.new(font, "", character_size: 13,
                        fill_color: SFML::Color["#888"], position: [12, 32])
log    = SFML::Text.new(font, "(clipboard log)", character_size: 14,
                        fill_color: SFML::Color["#cfd4dc"],
                        position: [12, HEADER_H + ROWS * CELL_H + 16])

cursor_visible = true
cursor_grabbed = false

# ---- Main loop -----------------------------------------------------------

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close

    in {type: :key_pressed, code: :v}
      log.string = "clipboard: #{SFML::Clipboard.text.inspect}"

    in {type: :key_pressed, code: :h}
      cursor_visible        = !cursor_visible
      window.cursor_visible = cursor_visible

    in {type: :key_pressed, code: :g}
      cursor_grabbed        = !cursor_grabbed
      window.cursor_grabbed = cursor_grabbed

    in {type: :mouse_button_pressed, button: :left, position: {x:, y:}}
      tile = tiles.find { |t| x.between?(t[:x], t[:x] + t[:w]) && y.between?(t[:y], t[:y] + t[:h]) }
      if tile
        SFML::Clipboard.text = tile[:type].to_s
        log.string = "copied → #{tile[:type]}"
      end
    else
    end
  end

  # Hover detection: which tile (if any) holds the mouse, swap the window cursor.
  pos     = SFML::Mouse.position(window)
  hovered = tiles.find { |t| pos.x.between?(t[:x], t[:x] + t[:w]) && pos.y.between?(t[:y], t[:y] + t[:h]) }
  if hovered && cursors[hovered[:type]]
    window.cursor = cursors[hovered[:type]]
  else
    window.cursor = cursors[:arrow]
  end

  flags.string = "visible: #{cursor_visible ? 'on' : 'off'} (H)  •  grabbed: #{cursor_grabbed ? 'on' : 'off'} (G)"

  window.clear(SFML::Color["#0e1018"])
  window.draw(header)
  window.draw(flags)
  tiles.each do |t|
    # Highlight the hovered tile.
    t[:rect].fill_color = (hovered && hovered.equal?(t)) ? SFML::Color["#2a3344"] : SFML::Color["#1a1d24"]
    window.draw(t[:rect])
    window.draw(t[:label])
  end
  window.draw(log)
  window.display
end
