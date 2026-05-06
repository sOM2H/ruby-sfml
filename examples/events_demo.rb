#!/usr/bin/env ruby
# frozen_string_literal: true

# Prints input events to stdout. The point is to show how case/in pattern
# matching against ruby-sfml events looks in practice.
#
# Press keys, type characters, click and scroll the mouse, resize/refocus
# the window. Esc or close button to quit.
#
#     bundle exec ruby examples/events_demo.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

window = SFML::RenderWindow.new(640, 360, "ruby-sfml events demo", framerate: 60)

puts "Press keys, type, move/click/scroll the mouse. Esc to quit."
puts "─" * 60

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}
      window.close

    in {type: :key_pressed, code: :escape}
      window.close

    in {type: :key_pressed, code:, shift:, control:, alt:}
      mods = [shift && "shift", control && "ctrl", alt && "alt"].select { _1 }
      label = mods.empty? ? code.to_s : "#{mods.join('+')}+#{code}"
      puts "key pressed:   #{label}"

    in {type: :key_released, code:}
      puts "key released:  #{code}"

    in {type: :text_entered, char:}
      next if char.empty? || char.bytes.first < 32  # skip control chars
      puts "text entered:  #{char.inspect}"

    in {type: :resized, size: {x:, y:}}
      puts "resized:       #{x}x#{y}"

    in {type: :focus_gained} then puts "focus gained"
    in {type: :focus_lost}   then puts "focus lost"

    in {type: :mouse_button_pressed, button:, position: {x:, y:}}
      puts "mouse press:   #{button} at (#{x}, #{y})"

    in {type: :mouse_button_released, button:, position: {x:, y:}}
      puts "mouse release: #{button} at (#{x}, #{y})"

    in {type: :mouse_wheel_scrolled, wheel:, delta:}
      puts "mouse wheel:   #{wheel} delta=#{delta}"

    else
      # mouse_moved/_raw fire constantly — silenced for legibility.
    end
  end

  window.clear(SFML::Color.cornflower_blue)
  window.display
end
