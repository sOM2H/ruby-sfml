module SFML
  module Network
    # A TCP client socket. Connect to a server, send/receive bytes,
    # disconnect.
    #
    #   sock = SFML::Network::TcpSocket.new
    #   case sock.connect(SFML::Network::IpAddress::LOCALHOST, port: 8080)
    #   when :done then ...
    #   end
    #
    #   sock.send("hello")
    #   status, bytes = sock.receive(max: 1024)
    #
    # By default sockets are blocking; set `socket.blocking = false`
    # for non-blocking polling, where send/receive may return :not_ready.
    class TcpSocket
      def initialize
        ptr = C::Network.sfTcpSocket_create
        raise NetworkError, "sfTcpSocket_create returned NULL" if ptr.null?
        @handle = FFI::AutoPointer.new(ptr, C::Network.method(:sfTcpSocket_destroy))
      end

      # Open a connection. Returns one of the SOCKET_STATUSES symbols
      # (:done, :not_ready, :disconnected, :error). `timeout` is a
      # SFML::Time; SFML::Time.zero (default) blocks forever.
      def connect(address, port:, timeout: SFML::Time.zero)
        addr = address.is_a?(IpAddress) ? address : IpAddress.from_string(address)
        code = C::Network.sfTcpSocket_connect(@handle, addr.struct, Integer(port), timeout.to_native)
        C::Network::STATUSES[code]
      end

      def disconnect
        C::Network.sfTcpSocket_disconnect(@handle)
        self
      end

      def send(data)
        bytes = data.to_s
        buf   = FFI::MemoryPointer.new(:uint8, bytes.bytesize)
        buf.write_bytes(bytes)
        code = C::Network.sfTcpSocket_send(@handle, buf, bytes.bytesize)
        C::Network::STATUSES[code]
      end

      # Read up to `max` bytes. Returns [status, data] — `data` is a
      # binary String when status is :done, nil otherwise.
      def receive(max: 4096)
        buf      = FFI::MemoryPointer.new(:uint8, Integer(max))
        received = FFI::MemoryPointer.new(:size_t)
        code = C::Network.sfTcpSocket_receive(@handle, buf, Integer(max), received)
        status = C::Network::STATUSES[code]

        return [status, nil] unless status == :done
        n = received.read(:size_t)
        [status, buf.read_bytes(n)]
      end

      # Send a structured SFML::Network::Packet. CSFML frames the wire
      # bytes with a length prefix so the peer's receive_packet always
      # gets a whole packet (no need to handle TCP boundary fragments
      # at the Ruby layer).
      def send_packet(packet)
        raise ArgumentError, "expected SFML::Network::Packet" unless packet.is_a?(Packet)
        code = C::Network.sfTcpSocket_sendPacket(@handle, packet.handle)
        C::Network::STATUSES[code]
      end

      # Receive into a fresh Packet. Returns [status, packet]; the
      # packet is nil for non-:done statuses.
      def receive_packet
        pkt  = Packet.new
        code = C::Network.sfTcpSocket_receivePacket(@handle, pkt.handle)
        status = C::Network::STATUSES[code]
        [status, status == :done ? pkt : nil]
      end

      def blocking? = C::Network.sfTcpSocket_isBlocking(@handle)

      def blocking=(value)
        C::Network.sfTcpSocket_setBlocking(@handle, value ? true : false)
      end

      def local_port  = C::Network.sfTcpSocket_getLocalPort(@handle)
      def remote_port = C::Network.sfTcpSocket_getRemotePort(@handle)

      def remote_address
        IpAddress.wrap(C::Network.sfTcpSocket_getRemoteAddress(@handle))
      end

      attr_reader :handle # :nodoc:
    end
  end
end
