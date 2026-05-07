module SFML
  module Network
    # Connectionless UDP datagram socket. Bind a port to receive,
    # send to (address, port). Stateless — every send/receive specifies
    # the peer.
    #
    #   sock = SFML::Network::UdpSocket.new
    #   sock.bind(port: 9999)
    #   sock.send("hello", to: SFML::Network::IpAddress::LOCALHOST, port: 9000)
    #   status, bytes, addr, port = sock.receive(max: 1024)
    class UdpSocket
      MAX_DATAGRAM_SIZE = C::Network.sfUdpSocket_maxDatagramSize

      def initialize
        ptr = C::Network.sfUdpSocket_create
        raise Error, "sfUdpSocket_create returned NULL" if ptr.null?
        @handle = FFI::AutoPointer.new(ptr, C::Network.method(:sfUdpSocket_destroy))
      end

      def bind(port:, address: IpAddress::ANY)
        addr = address.is_a?(IpAddress) ? address : IpAddress.from_string(address)
        code = C::Network.sfUdpSocket_bind(@handle, Integer(port), addr.struct)
        C::Network::STATUSES[code]
      end

      def unbind
        C::Network.sfUdpSocket_unbind(@handle)
        self
      end

      def send(data, to:, port:)
        bytes = data.to_s
        addr  = to.is_a?(IpAddress) ? to : IpAddress.from_string(to)
        buf   = FFI::MemoryPointer.new(:uint8, bytes.bytesize)
        buf.write_bytes(bytes)
        code = C::Network.sfUdpSocket_send(@handle, buf, bytes.bytesize, addr.struct, Integer(port))
        C::Network::STATUSES[code]
      end

      # Returns [status, data, sender_ip, sender_port].
      # `data` is a binary String when status is :done, otherwise nil.
      def receive(max: 1024)
        buf            = FFI::MemoryPointer.new(:uint8, Integer(max))
        received_size  = FFI::MemoryPointer.new(:size_t)
        sender_addr    = C::Network::IpAddress.new
        sender_port    = FFI::MemoryPointer.new(:uint16)

        code = C::Network.sfUdpSocket_receive(
          @handle, buf, Integer(max), received_size, sender_addr.pointer, sender_port,
        )
        status = C::Network::STATUSES[code]

        return [status, nil, nil, nil] unless status == :done
        n     = received_size.read(:size_t)
        sip   = IpAddress.wrap(sender_addr)
        sport = sender_port.read(:uint16)
        [status, buf.read_bytes(n), sip, sport]
      end

      def blocking? = C::Network.sfUdpSocket_isBlocking(@handle)

      def blocking=(value)
        C::Network.sfUdpSocket_setBlocking(@handle, value ? true : false)
      end

      def local_port = C::Network.sfUdpSocket_getLocalPort(@handle)

      attr_reader :handle # :nodoc:
    end
  end
end
