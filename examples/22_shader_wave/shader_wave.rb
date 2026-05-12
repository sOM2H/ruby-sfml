#!/usr/bin/env ruby
# frozen_string_literal: true

# Pure GLSL — the fragment shader generates every pixel from scratch
# using `gl_FragCoord` and three uniforms (time, resolution, mouse).
# No input texture, no Ruby-side image generation; we hand the GPU a
# fullscreen rectangle and let the shader draw the whole frame.
#
# Demonstrates:
#   - SFML::Shader.from_file loading GLSL from assets/wave.frag
#   - shader[:uniform] = value: Float, Vector2 dispatch
#   - window.draw(shape, shader: shader) plumbing through RenderStates
#
# Move the mouse to shift the ripple centre. Esc to quit.
#
#     bundle exec ruby examples/22_shader_wave/shader_wave.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

abort "GLSL shaders are not available on this GPU" unless SFML::Shader.available?

WINDOW_W, WINDOW_H = 800, 600

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Shader (pure GLSL)", framerate: 60)

# A fullscreen canvas — its colour is irrelevant since the shader
# overwrites every pixel anyway. It just exists so there's a fragment
# to run the shader for.
canvas = SFML::RectangleShape.new(size: [WINDOW_W, WINDOW_H])

shader = SFML::Shader.from_file(
  fragment: File.expand_path("assets/wave.frag", __dir__),
)
shader[:resolution] = SFML::Vector2[WINDOW_W, WINDOW_H]

font = SFML::Font.default
hud  = SFML::Text.new(font, "move the mouse  •  Esc quits", character_size: 14,
                      fill_color: SFML::Color.white, position: [10, 10])

clock = SFML::Clock.new

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else
    end
  end

  shader[:time]  = clock.elapsed.as_seconds
  shader[:mouse] = SFML::Mouse.position(window)

  window.clear(SFML::Color.black)
  window.draw(canvas, shader: shader)
  window.draw(hud)
  window.display
end
