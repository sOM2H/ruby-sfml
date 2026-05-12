module SFML
  module Network
    # The server side of TCP. Listens on a port; #accept blocks until a
    # client connects, then returns a fresh TcpSocket for that peer.
    #
    #   listener = SFML::Network::TcpListener.new
    #   listener.listen(port: 8080)
    #   loop do
    #     status, peer = listener.accept
    #     break unless status == :done
    #     handle_client(peer)
    #   end
    class TcpListener
      def initialize
        ptr = C::Network.sfTcpListener_create
        raise NetworkError, "sfTcpListener_create returned NULL" if ptr.null?
        @handle = FFI::AutoPointer.new(ptr, C::Network.method(:sfTcpListener_destroy))
      end

      # Bind the listener to a port and start listening.
      # `address` (default: any local interface) restricts which interface
      # to listen on — pass IpAddress::LOCALHOST for loopback-only.
      def listen(port:, address: IpAddress::ANY)
        addr = address.is_a?(IpAddress) ? address : IpAddress.from_string(address)
        code = C::Network.sfTcpListener_listen(@handle, Integer(port), addr.struct)
        C::Network::STATUSES[code]
      end

      def close
        C::Network.sfTcpListener_close(@handle)
        self
      end

      # Returns [status, TcpSocket] — the socket is non-nil only when
      # status == :done.
      def accept
        out_ptr = FFI::MemoryPointer.new(:pointer)
        code = C::Network.sfTcpListener_accept(@handle, out_ptr)
        status = C::Network::STATUSES[code]

        return [status, nil] unless status == :done
        sock_ptr = out_ptr.read_pointer
        return [status, nil] if sock_ptr.null?

        sock = TcpSocket.allocate
        sock.instance_variable_set(:@handle, FFI::AutoPointer.new(sock_ptr, C::Network.method(:sfTcpSocket_destroy)))
        [status, sock]
      end

      # `true` if blocking.
      def blocking? = C::Network.sfTcpListener_isBlocking(@handle)

      # Set the blocking.
      def blocking=(value)
        C::Network.sfTcpListener_setBlocking(@handle, value ? true : false)
      end

      # Returns the local port.
      def local_port = C::Network.sfTcpListener_getLocalPort(@handle)

      attr_reader :handle # :nodoc:
    end
  end
end
