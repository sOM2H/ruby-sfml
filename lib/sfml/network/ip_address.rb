module SFML
  module Network
    # An IPv4 address. The CSFML side stores it as a fixed-size 16-byte
    # NUL-terminated dotted-decimal string ("192.168.1.42").
    #
    #   SFML::Network::IpAddress.from_string("192.168.1.42")
    #   SFML::Network::IpAddress.from_bytes(192, 168, 1, 42)
    #   SFML::Network::IpAddress::LOCALHOST   # 127.0.0.1
    #   SFML::Network::IpAddress::ANY         # 0.0.0.0
    #   SFML::Network::IpAddress::BROADCAST   # 255.255.255.255
    #   SFML::Network::IpAddress.local        # local network IP
    class IpAddress
      # Parse from a dotted-decimal string like `"192.168.1.42"`.
      def self.from_string(s)
        wrap(C::Network.sfIpAddress_fromString(s.to_s))
      end

      # Build from four octets: `from_bytes(192, 168, 1, 42)`.
      def self.from_bytes(a, b, c, d)
        wrap(C::Network.sfIpAddress_fromBytes(Integer(a), Integer(b), Integer(c), Integer(d)))
      end

      # Build from a 32-bit packed integer.
      def self.from_integer(n)
        wrap(C::Network.sfIpAddress_fromInteger(Integer(n)))
      end

      # The IP this machine sees on its local network.
      def self.local
        wrap(C::Network.sfIpAddress_getLocalAddress)
      end

      # Public-facing IP. Performs an outbound query, so optionally
      # cap with a timeout. Slow — minutes if the network is down.
      def self.public(timeout: SFML::Time.zero)
        wrap(C::Network.sfIpAddress_getPublicAddress(timeout.to_native))
      end

      # @!visibility private
      def self.wrap(struct)
        ip = allocate
        ip.instance_variable_set(:@struct, struct)
        ip.freeze
      end

      # Dotted-decimal string ("192.168.1.42").
      def to_s
        @struct[:address].to_ptr.read_string_to_null
      end
      alias inspect to_s

      # Packed 32-bit Integer view of the address.
      def to_i
        C::Network.sfIpAddress_toInteger(@struct)
      end

      # Value equality — same dotted-decimal string.
      def ==(other)
        other.is_a?(IpAddress) && to_s == other.to_s
      end
      alias eql? ==
      # Returns the hash.
      def hash = to_s.hash

      # @!visibility private
      attr_reader :struct

      # The 0.0.0.0 / empty placeholder address.
      NONE      = wrap(C::Network.sfIpAddress_None)
      # 0.0.0.0 — match any local interface.
      ANY       = wrap(C::Network.sfIpAddress_Any)
      # 127.0.0.1 — local-only.
      LOCALHOST = wrap(C::Network.sfIpAddress_LocalHost)
      # 255.255.255.255 — broadcast on the local subnet.
      BROADCAST = wrap(C::Network.sfIpAddress_Broadcast)
    end
  end
end
