#!/usr/bin/env ruby
# frozen_string_literal: true

# An empty window. Closes on the X button or Escape.
#
# Run from the gem root:
#
#     bundle exec ruby examples/01_hello_window/hello_window.rb

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sfml"

window = SFML::RenderWindow.new(800, 600, "Hello, ruby-sfml", framerate: 60)

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else
      # ignore everything else for now
    end
  end

  window.clear(SFML::Color.cornflower_blue)
  window.display
end
