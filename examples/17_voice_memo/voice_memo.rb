#!/usr/bin/env ruby
# frozen_string_literal: true

# A tiny voice-memo recorder. Press R to start capturing audio from the
# default microphone; press R again to stop, which saves the recording
# to ./voice_memo.wav and stages it for playback. Press P to play back
# the saved file.
#
# Demonstrates:
#   - SFML::SoundRecorder.available? to gate features on missing hardware
#   - SFML::SoundBufferRecorder.start / .stop / .buffer
#   - SoundBuffer#save (any extension supported by the CSFML build)
#   - Sound playing back the saved buffer through the same loop
#
# Esc to quit.
#
#     bundle exec ruby examples/17_voice_memo/voice_memo.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

unless SFML::SoundRecorder.available?
  abort "no audio input device available — connect a microphone and retry"
end

WINDOW_W, WINDOW_H = 600, 400
OUT_PATH = File.expand_path("voice_memo.wav", Dir.pwd)

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "Voice memo", framerate: 60)

font = SFML::Font.default
status_text = SFML::Text.new(font, "", character_size: 20,
                             fill_color: SFML::Color.white, position: [20, 20])
hint_text   = SFML::Text.new(font,
  "R   start / stop recording\n" \
  "P   play back ./voice_memo.wav\n" \
  "Esc quit",
  character_size: 14, fill_color: SFML::Color["#888"],
  position: [20, WINDOW_H - 80])

# Visual recording indicator — a circle that pulses red while capturing.
indicator = SFML::CircleShape.new(
  radius:     22,
  origin:     [22, 22],
  position:   [WINDOW_W - 50, 50],
  fill_color: SFML::Color["#222"],
)

recorder       = SFML::SoundBufferRecorder.new
recording      = false
record_started = nil
last_duration  = nil

# Playback state — reusing one Sound across plays so we don't rack up
# stopped instances.
playback_sound = nil

# A clock that runs continuously — used as the time source for the
# pulsing red indicator while recording.
anim_clock = SFML::Clock.new

while window.open?
  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close

    in {type: :key_pressed, code: :r}
      if recording
        recorder.stop
        buf = recorder.buffer
        last_duration = buf.duration.as_seconds
        buf.save(OUT_PATH)
        recording = false
        record_started = nil
        # Reload the saved file as a SoundBuffer that owns its data —
        # the recorder's buffer lives only as long as the recorder.
        playback_buffer = SFML::SoundBuffer.load(OUT_PATH)
        playback_sound  = SFML::Sound.new(playback_buffer)
      else
        ok = recorder.start(sample_rate: 44_100)
        if ok
          recording      = true
          record_started = anim_clock.elapsed.as_seconds
        end
      end

    in {type: :key_pressed, code: :p}
      playback_sound&.play
    else
    end
  end

  now = anim_clock.elapsed.as_seconds

  # Animate the indicator: pulsing red while recording, dim otherwise.
  indicator.fill_color = if recording
                           level = (Math.sin(now * 6.0) * 0.3 + 0.7).clamp(0.4, 1.0)
                           SFML::Color.new((255 * level).to_i, 30, 30)
                         else
                           SFML::Color["#222"]
                         end

  status_text.string = if recording
                         "● REC  #{(now - record_started).round(1)}s"
                       elsif last_duration
                         "saved → #{File.basename(OUT_PATH)}  (#{last_duration.round(2)}s,  press P to play)"
                       else
                         "press R to record"
                       end

  window.clear(SFML::Color["#0e1018"])
  window.draw(indicator)
  window.draw(status_text)
  window.draw(hint_text)
  window.display
end
