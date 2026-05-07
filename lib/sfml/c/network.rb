module SFML
  module C
    module Network
      extend FFI::Library

      ffi_lib LIB_CANDIDATES[:network]

      typedef :pointer, :tcp_socket_t
      typedef :pointer, :tcp_listener_t
      typedef :pointer, :udp_socket_t
      typedef :pointer, :packet_t

      # sfIpAddress is just a 16-byte string buffer (IPv4 dotted-decimal,
      # NUL-terminated). Pass-by-value for most CSFML calls.
      class IpAddress < FFI::Struct
        layout :address, [:char, 16]
      end

      # sfSocketStatus enum order — see CSFML/Network/SocketStatus.h.
      STATUSES = %i[done not_ready partial disconnected error].freeze

      # ---- IpAddress ----
      attach_variable :sfIpAddress_None,      IpAddress
      attach_variable :sfIpAddress_Any,       IpAddress
      attach_variable :sfIpAddress_LocalHost, IpAddress
      attach_variable :sfIpAddress_Broadcast, IpAddress

      attach_function :sfIpAddress_fromString,      [:string], IpAddress.by_value
      attach_function :sfIpAddress_fromBytes,       [:uint8, :uint8, :uint8, :uint8], IpAddress.by_value
      attach_function :sfIpAddress_fromInteger,     [:uint32], IpAddress.by_value
      attach_function :sfIpAddress_toInteger,       [IpAddress.by_value], :uint32
      attach_function :sfIpAddress_getLocalAddress, [], IpAddress.by_value
      attach_function :sfIpAddress_getPublicAddress,[System::Time.by_value], IpAddress.by_value

      # ---- TcpSocket ----
      attach_function :sfTcpSocket_create,         [], :tcp_socket_t
      attach_function :sfTcpSocket_destroy,        [:tcp_socket_t], :void
      attach_function :sfTcpSocket_setBlocking,    [:tcp_socket_t, :bool], :void
      attach_function :sfTcpSocket_isBlocking,     [:tcp_socket_t], :bool
      attach_function :sfTcpSocket_getLocalPort,   [:tcp_socket_t], :uint16
      attach_function :sfTcpSocket_getRemoteAddress, [:tcp_socket_t], IpAddress.by_value
      attach_function :sfTcpSocket_getRemotePort,  [:tcp_socket_t], :uint16
      attach_function :sfTcpSocket_connect,        [:tcp_socket_t, IpAddress.by_value, :uint16, System::Time.by_value], :int
      attach_function :sfTcpSocket_disconnect,     [:tcp_socket_t], :void
      attach_function :sfTcpSocket_send,           [:tcp_socket_t, :pointer, :size_t], :int
      attach_function :sfTcpSocket_sendPartial,    [:tcp_socket_t, :pointer, :size_t, :pointer], :int
      attach_function :sfTcpSocket_receive,        [:tcp_socket_t, :pointer, :size_t, :pointer], :int

      # ---- TcpListener ----
      attach_function :sfTcpListener_create,        [], :tcp_listener_t
      attach_function :sfTcpListener_destroy,       [:tcp_listener_t], :void
      attach_function :sfTcpListener_setBlocking,   [:tcp_listener_t, :bool], :void
      attach_function :sfTcpListener_isBlocking,    [:tcp_listener_t], :bool
      attach_function :sfTcpListener_getLocalPort,  [:tcp_listener_t], :uint16
      attach_function :sfTcpListener_listen,        [:tcp_listener_t, :uint16, IpAddress.by_value], :int
      attach_function :sfTcpListener_close,         [:tcp_listener_t], :void
      attach_function :sfTcpListener_accept,        [:tcp_listener_t, :pointer], :int

      # ---- UdpSocket ----
      attach_function :sfUdpSocket_create,           [], :udp_socket_t
      attach_function :sfUdpSocket_destroy,          [:udp_socket_t], :void
      attach_function :sfUdpSocket_setBlocking,      [:udp_socket_t, :bool], :void
      attach_function :sfUdpSocket_isBlocking,       [:udp_socket_t], :bool
      attach_function :sfUdpSocket_getLocalPort,     [:udp_socket_t], :uint16
      attach_function :sfUdpSocket_bind,             [:udp_socket_t, :uint16, IpAddress.by_value], :int
      attach_function :sfUdpSocket_unbind,           [:udp_socket_t], :void
      attach_function :sfUdpSocket_send,             [:udp_socket_t, :pointer, :size_t, IpAddress.by_value, :uint16], :int
      attach_function :sfUdpSocket_receive,          [:udp_socket_t, :pointer, :size_t, :pointer, :pointer, :pointer], :int
      attach_function :sfUdpSocket_maxDatagramSize,  [], :uint32

      # ---- Packet (typed serializer) ----
      attach_function :sfPacket_create,         [], :packet_t
      attach_function :sfPacket_destroy,        [:packet_t], :void
      attach_function :sfPacket_append,         [:packet_t, :pointer, :size_t], :void
      attach_function :sfPacket_clear,          [:packet_t], :void
      attach_function :sfPacket_getData,        [:packet_t], :pointer

      # ---- HTTP ----
      typedef :pointer, :http_t
      typedef :pointer, :http_request_t
      typedef :pointer, :http_response_t

      # Order matches sfHttpMethod in CSFML 3.
      HTTP_METHODS = %i[get post head put delete].freeze

      # CSFML returns sfHttpStatus as an int. Most are HTTP status
      # codes; the four sfInvalid*/sfConnectionFailed are SFML-side
      # transport errors above the HTTP status range.
      attach_function :sfHttpRequest_create,      [], :http_request_t
      attach_function :sfHttpRequest_destroy,     [:http_request_t], :void
      attach_function :sfHttpRequest_setField,    [:http_request_t, :string, :string], :void
      attach_function :sfHttpRequest_setMethod,   [:http_request_t, :int], :void
      attach_function :sfHttpRequest_setUri,      [:http_request_t, :string], :void
      attach_function :sfHttpRequest_setHttpVersion, [:http_request_t, :uint32, :uint32], :void
      attach_function :sfHttpRequest_setBody,     [:http_request_t, :string], :void

      attach_function :sfHttpResponse_destroy,         [:http_response_t], :void
      attach_function :sfHttpResponse_getField,        [:http_response_t, :string], :string
      attach_function :sfHttpResponse_getStatus,       [:http_response_t], :int
      attach_function :sfHttpResponse_getMajorVersion, [:http_response_t], :uint32
      attach_function :sfHttpResponse_getMinorVersion, [:http_response_t], :uint32
      attach_function :sfHttpResponse_getBody,         [:http_response_t], :string

      attach_function :sfHttp_create,        [], :http_t
      attach_function :sfHttp_destroy,       [:http_t], :void
      attach_function :sfHttp_setHost,       [:http_t, :string, :uint16], :void
      # The actual network round-trip — release the GVL so other Ruby
      # threads (timers, audio, even an in-process test server) can run
      # while CSFML is blocked on the socket.
      attach_function :sfHttp_sendRequest,
                      [:http_t, :http_request_t, System::Time.by_value],
                      :http_response_t,
                      blocking: true
    end
  end
end
