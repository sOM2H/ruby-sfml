#!/usr/bin/env ruby
# frozen_string_literal: true

# Live joystick / gamepad inspector. Plug in any controller and you should
# see its name, axis bars, and button states. If nothing is connected,
# the demo still runs and shows a slot-grid that lights up when you
# plug something in.
#
# Demonstrates:
#   - SFML::Joystick polling API (connected?, axis_position, button_pressed?)
#   - SFML::Joystick.identification — vendor / product IDs
#   - Connect / disconnect events through case/in pattern matching
#   - Pre-allocating per-frame drawables instead of building them every frame
#
# Esc to quit.
#
#     bundle exec ruby examples/08_joystick_demo/joystick_demo.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 800, 600
SLOT = 0  # show detailed state for slot 0

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Joystick demo", framerate: 60)
font   = SFML::Font.default

# ---- Pre-allocated drawables --------------------------------------------

header = SFML::Text.new(font, "", character_size: 16, fill_color: SFML::Color.white,
                        position: [20, 20])

# An axis has a name label, a track, a fill that pulses with the value,
# and a number printed to the right.
TRACK_W = 240
TRACK_H = 12
TRACK_X = 100

axis_widgets = SFML::Joystick::AXES.each_with_index.map do |axis, i|
  y = 90 + i * 28
  {
    axis:  axis,
    label: SFML::Text.new(font, axis.to_s, character_size: 14,
                          fill_color: SFML::Color["#aaa"], position: [20, y - 2]),
    track: SFML::RectangleShape.new(size: [TRACK_W, TRACK_H], position: [TRACK_X, y],
                                    fill_color: SFML::Color["#222"]),
    centre_tick: SFML::RectangleShape.new(size: [1, TRACK_H + 4],
                                          position: [TRACK_X + TRACK_W / 2, y - 2],
                                          fill_color: SFML::Color["#555"]),
    fill:  SFML::RectangleShape.new(size: [0, TRACK_H], position: [TRACK_X + TRACK_W / 2, y],
                                    fill_color: SFML::Color.cornflower_blue),
    value: SFML::Text.new(font, "—", character_size: 14, fill_color: SFML::Color.white,
                          position: [TRACK_X + TRACK_W + 12, y - 2]),
  }
end

# Up to 32 buttons, two rows of 16.
button_widgets = (0...SFML::Joystick::MAX_BUTTON_COUNT).map do |b|
  row = b / 16
  col = b % 16
  SFML::CircleShape.new(
    radius:            10,
    position:          [20 + col * 30, 360 + row * 30],
    fill_color:        SFML::Color["#222"],
    outline_color:     SFML::Color["#666"],
    outline_thickness: 1,
  )
end

button_label = SFML::Text.new(font, "buttons:", character_size: 14,
                              fill_color: SFML::Color["#aaa"], position: [20, 332])

# Slot grid (only used when SLOT 0 isn't connected) — 8 dots showing
# which of the 0..7 slots have something attached.
slot_dots = (0...SFML::Joystick::MAX_COUNT).map do |i|
  SFML::CircleShape.new(
    radius:            8,
    position:          [20 + i * 26, 90],
    fill_color:        SFML::Color["#333"],
    outline_color:     SFML::Color.white,
    outline_thickness: 1,
  )
end

slot_grid_label = SFML::Text.new(font, "slots 0..7:", character_size: 14,
                                 fill_color: SFML::Color["#aaa"], position: [20, 65])

empty_msg = SFML::Text.new(font,
  "No joystick in slot #{SLOT}. Plug in a controller — its name will appear here.",
  character_size: 16, fill_color: SFML::Color.white, position: [20, 20])

# ---- Main loop ----------------------------------------------------------

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                              then window.close
    in {type: :key_pressed, code: :escape}          then window.close
    in {type: :joystick_connected, joystick_id: id} then puts "[joystick #{id}] connected"
    in {type: :joystick_disconnected, joystick_id: id} then puts "[joystick #{id}] disconnected"
    else
    end
  end

  window.clear(SFML::Color["#0e0e10"])

  if SFML::Joystick.connected?(SLOT)
    info = SFML::Joystick.identification(SLOT)
    header.string = "Joystick #{SLOT}: #{info[:name]}\n" \
                    "vendor=0x#{info[:vendor_id].to_s(16).rjust(4, '0')}  " \
                    "product=0x#{info[:product_id].to_s(16).rjust(4, '0')}  " \
                    "buttons=#{SFML::Joystick.button_count(SLOT)}"
    window.draw(header)

    axis_widgets.each do |w|
      if SFML::Joystick.has_axis?(SLOT, w[:axis])
        pos = SFML::Joystick.axis_position(SLOT, w[:axis])
        # Map [-100, 100] into a left/right fill from the centre tick.
        fill_w = pos.abs / 100.0 * TRACK_W / 2.0
        fill_x = pos >= 0 ? TRACK_X + TRACK_W / 2 : TRACK_X + TRACK_W / 2 - fill_w
        w[:fill].size = [fill_w, TRACK_H]
        w[:fill].position = [fill_x, w[:fill].position.y]
        w[:value].string = format("%+7.1f", pos)

        window.draw(w[:track])
        window.draw(w[:centre_tick])
        window.draw(w[:fill]) if fill_w > 0.5
        window.draw(w[:label])
        window.draw(w[:value])
      end
    end

    window.draw(button_label)
    btn_count = SFML::Joystick.button_count(SLOT)
    button_widgets.each_with_index do |btn, b|
      next if b >= btn_count
      btn.fill_color = SFML::Joystick.button_pressed?(SLOT, b) ?
                       SFML::Color.cornflower_blue :
                       SFML::Color["#222"]
      window.draw(btn)
    end
  else
    window.draw(empty_msg)
    window.draw(slot_grid_label)
    slot_dots.each_with_index do |dot, i|
      dot.fill_color = SFML::Joystick.connected?(i) ?
                       SFML::Color.cornflower_blue :
                       SFML::Color["#333"]
      window.draw(dot)
    end
  end

  window.display
end
