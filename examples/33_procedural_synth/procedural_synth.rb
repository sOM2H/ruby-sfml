#!/usr/bin/env ruby
# frozen_string_literal: true

# Mini procedural piano — generate sine-wave PCM samples in Ruby,
# build a `SoundBuffer` directly from the Array, and play it via
# `Sound`. No `.wav` files involved.
#
# `SFML::SoundBuffer.from_samples(samples, sample_rate:,
# channel_count:)` is the key API — it accepts a Ruby Array of
# signed-16-bit ints and hands you a buffer ready for playback.
#
# Demonstrates:
#   - `SoundBuffer.from_samples` — fully procedural audio
#   - One sample buffer per note, cached so each key press is cheap
#   - ADSR-ish amplitude envelope (attack/release) to avoid clicks
#
# Keys: Z S X D C V G B H N J M  — a chromatic octave starting at
# middle C (C4). Hold for sustain, release for fade-out.
# Esc to quit.
#
#     bundle exec ruby examples/33_procedural_synth/procedural_synth.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

SAMPLE_RATE = 44_100
NOTE_DURATION_S = 0.7
ATTACK_S        = 0.01
RELEASE_S       = 0.1

# Generate signed-16-bit PCM samples for `freq` Hz over `duration` s.
# Mixes a fundamental + a fifth harmonic for a richer timbre, then
# applies attack/release envelope.
def make_tone(freq, duration_s)
  n        = (SAMPLE_RATE * duration_s).to_i
  attack_n = (SAMPLE_RATE * ATTACK_S).to_i
  release_n = (SAMPLE_RATE * RELEASE_S).to_i
  step     = 2 * Math::PI * freq / SAMPLE_RATE

  Array.new(n) do |i|
    s = Math.sin(step * i) * 0.7 + Math.sin(2 * step * i) * 0.3
    env =
      if    i < attack_n     then i.to_f / attack_n
      elsif i > n - release_n then (n - i).to_f / release_n
      else 1.0
      end
    (s * env * 14_000).to_i.clamp(-32_768, 32_767)
  end
end

# 12 chromatic notes starting at middle C (MIDI 60 = C4 = 261.63 Hz).
NOTES = {
  z: { name: "C4",  midi: 60 },
  s: { name: "C#4", midi: 61 },
  x: { name: "D4",  midi: 62 },
  d: { name: "D#4", midi: 63 },
  c: { name: "E4",  midi: 64 },
  v: { name: "F4",  midi: 65 },
  g: { name: "F#4", midi: 66 },
  b: { name: "G4",  midi: 67 },
  h: { name: "G#4", midi: 68 },
  n: { name: "A4",  midi: 69 },
  j: { name: "A#4", midi: 70 },
  m: { name: "B4",  midi: 71 },
}.freeze

class ProceduralSynth < SFML::App
  width  720
  height 320
  title  "Procedural synth — SoundBuffer.from_samples"
  background SFML::Color["#0a0d12"]

  on_key :escape, :quit

  def setup
    # Pre-bake one buffer per key — cheap to keep all 12 in RAM.
    @buffers = NOTES.transform_values do |info|
      freq = 440.0 * (2 ** ((info[:midi] - 69) / 12.0))
      samples = make_tone(freq, NOTE_DURATION_S)
      SFML::SoundBuffer.from_samples(samples, sample_rate: SAMPLE_RATE, channel_count: 1)
    end

    @sounds   = {}     # Sounds we've spawned so they stay alive while playing
    @history  = []

    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 16,
                           fill_color: SFML::Color.white, position: [10, 10])
  end

  def on_event(event)
    case event
    in {type: :key_pressed, code:}
      info = NOTES[code]
      if info
        play_note(code, info)
      else
        super
      end
    else
      super
    end
  end

  def update(_dt)
    # Reap finished Sounds so the array doesn't grow forever.
    @sounds.delete_if { |_id, s| s.stopped? }
    refresh_hud
  end

  def draw
    window.draw(@hud)
  end

  def play_note(code, info)
    sound = SFML::Sound.new(@buffers[code])
    sound.play
    @sounds[Time.now.to_f] = sound     # unique key, kept alive until stopped
    @history.unshift("#{info[:name]} (#{code})")
    @history.pop while @history.size > 18
  end

  def refresh_hud
    @hud.string =
      "Procedural synth — generate PCM samples, build SoundBuffer.from_samples\n" \
      "keys: Z S X D C V G B H N J M  →  chromatic C4..B4  •  Esc to quit\n\n" \
      "active voices: #{@sounds.size}\n" \
      "history:\n#{@history.join("\n")}"
  end
end

ProceduralSynth.new.run
