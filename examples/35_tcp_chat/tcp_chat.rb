#!/usr/bin/env ruby
# frozen_string_literal: true

# TCP chat over typed `SFML::Network::Packet`s. Runs in one of
# three modes:
#
#   loopback          server + client in one process for a quick demo
#   server [PORT]     bind PORT (default 9000), echo each Packet back
#   client HOST PORT  connect to HOST:PORT, type to send messages
#
# Why `Packet` rather than raw byte send/receive: CSFML frames
# each packet on the wire with its byte count, so the receiver
# always gets a whole message even when TCP fragments the stream.
# Inside the packet you read/write typed primitives (Int32, String,
# Float, …) directly — no manual marshaling.
#
# Examples:
#
#     # quick "yes it works" demo in one window
#     bundle exec ruby examples/35_tcp_chat/tcp_chat.rb
#
#     # two-window real chat:
#     # terminal A:
#     bundle exec ruby examples/35_tcp_chat/tcp_chat.rb server 9000
#     # terminal B:
#     bundle exec ruby examples/35_tcp_chat/tcp_chat.rb client 127.0.0.1 9000
#
# Keys: type printable ASCII → Enter sends • Backspace deletes •
#       Esc quits.

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "sfml"

# ----------------------------------------------------------------
# Shared base — every mode draws a HUD with a draft line + log.
# Subclasses fill `@log` from their own send/receive pump.
# ----------------------------------------------------------------
class ChatBase < SFML::App
  width  720
  height 480
  background SFML::Color["#0b0f14"]

  on_key :escape,    :quit
  on_key :enter,     :send_current
  on_key :backspace, :backspace_draft

  def setup_common
    @log   = []
    @draft = ""
    @sent  = @received = 0

    @font = SFML::Font.default
    @hud  = SFML::Text.new(@font, "", character_size: 14,
                           fill_color: SFML::Color.white, position: [10, 10])
  end

  def on_event(event)
    case event
    in {type: :text_entered, unicode:}
      ch = [unicode].pack("U")
      @draft << ch if ch =~ /[\x20-\x7e]/   # printable ASCII only
    else
      super
    end
  end

  def backspace_draft
    @draft.chop!
  end

  def draw
    window.draw(@hud)
  end

  # Build a Packet with a monotonically increasing sequence number,
  # the message text, and a timestamp. Sent over `socket`.
  def send_packet_via(socket)
    return if @draft.empty?
    return unless socket

    pkt = SFML::Network::Packet.new
      .write_int32(@sent + 1)
      .write_string(@draft)
      .write_float(Time.now.to_f.modulo(86_400).round(2))

    status = socket.send_packet(pkt)
    if status == :done
      @sent += 1
      @log << "→ ##{@sent} #{@draft.inspect}"
      @draft.clear
    else
      @log << "send failed: #{status}"
    end
  end

  # Read whatever's queued on `socket` (non-blocking). Returns
  # [seq, msg, stamp] on a complete packet, nil otherwise.
  def receive_packet_from(socket)
    return nil unless socket
    status, pkt = socket.receive_packet
    return nil unless status == :done
    [pkt.read_int32, pkt.read_string, pkt.read_float]
  rescue StandardError => e
    @log << "receive error: #{e.message}"
    nil
  end

  def refresh_hud(header)
    visible = @log.last(18)
    @hud.string =
      "#{header}\n" \
      "sent: #{@sent}  •  received: #{@received}  •  Esc to quit\n" \
      "draft: #{@draft.inspect}\n\n" \
      "log (last 18 lines):\n#{visible.join("\n")}"
  end
end

# ----------------------------------------------------------------
# Server: bind a port, accept ALL incoming connections, echo each
# received Packet back. Holds connections in an array; polls them
# every frame.
# ----------------------------------------------------------------
class ChatServer < ChatBase
  title "TCP chat — SERVER"

  def initialize(port:)
    @port = port
    super()
  end

  def setup
    setup_common

    @listener = SFML::Network::TcpListener.new
    @listener.listen(port: @port, address: SFML::Network::IpAddress::ANY)
    @listener.blocking = false
    @peers = []

    @log << "[server] listening on 0.0.0.0:#{@listener.local_port}"
    @log << "[server] connect from another shell:"
    @log << "          ruby tcp_chat.rb client 127.0.0.1 #{@listener.local_port}"
  end

  def update(_dt)
    # New connections.
    status, peer = @listener.accept
    if status == :done
      peer.blocking = false
      @peers << peer
      @log << "[server] accepted #{@peers.size} client(s) total"
    end

    # Pump every connected peer.
    @peers.each_with_index do |sock, idx|
      result = receive_packet_from(sock)
      next unless result
      seq, msg, stamp = result
      @received += 1
      @log << "[peer ##{idx}] ##{seq} #{msg.inspect} @ #{stamp.round(2)}s"

      # Echo it back to the same peer.
      reply = SFML::Network::Packet.new
        .write_int32(seq).write_string("echo:#{msg}").write_float(stamp)
      sock.send_packet(reply)
    end

    refresh_hud("TCP server on port #{@listener.local_port}  •  #{@peers.size} client(s)")
  end

  def send_current
    # Server-side broadcast: send the typed message to every peer.
    return if @draft.empty?
    @peers.each { |sock| send_packet_via(sock) }
  end
