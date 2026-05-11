module SFML
  # Bridge between a Ruby IO-like object (anything with `#read(n)`,
  # `#seek(pos)`, `#pos` / `#tell`, and `#size`) and CSFML's
  # `sfInputStream*` parameter on `*_createFromStream` loader
  # functions.
  #
  # Typical use is indirect — pass a Ruby IO to the
  # `.from_stream` factory on Font, Image, Texture, Shader, Music,
  # or SoundBuffer:
  #
  #   File.open("assets/hero.png", "rb") do |io|
  #     tex = SFML::Texture.from_stream(io)
  #   end
  #
  # Direct use is for advanced cases (custom virtual filesystems,
  # network streams, etc.). Subclass or build with `.new(io)`:
  #
  #   wrapped = SFML::InputStream.new(my_random_access_io)
  #   font    = SFML::Font.send(:_load_from_stream_handle, wrapped.struct)
  #
  # The InputStream object must outlive the loader call — keep a
  # reference until the CSFML factory returns. The wrapped IO is
  # not closed automatically; close it yourself.
  class InputStream
    # `io` must respond to: read(n), seek(pos, IO::SEEK_SET), pos/tell, size.
    # Ruby's File, StringIO, and Tempfile all qualify.
    def initialize(io)
      @io = io

      # Strong refs so the GC doesn't free our callbacks before CSFML
      # is done with the struct. CSFML calls them synchronously
      # during the loader function, but may also call them later
      # (Music streams from disk on its audio thread).
      @read_cb = FFI::Function.new(:int64, [:pointer, :size_t, :pointer]) do |buf, size, _user|
        begin
          bytes = @io.read(size) || ""
          buf.write_bytes(bytes) unless bytes.empty?
          bytes.bytesize
        rescue StandardError
          -1
        end
      end

      @seek_cb = FFI::Function.new(:int64, [:size_t, :pointer]) do |pos, _user|
        begin
          @io.seek(pos, IO::SEEK_SET)
          pos
        rescue StandardError
          -1
        end
      end

      @tell_cb = FFI::Function.new(:int64, [:pointer]) do |_user|
        begin
          @io.respond_to?(:pos) ? @io.pos : @io.tell
        rescue StandardError
          -1
        end
      end

      @size_cb = FFI::Function.new(:int64, [:pointer]) do |_user|
        begin
          @io.size
        rescue StandardError
          -1
        end
      end

      @struct = C::System::InputStream.new
      @struct[:read]      = @read_cb
      @struct[:seek]      = @seek_cb
      @struct[:tell]      = @tell_cb
      @struct[:get_size]  = @size_cb
      @struct[:user_data] = FFI::Pointer::NULL
    end

    # @!visibility private
    def struct
      @struct
    end

    # Pointer suitable for the `sfInputStream*` parameter on
    # `*_createFromStream` loaders.
    def to_ptr
      @struct.pointer
    end
  end
end
