#!/usr/bin/env ruby
# frozen_string_literal: true

# Three looping drones placed around the window. The SFML::Listener
# follows the mouse, so as you move the cursor toward a speaker its
# volume rises (and pans toward the matching ear). Demonstrates:
#
#   - Sound#position=, #attenuation=, #min_distance=
#   - SFML::Listener.position= drives stereo panning + per-source volume
#   - Procedural seamless-loop WAV generation at startup so the example
#     ships zero binary audio assets
#
# Esc to quit.
#
#     bundle exec ruby examples/16_spatial_audio/spatial_audio.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"
require "fileutils"

WINDOW_W, WINDOW_H = 800, 600

# ---- Drone WAV generator -------------------------------------------------
# A pure sine at `freq` Hz, length chosen so an integer number of cycles
# fit — that lets the loop wrap seamlessly without click artifacts.

def write_drone(path, freq:, sample_rate: 44100)
  return if File.exist?(path)

  samples_per_cycle = (sample_rate / freq.to_f).round
  total_samples     = samples_per_cycle * 80   # ~0.4 s, give or take

  bytes = String.new(capacity: total_samples * 2)
  total_samples.times do |i|
    val = (Math.sin(2 * Math::PI * freq * i / sample_rate) * 9000).to_i
    bytes << [val].pack("s<")
  end

  size   = bytes.bytesize
  header = [
    "RIFF", 36 + size, "WAVE",
    "fmt ", 16, 1, 1, sample_rate, sample_rate * 2, 2, 16,
    "data", size,
  ].pack("a4Va4a4VvvVVvva4V")

  FileUtils.mkdir_p(File.dirname(path))
  File.binwrite(path, header + bytes)
end

assets_dir = File.expand_path("assets", __dir__)
SOURCES = [
  { freq: 220, position: [180, 200, 0], color: SFML::Color.new(220,  90,  90) },
  { freq: 330, position: [620, 200, 0], color: SFML::Color.new( 90, 200, 110) },
  { freq: 440, position: [400, 470, 0], color: SFML::Color.new( 90, 130, 230) },
].each do |s|
  s[:path] = File.join(assets_dir, "drone_#{s[:freq]}.wav")
  write_drone(s[:path], freq: s[:freq])
end

# ---- Setup ----------------------------------------------------------------

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Spatial audio", framerate: 60)

speakers = SOURCES.map do |s|
  buffer = SFML::SoundBuffer.load(s[:path])
  sound  = SFML::Sound.new(buffer, looping: true, volume: 80)
  sound.position     = s[:position]
  sound.min_distance = 60.0
  sound.attenuation  = 2.0
  sound.play

  shape = SFML::CircleShape.new(
    radius:        24,
    origin:        [24, 24],
    position:      [s[:position][0], s[:position][1]],
    fill_color:    s[:color],
    outline_color: SFML::Color.white,
    outline_thickness: 2,
  )

  { sound: sound, shape: shape, freq: s[:freq], pos: s[:position] }
end

# Listener cursor — a small white pulse following the mouse.
listener_dot = SFML::CircleShape.new(
  radius:            8,
  origin:            [8, 8],
  fill_color:        SFML::Color.white,
  outline_color:     SFML::Color.black,
  outline_thickness: 1,
)

font = SFML::Font.default
hud  = SFML::Text.new(font, "", character_size: 14, fill_color: SFML::Color.white,
                      position: [10, 10])

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else
    end
  end

  pos = SFML::Mouse.position(window)
  SFML::Listener.position = [pos.x, pos.y, 0]
  listener_dot.position   = [pos.x, pos.y]

  # For each speaker, compute distance and a perceived-volume estimate
  # (matches the SFML inverse-distance attenuation curve).
  lines = speakers.map do |sp|
    dx = pos.x - sp[:pos][0]
    dy = pos.y - sp[:pos][1]
    dist = Math.sqrt((dx * dx) + (dy * dy))
    md   = sp[:sound].min_distance
    att  = sp[:sound].attenuation
    # SFML inverse-distance model: volume = md / (md + att * (max(d, md) - md))
    factor = md / (md + att * ([dist, md].max - md))
    "#{sp[:freq]} Hz: dist=#{dist.round} px, perceived ≈ #{(factor * 100).round}%"
  end.join("\n")

  hud.string = "Move mouse — listener follows  •  Esc quits\n#{lines}"

  window.clear(SFML::Color["#0c0e14"])
  speakers.each { |sp| window.draw(sp[:shape]) }
  window.draw(listener_dot)
  window.draw(hud)
  window.display
end
