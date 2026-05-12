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
      raise AudioError, "sfSoundStream_create returned NULL" if ptr.null?

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

    # Start streaming. Triggers the audio thread to start polling
    # `#on_get_data` for chunks. Returns self.
    def play  = (C::Audio.sfSoundStream_play(@handle); self)
    # Pause streaming. `#play` resumes from here.
    def pause = (C::Audio.sfSoundStream_pause(@handle); self)
    # Stop streaming and reset internal state.
    def stop  = (C::Audio.sfSoundStream_stop(@handle); self)

    # Playback state — `:stopped`, `:paused`, or `:playing`.
    def status      = C::Audio::STATUSES[C::Audio.sfSoundStream_getStatus(@handle)]
    # `status == :playing`.
    def playing?    = status == :playing
    # `status == :paused`.
    def paused?     = status == :paused
    # `status == :stopped`.
    def stopped?    = status == :stopped

    # Channel count this stream produces (1 = mono, 2 = stereo).
    def channel_count = C::Audio.sfSoundStream_getChannelCount(@handle)
    # Sample rate in Hz.
    def sample_rate   = C::Audio.sfSoundStream_getSampleRate(@handle)

    # Cached on the Ruby side; some OpenAL backends (notably the
    # headless null sink we get on Linux CI) don't reliably read
    # the loop flag back through CSFML once it's been set.
    def looping?
      @looping == true
    end

    # Toggle looping playback.
    def looping=(value)
      @looping = !!value
      C::Audio.sfSoundStream_setLooping(@handle, @looping)
    end

    # Playback volume in [0, 100].
    def volume = C::Audio.sfSoundStream_getVolume(@handle)

    # Set the volume.
    def volume=(value)
      C::Audio.sfSoundStream_setVolume(@handle, value.to_f)
    end

    # Pitch multiplier. 1.0 = normal.
    def pitch = C::Audio.sfSoundStream_getPitch(@handle)

    # Set the pitch.
    def pitch=(value)
      C::Audio.sfSoundStream_setPitch(@handle, value.to_f)
    end

    # Current playback head as `SFML::Time`.
    def playing_offset
      Time.from_native(C::Audio.sfSoundStream_getPlayingOffset(@handle))
    end

    # Seek to `value` (`SFML::Time` or numeric seconds). Triggers
    # `#on_seek` on the subclass.
    def playing_offset=(value)
      t = value.is_a?(Time) ? value : Time.seconds(value.to_f)
      C::Audio.sfSoundStream_setPlayingOffset(@handle, t.to_native)
    end

    # 3D position as a Vector3.
    def position
      v = C::Audio.sfSoundStream_getPosition(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    # Set the 3D position — accepts Vector3 or `[x, y, z]`.
    def position=(value)
      v = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = v.x.to_f; packed[:y] = v.y.to_f; packed[:z] = v.z.to_f
      C::Audio.sfSoundStream_setPosition(@handle, packed)
    end

    # Falloff sharpness with distance — see `Sound#attenuation`.
    def attenuation = C::Audio.sfSoundStream_getAttenuation(@handle)

    # Set the attenuation.
    def attenuation=(value)
      C::Audio.sfSoundStream_setAttenuation(@handle, value.to_f)
    end

    # Distance below which volume is not attenuated.
    def min_distance = C::Audio.sfSoundStream_getMinDistance(@handle)

    # Set the min-distance.
    def min_distance=(value)
      C::Audio.sfSoundStream_setMinDistance(@handle, value.to_f)
    end

    # `true` if `#position` is interpreted relative to the listener.
    def relative_to_listener? = C::Audio.sfSoundStream_isRelativeToListener(@handle)

    # Toggle listener-relative positioning.
    def relative_to_listener=(value)
      C::Audio.sfSoundStream_setRelativeToListener(@handle, !!value)
    end

    # ---- 3D-audio surface (mirror of Sound / Music) -------------------

    # Stereo pan in [-1.0, 1.0].
    def pan = C::Audio.sfSoundStream_getPan(@handle)

    # Set the stereo pan.
    def pan=(value)
      C::Audio.sfSoundStream_setPan(@handle, value.to_f)
    end

    # Distance beyond which the source is fully attenuated.
    def max_distance = C::Audio.sfSoundStream_getMaxDistance(@handle)

    # Set the max-distance.
    def max_distance=(value)
      C::Audio.sfSoundStream_setMaxDistance(@handle, value.to_f)
    end

    # Lower gain bound.
    def min_gain = C::Audio.sfSoundStream_getMinGain(@handle)

    # Set the min-gain floor.
    def min_gain=(value)
      C::Audio.sfSoundStream_setMinGain(@handle, value.to_f)
    end

    # Upper gain bound.
    def max_gain = C::Audio.sfSoundStream_getMaxGain(@handle)

    # Set the max-gain cap.
    def max_gain=(value)
      C::Audio.sfSoundStream_setMaxGain(@handle, value.to_f)
    end

    # `true` if 3D positional / Doppler / cone math is applied.
    def spatialization_enabled? = C::Audio.sfSoundStream_isSpatializationEnabled(@handle)

    # Toggle 3D spatialisation.
    def spatialization_enabled=(value)
      C::Audio.sfSoundStream_setSpatializationEnabled(@handle, !!value)
    end

    # The direction vector for the cone.
    def direction
      v = C::Audio.sfSoundStream_getDirection(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    # Set the direction — accepts Vector3 or `[x, y, z]`.
    def direction=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = vec.x.to_f; packed[:y] = vec.y.to_f; packed[:z] = vec.z.to_f
      C::Audio.sfSoundStream_setDirection(@handle, packed)
    end

    # Directional-attenuation cone.
    def cone
      SoundCone.from_native(C::Audio.sfSoundStream_getCone(@handle))
    end

    # Set the cone. Accepts a `SoundCone` or Hash.
    def cone=(value)
      cone =
        case value
        when SoundCone then value
        when Hash      then SoundCone.new(**value)
        else
          raise ArgumentError, "SoundStream#cone= expects SoundCone or Hash; got #{value.class}"
        end
      C::Audio.sfSoundStream_setCone(@handle, cone.to_native)
    end

    # 3D velocity in world units / second.
    def velocity
      v = C::Audio.sfSoundStream_getVelocity(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    # Set the velocity — accepts Vector3 or `[x, y, z]`.
    def velocity=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = vec.x.to_f; packed[:y] = vec.y.to_f; packed[:z] = vec.z.to_f
      C::Audio.sfSoundStream_setVelocity(@handle, packed)
    end

    # Per-source Doppler scale.
    def doppler_factor = C::Audio.sfSoundStream_getDopplerFactor(@handle)

    # Set the Doppler factor.
    def doppler_factor=(value)
      C::Audio.sfSoundStream_setDopplerFactor(@handle, value.to_f)
    end

    # Multiplier on the Listener's directional attenuation cone.
    def directional_attenuation_factor
      C::Audio.sfSoundStream_getDirectionalAttenuationFactor(@handle)
    end

    # Set the directional-attenuation factor.
    def directional_attenuation_factor=(value)
      C::Audio.sfSoundStream_setDirectionalAttenuationFactor(@handle, value.to_f)
    end

    # Install a real-time DSP filter (same contract as Sound /
    # Music — see Sound#effect_processor=). Pass `nil` to remove.
    def effect_processor=(callable)
      @effect_cb = callable.nil? ? nil : Audio._build_effect_processor(callable)
      C::Audio.sfSoundStream_setEffectProcessor(@handle, @effect_cb, nil)
    end

    # The channel layout the stream is producing, as an Array of
    # `sfSoundChannel` enum values (1 = Mono, 2 = FrontLeft,
    # 3 = FrontRight, etc — see SoundBuffer::DEFAULT_CHANNEL_MAPS).
    def channel_map
      count_buf = FFI::MemoryPointer.new(:size_t)
      ptr = C::Audio.sfSoundStream_getChannelMap(@handle, count_buf)
      n = count_buf.read(:size_t)
      return [] if ptr.null? || n.zero?
      ptr.read_array_of_int32(n)
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