end

# ----------------------------------------------------------------
# Client: connect to a remote host:port, type → Enter → send.
# Server replies show up in the log.
# ----------------------------------------------------------------
class ChatClient < ChatBase
  title "TCP chat — CLIENT"

  def initialize(host:, port:)
    @host, @port = host, port
    super()
  end

  def setup
    setup_common

    @socket = SFML::Network::TcpSocket.new
    status  = @socket.connect(SFML::Network::IpAddress.from_string(@host),
                              port: @port,
                              timeout: SFML::Time.seconds(2))
    if status != :done
      @log << "[client] connect failed: #{status}"
      @socket = nil
      return
    end
    @socket.blocking = false
    @log << "[client] connected to #{@host}:#{@port}"
  end

  def update(_dt)
    result = receive_packet_from(@socket)
    if result
      seq, msg, stamp = result
      @received += 1
      @log << "← ##{seq} #{msg.inspect} (round-trip)"
    end

    state = @socket ? "connected to #{@host}:#{@port}" : "DISCONNECTED"
    refresh_hud("TCP client  •  #{state}")
  end

  def send_current
    send_packet_via(@socket)
  end
end

# ----------------------------------------------------------------
# Loopback: both server and client in one process. Same logic, but
# without a network hop — useful as a "is the wiring right?" demo.
# ----------------------------------------------------------------
class ChatLoopback < ChatBase
  title "TCP chat — LOOPBACK demo"

  def setup
    setup_common

    @listener = SFML::Network::TcpListener.new
    @listener.listen(port: 0, address: SFML::Network::IpAddress::LOCALHOST)
    @port     = @listener.local_port
    @listener.blocking = false

    @client = SFML::Network::TcpSocket.new
    status  = @client.connect(SFML::Network::IpAddress::LOCALHOST, port: @port)
    raise "loopback connect failed: #{status}" unless status == :done
    @client.blocking = false

    @server_peer = nil
    @log << "[loopback] running both ends in this process, port #{@port}"
  end

  def update(_dt)
    # Accept the client we just connected (once).
    unless @server_peer
      status, peer = @listener.accept
      if status == :done
        peer.blocking = false
        @server_peer = peer
        @log << "[server-side] accepted client connection"
      end
    end

    # Server-side: echo each Packet back.
    if @server_peer
      result = receive_packet_from(@server_peer)
      if result
        seq, msg, stamp = result
        @log << "[server ←] ##{seq} #{msg.inspect}"
        reply = SFML::Network::Packet.new
          .write_int32(seq).write_string("echo:#{msg}").write_float(stamp)
        @server_peer.send_packet(reply)
      end
    end

    # Client-side: collect server replies.
    result = receive_packet_from(@client)
    if result
      seq, msg, stamp = result
      @received += 1
      @log << "[client ←] ##{seq} #{msg.inspect} (round-trip)"
    end

    refresh_hud("Loopback demo on port #{@port}  •  server + client in one process")
  end

  def send_current
    send_packet_via(@client)
  end
end

# ----------------------------------------------------------------
# Mode dispatch.
# ----------------------------------------------------------------
case ARGV.first
when "server"
  port = (ARGV[1] || 9000).to_i
  ChatServer.new(port: port).run
when "client"
  host = ARGV[1] or abort "usage: tcp_chat.rb client HOST PORT"
  port = (ARGV[2] || abort("usage: tcp_chat.rb client HOST PORT")).to_i
  ChatClient.new(host: host, port: port).run
when nil, "loopback"
  ChatLoopback.new.run
else
  abort "usage: tcp_chat.rb [loopback | server [PORT] | client HOST PORT]"
end
