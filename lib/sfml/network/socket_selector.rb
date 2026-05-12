module SFML
  module Network
    # Multiplex many sockets onto a single blocking #wait. Useful for
    # one-thread network servers — register every socket / listener
    # you care about, call #wait, then ask each one whether it's
    # `ready?`. Ready means there's data to read or, for a listener,
    # an incoming connection waiting.
    #
    #   selector = SFML::Network::SocketSelector.new
    #   selector.add(listener)
    #   clients.each { |c| selector.add(c) }
    #
    #   if selector.wait(timeout: 1.0)
    #     if selector.ready?(listener)
    #       # accept() will not block
    #     end
    #     clients.each do |c|
    #       next unless selector.ready?(c)
    #       # receive() will return data
    #     end
    #   end
    #
    # Ruby's `IO.select` covers a similar use case for plain Ruby IO
    # objects; this binding exists for game code that's already using
    # `SFML::Network::Tcp{Socket,Listener}` / `UdpSocket`.
    class SocketSelector
      def initialize
        ptr = C::Network.sfSocketSelector_create
        raise NetworkError, "sfSocketSelector_create returned NULL" if ptr.null?

        @handle = FFI::AutoPointer.new(ptr, C::Network.method(:sfSocketSelector_destroy))
      end

      def add(socket)
        case socket
        when TcpListener then C::Network.sfSocketSelector_addTcpListener(@handle, socket.handle)
        when TcpSocket   then C::Network.sfSocketSelector_addTcpSocket(@handle,  socket.handle)
        when UdpSocket   then C::Network.sfSocketSelector_addUdpSocket(@handle,  socket.handle)
        else
          raise ArgumentError,
                "SocketSelector#add expects TcpListener, TcpSocket, or UdpSocket (got #{socket.class})"
        end
        self
      end

      def remove(socket)
        case socket
        when TcpListener then C::Network.sfSocketSelector_removeTcpListener(@handle, socket.handle)
        when TcpSocket   then C::Network.sfSocketSelector_removeTcpSocket(@handle,  socket.handle)
        when UdpSocket   then C::Network.sfSocketSelector_removeUdpSocket(@handle,  socket.handle)
        else
          raise ArgumentError,
                "SocketSelector#remove expects TcpListener, TcpSocket, or UdpSocket (got #{socket.class})"
        end
        self
      end

      def clear
        C::Network.sfSocketSelector_clear(@handle)
        self
      end

      # Block until at least one registered socket has activity, or
      # `timeout` elapses. `timeout` may be a SFML::Time, a Numeric
      # (seconds), or nil / SFML::Time.zero (no timeout — block
      # forever). Returns true if a socket is ready, false on timeout.
      def wait(timeout: nil)
        t =
          case timeout
          when nil     then SFML::Time.zero
          when Time    then timeout
          when Numeric then SFML::Time.seconds(timeout.to_f)
          else
            raise ArgumentError, "timeout must be SFML::Time, Numeric, or nil"
          end
        C::Network.sfSocketSelector_wait(@handle, t.to_native)
      end

      def ready?(socket)
        case socket
        when TcpListener then C::Network.sfSocketSelector_isTcpListenerReady(@handle, socket.handle)
        when TcpSocket   then C::Network.sfSocketSelector_isTcpSocketReady(@handle,  socket.handle)
        when UdpSocket   then C::Network.sfSocketSelector_isUdpSocketReady(@handle,  socket.handle)
        else
          raise ArgumentError,
                "SocketSelector#ready? expects TcpListener, TcpSocket, or UdpSocket (got #{socket.class})"
        end
      end

      attr_reader :handle # :nodoc:
    end
  end
end
