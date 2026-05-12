#!/usr/bin/env ruby
# frozen_string_literal: true

# A single UDP socket sends a "ping #N" packet to itself every second
# and shows the round-trip in a scrollable in-window log. Every send is
# painted as a small dot drifting toward the bottom — when its echo is
# received the dot turns green.
#
# Demonstrates:
#   - SFML::Network::UdpSocket (bind, non-blocking receive, send)
#   - IpAddress::LOCALHOST as destination
#   - Polling sockets from a regular game loop without threads
#
# Esc to quit.
#
#     bundle exec ruby examples/34_udp_loopback/udp_loopback.rb

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

WINDOW_W, WINDOW_H = 700, 480

# ---- Set up the socket ----------------------------------------------------

sock = SFML::Network::UdpSocket.new
sock.blocking = false
status = sock.bind(port: 0)   # 0 = let the OS pick a free port
abort "couldn't bind UDP socket: #{status}" unless status == :done
puts "bound to localhost:#{sock.local_port}"

# ---- Window + UI ----------------------------------------------------------

window = SFML::RenderWindow.new(WINDOW_W, WINDOW_H, "UDP loopback", framerate: 60)
font   = SFML::Font.default

header = SFML::Text.new(font, "self-port: #{sock.local_port}  •  Esc quits",
                        character_size: 14, fill_color: SFML::Color["#aaa"],
                        position: [10, 10])

# Most recent log lines
log_lines = []
log_text  = SFML::Text.new(font, "", character_size: 13,
                           fill_color: SFML::Color.white, position: [10, 36])

# Animated dots: each spawned on send, painted green when echoed.
in_flight = {}   # seq → { x:, y:, sent_at:, echoed: }

clock      = SFML::Clock.new
last_send  = -1.0
seq        = 0

def append_log(lines, msg)
  lines.unshift("#{Time.now.strftime('%H:%M:%S')}  #{msg}")
  lines.first(20)
end

while window.open?
  t = clock.elapsed.as_seconds

  window.each_event do |event|
    case event
    in {type: :closed}                     then window.close
    in {type: :key_pressed, code: :escape} then window.close
    else
    end
  end

  # 1. Send roughly once a second.
  if t - last_send >= 1.0
    seq      += 1
    payload  = "ping ##{seq}"
    status   = sock.send(payload, to: SFML::Network::IpAddress::LOCALHOST, port: sock.local_port)
    last_send = t
    if status == :done
      log_lines = append_log(log_lines, "→ #{payload}")
      in_flight[seq] = { y: 80, sent_at: t, echoed: false }
    else
      log_lines = append_log(log_lines, "send failed: #{status}")
    end
  end

  # 2. Drain inbound datagrams (non-blocking → :done if any, else :not_ready).
  loop do
    rstatus, bytes, _ip, _port = sock.receive(max: 256)
    break unless rstatus == :done

    log_lines = append_log(log_lines, "← #{bytes}")
    if (m = bytes.match(/\Aping #(\d+)\z/)) && (entry = in_flight[m[1].to_i])
      entry[:echoed] = true
    end
  end

  # 3. Animate the in-flight dots: drift down, fade after 3s.
  in_flight.each_value { |e| e[:y] += 90.0 / 60.0 }   # 90 px/sec downward
  in_flight.delete_if { |_, e| t - e[:sent_at] > 3.0 }

  log_text.string = log_lines.join("\n")

  window.clear(SFML::Color["#0e1018"])
  window.draw(header)
  window.draw(log_text)

  in_flight.each do |id, e|
    age = t - e[:sent_at]
    fade = (1.0 - age / 3.0).clamp(0.0, 1.0)
    color = if e[:echoed]
              SFML::Color.new(80, 220, 100, (255 * fade).to_i)
            else
              SFML::Color.new(255, 200, 80, (255 * fade).to_i)
            end
    dot = SFML::CircleShape.new(
      radius:     6,
      origin:     [6, 6],
      position:   [WINDOW_W - 60 - (id % 5) * 12, e[:y]],
      fill_color: color,
    )
    window.draw(dot)
  end

  window.display
end
