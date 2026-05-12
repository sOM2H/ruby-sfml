module SFML
  module Network
    # Binary serializer with explicit, typed read/write — wire-compatible
    # with SFML's `sf::Packet`. Used by Tcp/UdpSocket's `send_packet`
    # /`receive_packet` (the network layer prepends a 4-byte length header
    # for TCP framing, so the receiver always gets a whole packet).
    #
    # All read calls consume bytes in FIFO order. After a write you can
    # always re-read by sending the packet over the wire; the local
    # read position only advances on the receive side. To rewind a
    # locally-built packet, just construct a new one.
    #
    #   pkt = SFML::Network::Packet.new
    #   pkt.write_int32(42)
    #   pkt.write_string("hello")
    #   pkt.write_float(0.5)
    #
    #   # … send over a TcpSocket, receive on the other end …
    #
    #   incoming.read_int32     #=> 42
    #   incoming.read_string    #=> "hello"
    #   incoming.read_float     #=> 0.5
    class Packet
      def initialize
        ptr = C::Network.sfPacket_create
        raise NetworkError, "sfPacket_create returned NULL" if ptr.null?
        @handle = FFI::AutoPointer.new(ptr, C::Network.method(:sfPacket_destroy))
      end

      # Returns the clear.
      def clear
        C::Network.sfPacket_clear(@handle)
        self
      end

      # Append a raw byte buffer (no length prefix, no type tag) — for
      # interop with hand-crafted binary protocols. Most callers want
      # `write_string` / `write_int32` etc. instead.
      def append(bytes)
        s = bytes.to_s
        buf = FFI::MemoryPointer.new(:uint8, s.bytesize)
        buf.write_bytes(s)
        C::Network.sfPacket_append(@handle, buf, s.bytesize)
        self
      end

      # Returns the full packet as a binary String. Includes any length
      # prefixes / type encoding sfPacket added on write.
      def data
        size = C::Network.sfPacket_getDataSize(@handle)
        return "".b if size.zero?
        ptr = C::Network.sfPacket_getData(@handle)
        ptr.read_bytes(size).force_encoding(Encoding::ASCII_8BIT)
      end

      # Returns the size.
      def size            = C::Network.sfPacket_getDataSize(@handle)
      # Returns the read position.
      def read_position   = C::Network.sfPacket_getReadPosition(@handle)
      # `true` if end of packet.
      def end_of_packet?  = C::Network.sfPacket_endOfPacket(@handle)

      # `false` if the last read overran the packet — sfPacket "fails"
      # quietly rather than raising, and subsequent reads return zero.
      # Check this after a read sequence to validate the frame.
      def ok? = C::Network.sfPacket_canRead(@handle)

      # ---- typed writers ----
      # All writers append to the end of the packet and return self
      # for chaining.

      # Append a Bool.
      def write_bool(v)
        C::Network.sfPacket_writeBool(@handle, v ? true : false); self
      end
      # Append a signed 8-bit Integer.
      def write_int8(v)   = (C::Network.sfPacket_writeInt8(@handle,   Integer(v)); self)
      # Append an unsigned 8-bit Integer.
      def write_uint8(v)  = (C::Network.sfPacket_writeUint8(@handle,  Integer(v)); self)
      # Append a signed 16-bit Integer.
      def write_int16(v)  = (C::Network.sfPacket_writeInt16(@handle,  Integer(v)); self)
      # Append an unsigned 16-bit Integer.
      def write_uint16(v) = (C::Network.sfPacket_writeUint16(@handle, Integer(v)); self)
      # Append a signed 32-bit Integer.
      def write_int32(v)  = (C::Network.sfPacket_writeInt32(@handle,  Integer(v)); self)
      # Append an unsigned 32-bit Integer.
      def write_uint32(v) = (C::Network.sfPacket_writeUint32(@handle, Integer(v)); self)
      # Append a signed 64-bit Integer.
      def write_int64(v)  = (C::Network.sfPacket_writeInt64(@handle,  Integer(v)); self)
      # Append an unsigned 64-bit Integer.
      def write_uint64(v) = (C::Network.sfPacket_writeUint64(@handle, Integer(v)); self)
      # Append a single-precision Float.
      def write_float(v)  = (C::Network.sfPacket_writeFloat(@handle,  Float(v));   self)
      # Append a double-precision Float.
      def write_double(v) = (C::Network.sfPacket_writeDouble(@handle, Float(v));   self)

      # Append a length-prefixed UTF-8 String.
      def write_string(str)
        C::Network.sfPacket_writeString(@handle, str.to_s)
        self
      end

      # ---- typed readers ----
      def read_bool   = C::Network.sfPacket_readBool(@handle)
      # Returns the read int8.
      def read_int8   = C::Network.sfPacket_readInt8(@handle)
      # Returns the read uint8.
      def read_uint8  = C::Network.sfPacket_readUint8(@handle)
      # Returns the read int16.
      def read_int16  = C::Network.sfPacket_readInt16(@handle)
      # Returns the read uint16.
      def read_uint16 = C::Network.sfPacket_readUint16(@handle)
      # Returns the read int32.
      def read_int32  = C::Network.sfPacket_readInt32(@handle)
      # Returns the read uint32.
      def read_uint32 = C::Network.sfPacket_readUint32(@handle)
      # Returns the read int64.
      def read_int64  = C::Network.sfPacket_readInt64(@handle)
      # Returns the read uint64.
      def read_uint64 = C::Network.sfPacket_readUint64(@handle)
      # Returns the read float.
      def read_float  = C::Network.sfPacket_readFloat(@handle)
      # Returns the read double.
      def read_double = C::Network.sfPacket_readDouble(@handle)

      # Read a length-prefixed string. CSFML expects a caller-allocated
      # C buffer of "string length + 1 NUL" bytes — we size it from the
      # remaining packet bytes, which is always an upper bound.
      def read_string
        remaining = size - read_position
        return "" if remaining <= 0

        buf = FFI::MemoryPointer.new(:char, remaining + 1)
        C::Network.sfPacket_readString(@handle, buf)
        buf.read_string.force_encoding(Encoding::UTF_8)
      end

      # Returns the dup.
      def dup
        ptr = C::Network.sfPacket_copy(@handle)
        raise NetworkError, "sfPacket_copy returned NULL" if ptr.null?

        copy = self.class.allocate
        copy.instance_variable_set(:@handle,
          FFI::AutoPointer.new(ptr, C::Network.method(:sfPacket_destroy)))
        copy
      end
      alias clone dup

      attr_reader :handle # :nodoc:
    end
  end
end
