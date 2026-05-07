#!/usr/bin/env ruby
# frozen_string_literal: true

# A bare SFML::Window — gets you a window + GL context + the standard
# input/event flow, but no built-in 2D rendering. You'd use this when
# you want to drive raw OpenGL (or another rendering library) yourself
# and just need SFML to manage the platform-level window. The window's
# contents are whatever the GL framebuffer happens to hold each frame —
# typically uninitialised colour, since there's no Ruby OpenGL binding
# in this repo to actually clear or draw anything.
#
# In practice this is rarely what 2D Ruby gamedev wants — you almost
# always want SFML::RenderWindow. This example exists for completeness
# and to verify the bare event flow works end-to-end.
#
# Events get printed to stdout. Esc to quit.
#
#     bundle exec ruby examples/20_bare_window/bare_window.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

window = SFML::Window.new(640, 360, "bare SFML::Window", framerate: 60)

puts "Window open: #{window.size.x}×#{window.size.y}, position #{window.position.to_a}"
puts "Press keys, click, resize — events stream to stdout. Esc quits."
puts "─" * 60

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close

    in {type: :key_pressed, code:}         then puts "key:    #{code}"
    in {type: :resized, size: {x:, y:}}    then puts "resize: #{x}×#{y}"
    in {type: :focus_gained}               then puts "focus gained"
    in {type: :focus_lost}                 then puts "focus lost"
    in {type: :mouse_button_pressed, button:, position: {x:, y:}}
      puts "click:  #{button} at (#{x}, #{y})"
    else
      # mouse_moved, joystick_moved, etc. — too noisy to log
    end
  end

  window.display
end

puts "window closed cleanly"
