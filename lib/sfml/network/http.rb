module SFML
  module Network
    # CSFML's tiny HTTP/1.x client. Useful when an SFML 3 game wants
    # to talk to a leaderboard / asset server without pulling in
    # `Net::HTTP`. For anything more involved (TLS, redirects,
    # streaming, retries, JSON), Ruby's stdlib `Net::HTTP` is the
    # better tool — this wrapper exists for parity with CSFML, not
    # because we recommend it.
    #
    #   http = SFML::Network::Http.new("http://localhost", port: 8080)
    #   resp = http.send_request(method: :get, uri: "/")
    #   resp.status   #=> 200
    #   resp.body     #=> "Hello world\n"
    #
    # `send_request` accepts:
    #   method:       :get / :post / :head / :put / :delete (default :get)
    #   uri:          path string (default "/")
    #   fields:       Hash of header name → value
    #   body:         String body (POST/PUT)
    #   http_version: [major, minor] (default [1, 0])
    #   timeout:      SFML::Time or seconds (default 0 = no timeout)
    class Http
      # Default per-call timeout.
      DEFAULT_TIMEOUT = SFML::Time.zero
      DEFAULT_VERSION = [1, 0].freeze

      # Build an HTTP client pinned to `host` (URL prefix). Pass
      # `port: 0` to let CSFML pick the protocol's default port.
      def initialize(host, port: 0)
        ptr = C::Network.sfHttp_create
        raise NetworkError, "sfHttp_create returned NULL" if ptr.null?

        @handle = FFI::AutoPointer.new(ptr, C::Network.method(:sfHttp_destroy))
        C::Network.sfHttp_setHost(@handle, host.to_s, Integer(port))
      end

      # Send a request and wait for the response. See the class doc
      # for all the kwargs.
      def send_request(method: :get, uri: "/", fields: nil, body: nil,
                       http_version: DEFAULT_VERSION, timeout: DEFAULT_TIMEOUT)
        request_ptr = C::Network.sfHttpRequest_create
        raise NetworkError, "sfHttpRequest_create returned NULL" if request_ptr.null?

        begin
          method_idx = C::Network::HTTP_METHODS.index(method) ||
            raise(ArgumentError, "Unknown HTTP method: #{method.inspect} " \
                                 "(expected one of #{C::Network::HTTP_METHODS.inspect})")
          C::Network.sfHttpRequest_setMethod(request_ptr, method_idx)
          C::Network.sfHttpRequest_setUri(request_ptr, uri.to_s)
          C::Network.sfHttpRequest_setHttpVersion(request_ptr, Integer(http_version[0]), Integer(http_version[1]))
          C::Network.sfHttpRequest_setBody(request_ptr, body.to_s) if body
          fields&.each_pair do |name, value|
            C::Network.sfHttpRequest_setField(request_ptr, name.to_s, value.to_s)
          end

          t = timeout.is_a?(Time) ? timeout : Time.seconds(timeout.to_f)
          response_ptr = C::Network.sfHttp_sendRequest(@handle, request_ptr, t.to_native)
          raise NetworkError, "sfHttp_sendRequest returned NULL" if response_ptr.null?

          Response.send(:_take_ownership, response_ptr)
        ensure
          C::Network.sfHttpRequest_destroy(request_ptr)
        end
      end

      attr_reader :handle # :nodoc:

      # Read-only view onto a CSFML sfHttpResponse. Wraps the C pointer
      # in a Ruby object that destroys the response when GC'd.
      class Response
        # Status mappings — most map onto standard HTTP codes; the four
        # at the bottom are SFML-side transport errors above the
        # standard range (≥ 1000).
        STATUS_NAMES = {
          200 => :ok, 201 => :created, 202 => :accepted, 204 => :no_content,
          205 => :reset_content, 206 => :partial_content,
          301 => :multiple_choices, 302 => :moved_permanently, 303 => :moved_temporarily,
          304 => :not_modified,
          400 => :bad_request, 401 => :unauthorized, 403 => :forbidden, 404 => :not_found,
          405 => :range_not_satisfiable,
          500 => :internal_server_error, 501 => :not_implemented, 502 => :bad_gateway,
          503 => :service_not_available, 504 => :gateway_timeout, 505 => :version_not_supported,
          1000 => :invalid_response, 1001 => :connection_failed,
        }.freeze

        # Responses are created via `Http#send_request`, not directly.
        def initialize
          raise NoMethodError, "use SFML::Network::Http#send_request to create a Response"
        end

        # Numeric HTTP status code (200, 404, ...). Combine with
        # `STATUS_NAMES` or use `#status_symbol`.
        def status
          C::Network.sfHttpResponse_getStatus(@handle)
        end

        # The status as a symbol when CSFML maps it, otherwise the
        # raw integer. Useful for `case resp.status_symbol in :ok`.
        def status_symbol
          STATUS_NAMES[status] || status
        end

        # Response body as a Ruby String.
        def body  = C::Network.sfHttpResponse_getBody(@handle).to_s
        # Look up a response header by name (case-insensitive in HTTP).
        def field(name) = C::Network.sfHttpResponse_getField(@handle, name.to_s)

        # HTTP version the server replied with, as `[major, minor]`.
        def http_version
          [
            C::Network.sfHttpResponse_getMajorVersion(@handle),
            C::Network.sfHttpResponse_getMinorVersion(@handle),
          ]
        end

        attr_reader :handle # :nodoc:

        # @!visibility private
        def self._take_ownership(ptr)
          obj = allocate
          obj.instance_variable_set(:@handle,
            FFI::AutoPointer.new(ptr, C::Network.method(:sfHttpResponse_destroy)))
          obj
        end
      end
    end
  end
end
