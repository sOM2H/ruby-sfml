module SFML
  # Decoded audio data held in memory. Use it to back one or more Sound
  # instances. Loaded from .wav, .ogg, .flac, .mp3 (depends on CSFML build).
  #
  #   buffer = SFML::SoundBuffer.load("assets/blip.wav")
  #   sound  = SFML::Sound.new(buffer)
  #   sound.play
  class SoundBuffer
    def self.load(path)
      ptr = C::Audio.sfSoundBuffer_createFromFile(path.to_s)
      raise Error, "Could not load sound buffer from #{path.inspect}" if ptr.null?
      buf = allocate
      buf.send(:_take_ownership, ptr)
      buf
    end

    # Decode a Ruby String of bytes (.wav, .ogg, .flac, …)
    # straight into a buffer — bypass the disk.
    def self.from_memory(bytes)
      raise ArgumentError, "expected a String, got #{bytes.class}" unless bytes.is_a?(String)

      buf_p = FFI::MemoryPointer.new(:uint8, bytes.bytesize)
      buf_p.write_bytes(bytes)
      ptr = C::Audio.sfSoundBuffer_createFromMemory(buf_p, bytes.bytesize)
      raise Error, "sfSoundBuffer_createFromMemory returned NULL — unsupported format?" if ptr.null?

      buf = allocate
      buf.send(:_take_ownership, ptr)
      buf
    end

    # Load fully-decoded audio from any Ruby IO-like object. The
    # whole stream is decoded into RAM — for streaming playback,
    # use `Music.from_stream` instead.
    def self.from_stream(io)
      stream = SFML::InputStream.new(io)
      ptr = C::Audio.sfSoundBuffer_createFromStream(stream.to_ptr)
      raise Error, "sfSoundBuffer_createFromStream returned NULL — unsupported format?" if ptr.null?

      buf = allocate
      buf.send(:_take_ownership, ptr)
      buf
    end

    # Default channel-layout map for the common 1- and 2-channel
    # cases — saves callers from spelling out the SoundChannel
    # enum just to build a mono blip or stereo waveform.
    DEFAULT_CHANNEL_MAPS = {
      1 => [1],          # sfSoundChannelMono
      2 => [2, 3],       # sfSoundChannelFrontLeft, FrontRight
    }.freeze

    # Build a buffer from raw 16-bit signed samples. `samples` is
    # an Array of Integers in [-32768, 32767]. The caller specifies
    # `sample_rate` (Hz) and `channel_count` (1 = mono, 2 = stereo).
    # `channel_map` is an Array of `sfSoundChannel` enum values; for
    # 1- and 2-channel content the default mono / front-L+R layout
    # is filled in automatically.
    def self.from_samples(samples, sample_rate:, channel_count:, channel_map: nil)
      arr = samples.to_a.map { |s| Integer(s) }
      buf = FFI::MemoryPointer.new(:int16, arr.length)
      buf.write_array_of_int16(arr)

      map = channel_map || DEFAULT_CHANNEL_MAPS.fetch(channel_count) do
        raise ArgumentError,
              "no default channel_map for #{channel_count} channels — pass `channel_map: [...]` explicitly"
      end
      map_buf = FFI::MemoryPointer.new(:int, map.length)
      map_buf.write_array_of_int(map.map { |v| Integer(v) })

      ptr = C::Audio.sfSoundBuffer_createFromSamples(buf, arr.length,
                                                     Integer(channel_count),
                                                     Integer(sample_rate),
                                                     map_buf, map.length)
      raise Error, "sfSoundBuffer_createFromSamples returned NULL" if ptr.null?

      sb = allocate
      sb.send(:_take_ownership, ptr)
      sb
    end

    def duration      = Time.from_native(C::Audio.sfSoundBuffer_getDuration(@handle))
    def sample_rate   = C::Audio.sfSoundBuffer_getSampleRate(@handle)
    def channel_count = C::Audio.sfSoundBuffer_getChannelCount(@handle)
    def sample_count  = C::Audio.sfSoundBuffer_getSampleCount(@handle)

    # The decoded 16-bit signed samples as a Ruby Array of
    # Integers. Heavy — copies every sample. For analysis or
    # custom DSP that needs the raw waveform.
    def samples
      ptr = C::Audio.sfSoundBuffer_getSamples(@handle)
      return [] if ptr.null?
      ptr.read_array_of_int16(sample_count)
    end

    # Independent copy — same decoded waveform, different
    # underlying memory block.
    def dup
      ptr = C::Audio.sfSoundBuffer_copy(@handle)
      raise Error, "sfSoundBuffer_copy returned NULL" if ptr.null?

      copy = self.class.allocate
      copy.send(:_take_ownership, ptr)
      copy
    end
    alias clone dup

    # Write the buffer out to disk. Format is inferred from the file
    # extension (.wav / .ogg / .flac, depends on what CSFML was built
    # with).
    def save(path)
      ok = C::Audio.sfSoundBuffer_saveToFile(@handle, path.to_s)
      raise Error, "could not save SoundBuffer to #{path.inspect}" unless ok
      path
    end

    attr_reader :handle # :nodoc:

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfSoundBuffer_destroy))
    end
  end
end
