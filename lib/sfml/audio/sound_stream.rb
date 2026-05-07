module SFML
  # Procedural audio source. Subclass it and override `#on_get_data`
  # to fill each chunk on demand — CSFML invokes the callback from
  # its audio thread whenever the sound queue runs low.
  #
  # `#on_get_data` returns either:
  #   * an Array (or anything responding to `#to_a`) of Int16 PCM
  #     samples — they're packed into a buffer and handed to CSFML;
  #   * `nil` to stop the stream.
  #
  # Override `#on_seek(time)` to support `playing_offset=`. Default
  # is a no-op (the next callback continues from wherever the
  # subclass internal state happens to be).
  #
  #   class SineWave < SFML::SoundStream
  #     def initialize(freq:, sample_rate: 44_100)
  #       super(channel_count: 1, sample_rate: sample_rate)
  #       @freq, @sample_rate = freq, sample_rate
  #       @phase = 0.0
  #     end
  #
  #     def on_get_data
  #       n = @sample_rate / 10   # ~100ms chunks
  #       step = 2 * Math::PI * @freq / @sample_rate
  #       Array.new(n) do
  #         s = (Math.sin(@phase) * 30_000).to_i
  #         @phase = (@phase + step) % (2 * Math::PI)
  #         s
  #       end
  #     end
  #
  #     def on_seek(time)
  #       @phase = 0.0
  #     end
  #   end
  #
  # CAVEATS
  # * The callback runs on the SFML audio thread; doing heavy work
  #   there will glitch the audio. Generate samples and return.
  # * Ruby threads still need the GVL — your callback acquires it
  #   each invocation. Long Ruby work on the main thread can starve
  #   the audio thread and produce dropouts.
  # * Always keep a reference to the SoundStream object (assign to a
  #   variable, store in an instance var). If the Ruby object is GC'd
  #   while CSFML is still calling callbacks, the process crashes.
  class SoundStream
    DEFAULT_CHUNK_FRAMES = 4096

    def initialize(channel_count:, sample_rate:)
      raise ArgumentError, "channel_count must be >= 1" if channel_count < 1
      raise ArgumentError, "sample_rate must be > 0"    if sample_rate < 1

      # Hold strong refs so neither GC nor reload disposes the
      # callbacks while CSFML is still calling them.
      @get_data_cb = FFI::Function.new(:bool, [:pointer, :pointer]) do |chunk_ptr, _user|
        _on_get_data_callback(chunk_ptr)
      end
      @seek_cb = FFI::Function.new(:void, [C::System::Time.by_value, :pointer]) do |time, _user|
        on_seek(Time.from_native(time))
        nil
      end

      ptr = C::Audio.sfSoundStream_create(
        @get_data_cb, @seek_cb,
        Integer(channel_count), Integer(sample_rate),
        nil, 0,
        nil,
      )
      raise Error, "sfSoundStream_create returned NULL" if ptr.null?

      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfSoundStream_destroy))

      # We re-use a single MemoryPointer for the sample buffer,
      # growing it on demand. CSFML reads from the pointer between
      # callbacks, then asks for the next chunk — by the time we
      # overwrite, CSFML is done with the previous data.
      @sample_buffer = nil
      @sample_buffer_capacity = 0
    end

    # ---- Subclass hooks ------------------------------------------------

    # Return an Array of Int16 PCM samples (interleaved if multi-channel),
    # or `nil` to stop the stream. Default raises so subclasses must
    # implement it.
    def on_get_data
      raise NoMethodError, "#{self.class} must override #on_get_data"
    end

    # Called when the user changes the playing offset. Default is a
    # no-op — override if your stream tracks position internally
    # (counters, file offsets, etc.).
    def on_seek(_time); end

    # ---- Public playback API ------------------------------------------

    def play  = (C::Audio.sfSoundStream_play(@handle); self)
    def pause = (C::Audio.sfSoundStream_pause(@handle); self)
    def stop  = (C::Audio.sfSoundStream_stop(@handle); self)

    def status      = C::Audio::STATUSES[C::Audio.sfSoundStream_getStatus(@handle)]
    def playing?    = status == :playing
    def paused?     = status == :paused
    def stopped?    = status == :stopped

    def channel_count = C::Audio.sfSoundStream_getChannelCount(@handle)
    def sample_rate   = C::Audio.sfSoundStream_getSampleRate(@handle)

    # Cached on the Ruby side; some OpenAL backends (notably the
    # headless null sink we get on Linux CI) don't reliably read
    # the loop flag back through CSFML once it's been set.
    def looping?
      @looping == true
    end

    def looping=(value)
      @looping = !!value
      C::Audio.sfSoundStream_setLooping(@handle, @looping)
    end

    def volume = C::Audio.sfSoundStream_getVolume(@handle)

    def volume=(value)
      C::Audio.sfSoundStream_setVolume(@handle, value.to_f)
    end

    def pitch = C::Audio.sfSoundStream_getPitch(@handle)

    def pitch=(value)
      C::Audio.sfSoundStream_setPitch(@handle, value.to_f)
    end

    def playing_offset
      Time.from_native(C::Audio.sfSoundStream_getPlayingOffset(@handle))
    end

    def playing_offset=(value)
      t = value.is_a?(Time) ? value : Time.seconds(value.to_f)
      C::Audio.sfSoundStream_setPlayingOffset(@handle, t.to_native)
    end

    def position
      v = C::Audio.sfSoundStream_getPosition(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    def position=(value)
      v = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = v.x.to_f; packed[:y] = v.y.to_f; packed[:z] = v.z.to_f
      C::Audio.sfSoundStream_setPosition(@handle, packed)
    end

    def attenuation = C::Audio.sfSoundStream_getAttenuation(@handle)

    def attenuation=(value)
      C::Audio.sfSoundStream_setAttenuation(@handle, value.to_f)
    end

    def min_distance = C::Audio.sfSoundStream_getMinDistance(@handle)

    def min_distance=(value)
      C::Audio.sfSoundStream_setMinDistance(@handle, value.to_f)
    end

    def relative_to_listener? = C::Audio.sfSoundStream_isRelativeToListener(@handle)

    def relative_to_listener=(value)
      C::Audio.sfSoundStream_setRelativeToListener(@handle, !!value)
    end

    attr_reader :handle # :nodoc:

    private

    # Bridge between CSFML's chunk struct and our user-facing
    # `#on_get_data`. Runs on the audio thread.
    def _on_get_data_callback(chunk_ptr)
      samples = on_get_data
      chunk = C::Audio::SoundStreamChunk.new(chunk_ptr)

      if samples.nil?
        chunk[:samples]      = FFI::Pointer::NULL
        chunk[:sample_count] = 0
        return false
      end

      arr = samples.respond_to?(:to_a) ? samples.to_a : samples
      n   = arr.length

      _grow_sample_buffer(n)
      @sample_buffer.write_array_of_int16(arr) if n > 0

      chunk[:samples]      = @sample_buffer
      chunk[:sample_count] = n
      true
    end

    def _grow_sample_buffer(n)
      return if @sample_buffer && @sample_buffer_capacity >= n

      @sample_buffer_capacity = [n, DEFAULT_CHUNK_FRAMES].max
      @sample_buffer          = FFI::MemoryPointer.new(:int16, @sample_buffer_capacity)
    end
  end
end
