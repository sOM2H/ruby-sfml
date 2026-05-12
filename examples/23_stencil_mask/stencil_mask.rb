#!/usr/bin/env ruby
# frozen_string_literal: true

# Stencil-buffer masking — clip a colourful animated background to a
# moving circular spotlight using a two-pass draw:
#
#   1. Mask pass: draw a circle that follows the cursor, configured to
#      WRITE into the stencil buffer (reference=1) but skip the colour
#      buffer (`only_write_mask: true`).
#
#   2. Content pass: draw the animated background with a stencil mode
#      that reads — `comparison: :equal, reference: 1` — so only
#      pixels inside the mask survive.
#
# Move the mouse to drag the spotlight around. Esc to quit.
#
#     bundle exec ruby examples/23_stencil_mask/stencil_mask.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

W, H = 800, 600

window = SFML::RenderWindow.new(W, H, "ruby-sfml — stencil mask", framerate: 60)

# A column of colourful stripes — the "content" we'll mask.
stripes = (0..H / 20).map do |i|
  hue   = (i * 12) % 360
  rgb   = SFML::Color.new(*hsv_to_rgb(hue, 0.6, 0.95))
  SFML::RectangleShape.new(
    size:       [W, 18],
    position:   [0, i * 20],
    fill_color: rgb,
  )
end

# The mask shape — a circle. Position is updated each frame to follow
# the mouse.
spotlight = SFML::CircleShape.new(
  radius:     90,
  origin:     [90, 90],
  fill_color: SFML::Color.white,
)

write_mask = SFML::StencilMode.new(
  comparison:        :always,
  update_operation:  :replace,
  reference:         1,
  only_write_mask:   true,    # mask shape is invisible — only updates stencil
)

read_mask = SFML::StencilMode.new(
  comparison:        :equal,
  update_operation:  :keep,
  reference:         1,
)

clock = SFML::Clock.new

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    in {type: :mouse_moved, position: {x:, y:}} then spotlight.position = [x, y]
    else
    end
  end

  # Animate the stripes vertically by shifting their positions.
  shift = (clock.elapsed_time.as_seconds * 60).to_i % 20
  stripes.each_with_index { |s, i| s.position = [0, (i * 20 + shift) - 20] }

  # Both colour and stencil get reset every frame — the stencil starts
  # at zero, then phase 1 stamps `1` into the spotlight's footprint.
  window.clear(SFML::Color.new(20, 22, 28), stencil: 0)

  window.draw(spotlight, stencil_mode: write_mask)
  stripes.each { |s| window.draw(s, stencil_mode: read_mask) }

  window.display
end

# HSV→RGB. h in [0,360), s/v in [0,1].
BEGIN {
  def hsv_to_rgb(h, s, v)
    c = v * s
    x = c * (1 - ((h / 60.0) % 2 - 1).abs)
    m = v - c
    r1, g1, b1 = case h
                 when   0...60  then [c, x, 0]
                 when  60...120 then [x, c, 0]
                 when 120...180 then [0, c, x]
                 when 180...240 then [0, x, c]
                 when 240...300 then [x, 0, c]
                 else                [c, 0, x]
                 end
    [(r1 + m) * 255, (g1 + m) * 255, (b1 + m) * 255].map { |c| c.round.clamp(0, 255) }
  end
}
