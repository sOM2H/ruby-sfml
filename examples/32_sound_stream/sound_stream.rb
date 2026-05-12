#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate audio in real time. Subclass SFML::SoundStream and override
# #on_get_data — CSFML calls it on its audio thread whenever it
# needs more samples. Here we synthesize a sine wave whose frequency
# you sweep with the arrow keys.
#
#   ←/→  shift frequency by 50Hz
#   ↑/↓  shift volume
#   Esc  quit
#
#     bundle exec ruby examples/32_sound_stream/sound_stream.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

class SineStream < SFML::SoundStream
  attr_accessor :frequency

  def initialize(frequency:, sample_rate: 44_100)
    super(channel_count: 1, sample_rate: sample_rate)
    @frequency   = frequency.to_f
    @sample_rate = sample_rate
    @phase       = 0.0
  end

  def on_get_data
    frames = @sample_rate / 10  # ~100 ms chunks
    step   = 2 * Math::PI * @frequency / @sample_rate

    Array.new(frames) do
      sample = (Math.sin(@phase) * 24_000).to_i
      @phase = (@phase + step) % (2 * Math::PI)
      sample
    end
  end

  def on_seek(_time)
    @phase = 0.0
  end
end

window = SFML::RenderWindow.new(640, 320, "ruby-sfml — SoundStream synth", framerate: 60)

stream = SineStream.new(frequency: 440)
stream.volume  = 30
stream.looping = true
stream.play

font = SFML::Font.default
hud  = SFML::Text.new(font, "", character_size: 24, fill_color: SFML::Color.white,
                      position: [24, 18])

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    in {type: :key_pressed, code: :left}   then stream.frequency = [stream.frequency - 50, 50].max
    in {type: :key_pressed, code: :right}  then stream.frequency += 50
    in {type: :key_pressed, code: :up}     then stream.volume    = [stream.volume + 5, 100].min
    in {type: :key_pressed, code: :down}   then stream.volume    = [stream.volume - 5, 0].max
    else
    end
  end

  hud.string = "freq: #{stream.frequency.round} Hz   volume: #{stream.volume.round}\n" \
               "←/→ pitch · ↑/↓ volume · Esc quit"

  window.clear(SFML::Color.new(20, 22, 28))
  window.draw(hud)
  window.display
end

stream.stop
