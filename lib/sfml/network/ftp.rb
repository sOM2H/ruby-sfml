module SFML
  module Network
    # CSFML's FTP client. Useful for the rare game that needs to fetch
    # extra content from a plain-FTP server. For anything modern,
    # Ruby's stdlib `Net::FTP` (and the Net::FTP gem) is a much nicer
    # tool — this binding exists for parity with CSFML.
    #
    #   ftp = SFML::Network::Ftp.new
    #   ftp.connect("ftp.example.com").ok?      #=> true
    #   ftp.login_anonymous.ok?                  #=> true
    #   ftp.directory_listing("/").names         #=> ["pub", "incoming", ...]
    #   ftp.download("/pub/file.bin", "/tmp/")
    #   ftp.disconnect
    #
    # Each call returns a Response (or DirectoryResponse / ListingResponse
    # for commands that return a path or a list). All responses expose
    # `#ok?`, `#status` (Integer), `#status_symbol`, `#message`.
    class Ftp
      DEFAULT_PORT    = 21
      DEFAULT_TIMEOUT = SFML::Time.zero

      # FTP status codes mapped to symbols. The transport-error ones
      # at ≥ 1000 are SFML's, not RFC 959.
      STATUS_NAMES = {
        110 => :restart_marker_reply, 120 => :service_ready_soon,
        125 => :data_connection_already_opened, 150 => :opening_data_connection,
        200 => :ok, 211 => :system_status, 212 => :directory_status,
        213 => :file_status, 214 => :help_message,
        215 => :system_type, 220 => :service_ready, 221 => :closing_connection,
        225 => :data_connection_opened, 226 => :closing_data_connection,
        227 => :entering_passive_mode, 230 => :logged_in,
        250 => :file_action_ok, 257 => :directory_ok,
        331 => :need_password, 332 => :need_account_to_log_in,
        350 => :need_information,
        421 => :service_unavailable, 425 => :data_connection_unavailable,
        426 => :transfer_aborted, 450 => :file_action_aborted,
        451 => :local_error, 452 => :insufficient_storage_space,
        500 => :command_unknown, 501 => :parameters_unknown,
        502 => :command_not_implemented, 503 => :bad_command_sequence,
        504 => :parameter_not_implemented, 530 => :not_logged_in,
        532 => :need_account_to_store, 550 => :file_unavailable,
        551 => :page_type_unknown, 552 => :not_enough_memory,
        553 => :filename_not_allowed,
        1000 => :invalid_response, 1001 => :connection_failed,
        1002 => :connection_closed, 1003 => :invalid_file,
      }.freeze

      def initialize
        ptr = C::Network.sfFtp_create
        raise Error, "sfFtp_create returned NULL" if ptr.null?

        @handle = FFI::AutoPointer.new(ptr, C::Network.method(:sfFtp_destroy))
      end

      # Connect to an FTP server. `host` may be an IP string ("1.2.3.4")
      # or hostname ("ftp.example.com"); pass timeout as a SFML::Time
      # or numeric seconds (default 0 = no timeout).
      def connect(host, port: DEFAULT_PORT, timeout: DEFAULT_TIMEOUT)
        addr = IpAddress.from_string(host).struct
        t    = timeout.is_a?(Time) ? timeout : Time.seconds(timeout.to_f)
        Response._take_ownership(C::Network.sfFtp_connect(@handle, addr, Integer(port), t.to_native))
      end

      def login_anonymous
        Response._take_ownership(C::Network.sfFtp_loginAnonymous(@handle))
      end

      def login(user, password)
        Response._take_ownership(C::Network.sfFtp_login(@handle, user.to_s, password.to_s))
      end

      def disconnect = Response._take_ownership(C::Network.sfFtp_disconnect(@handle))
      def keep_alive = Response._take_ownership(C::Network.sfFtp_keepAlive(@handle))

      def working_directory
        DirectoryResponse._take_ownership(C::Network.sfFtp_getWorkingDirectory(@handle))
      end

      def directory_listing(directory = "")
        ListingResponse._take_ownership(C::Network.sfFtp_getDirectoryListing(@handle, directory.to_s))
      end

      def change_directory(directory)
        Response._take_ownership(C::Network.sfFtp_changeDirectory(@handle, directory.to_s))
      end

      def parent_directory
        Response._take_ownership(C::Network.sfFtp_parentDirectory(@handle))
      end

      def create_directory(name)
        DirectoryResponse._take_ownership(C::Network.sfFtp_createDirectory(@handle, name.to_s))
      end

      def delete_directory(name)
        Response._take_ownership(C::Network.sfFtp_deleteDirectory(@handle, name.to_s))
      end

      def rename_file(file, new_name)
        Response._take_ownership(C::Network.sfFtp_renameFile(@handle, file.to_s, new_name.to_s))
      end

      def delete_file(name)
        Response._take_ownership(C::Network.sfFtp_deleteFile(@handle, name.to_s))
      end

      def download(remote, local, mode: :binary)
        idx = C::Network::FTP_TRANSFER_MODES.index(mode) ||
          raise(ArgumentError, "Unknown FTP transfer mode: #{mode.inspect}")
        Response._take_ownership(C::Network.sfFtp_download(@handle, remote.to_s, local.to_s, idx))
      end

      def upload(local, remote, mode: :binary, append: false)
        idx = C::Network::FTP_TRANSFER_MODES.index(mode) ||
          raise(ArgumentError, "Unknown FTP transfer mode: #{mode.inspect}")
        Response._take_ownership(C::Network.sfFtp_upload(@handle, local.to_s, remote.to_s, idx, !!append))
      end

      def send_command(command, parameter = "")
        Response._take_ownership(C::Network.sfFtp_sendCommand(@handle, command.to_s, parameter.to_s))
      end

      attr_reader :handle # :nodoc:

      # Generic response: most FTP operations return this.
      class Response
        def ok?           = C::Network.sfFtpResponse_isOk(@handle)
        def status        = C::Network.sfFtpResponse_getStatus(@handle)
        def status_symbol = STATUS_NAMES[status] || status
        def message       = C::Network.sfFtpResponse_getMessage(@handle).to_s
        attr_reader :handle # :nodoc:

        # @!visibility private
        def self._take_ownership(ptr)
          obj = allocate
          obj.instance_variable_set(:@handle,
            FFI::AutoPointer.new(ptr, C::Network.method(:sfFtpResponse_destroy)))
          obj
        end
      end

      # Returned by working_directory and create_directory — adds the
      # `#directory` accessor on top of Response.
      class DirectoryResponse
        def ok?           = C::Network.sfFtpDirectoryResponse_isOk(@handle)
        def status        = C::Network.sfFtpDirectoryResponse_getStatus(@handle)
        def status_symbol = STATUS_NAMES[status] || status
        def message       = C::Network.sfFtpDirectoryResponse_getMessage(@handle).to_s
        def directory     = C::Network.sfFtpDirectoryResponse_getDirectory(@handle).to_s
        attr_reader :handle # :nodoc:

        # @!visibility private
        def self._take_ownership(ptr)
          obj = allocate
          obj.instance_variable_set(:@handle,
            FFI::AutoPointer.new(ptr, C::Network.method(:sfFtpDirectoryResponse_destroy)))
          obj
        end
      end

      # Returned by directory_listing — adds the `#names` array.
      class ListingResponse
        def ok?           = C::Network.sfFtpListingResponse_isOk(@handle)
        def status        = C::Network.sfFtpListingResponse_getStatus(@handle)
        def status_symbol = STATUS_NAMES[status] || status
        def message       = C::Network.sfFtpListingResponse_getMessage(@handle).to_s
        def count         = C::Network.sfFtpListingResponse_getCount(@handle)
        attr_reader :handle # :nodoc:

        def names
          Array.new(count) { |i| C::Network.sfFtpListingResponse_getName(@handle, i).to_s }
        end

        # @!visibility private
        def self._take_ownership(ptr)
          obj = allocate
          obj.instance_variable_set(:@handle,
            FFI::AutoPointer.new(ptr, C::Network.method(:sfFtpListingResponse_destroy)))
          obj
        end
      end
    end
  end
end
