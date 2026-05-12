module SFML
  # A streamed audio source. Use this for long tracks (background music) so
  # the file isn't loaded into memory all at once.
  #
  #   bgm = SFML::Music.load("assets/track.ogg", looping: true, volume: 60)
  #   bgm.play
  class Music
    def self.load(path, **opts)
      ptr = C::Audio.sfMusic_createFromFile(path.to_s)
      raise LoadError, "Could not load music from #{path.inspect}" if ptr.null?

      _wrap(ptr, opts)
    end

    # Stream music from a Ruby String of bytes (an in-memory MP3,
    # OGG, FLAC, …). Useful for embedded audio or downloaded
    # tracks that bypass the disk. The bytes must outlive the
    # Music object — SFML keeps a pointer into them.
    def self.from_memory(bytes, **opts)
      raise ArgumentError, "expected a String, got #{bytes.class}" unless bytes.is_a?(String)

      buf = FFI::MemoryPointer.new(:uint8, bytes.bytesize)
      buf.write_bytes(bytes)
      ptr = C::Audio.sfMusic_createFromMemory(buf, bytes.bytesize)
      raise LoadError, "sfMusic_createFromMemory returned NULL — unsupported format?" if ptr.null?

      m = _wrap(ptr, opts)
      m.instance_variable_set(:@_memory_pin, buf)   # keep buffer alive
      m
    end

    # Stream music straight from a Ruby IO-like object. CSFML reads
    # the audio lazily on its decoding thread — keep the IO open
    # until you stop the Music.
    def self.from_stream(io, **opts)
      stream = SFML::InputStream.new(io)
      ptr = C::Audio.sfMusic_createFromStream(stream.to_ptr)
      raise LoadError, "sfMusic_createFromStream returned NULL — unsupported format?" if ptr.null?

      m = _wrap(ptr, opts)
      m.instance_variable_set(:@_stream_pin, stream)
      m.instance_variable_set(:@_io_pin, io)
      m
    end

    # Internal — finish initialising a Music from an already-built
    # CSFML pointer.
    def self._wrap(ptr, opts)
      m = allocate
      m.send(:_take_ownership, ptr)
      m.instance_variable_set(:@looping, false)
      m.volume  = opts[:volume]  if opts.key?(:volume)
      m.pitch   = opts[:pitch]   if opts.key?(:pitch)
      m.looping = opts[:looping] if opts.key?(:looping)
      m
    end
    private_class_method :_wrap

    def play   = C::Audio.sfMusic_play(@handle)
    def pause  = C::Audio.sfMusic_pause(@handle)
    def stop   = C::Audio.sfMusic_stop(@handle)

    def status   = C::Audio::STATUSES[C::Audio.sfMusic_getStatus(@handle)]
    def playing? = status == :playing
    def paused?  = status == :paused
    def stopped? = status == :stopped

    def duration = Time.from_native(C::Audio.sfMusic_getDuration(@handle))

    # Current playback head as a SFML::Time. Reads from the underlying
    # OpenAL source — only meaningful while the music is playing or
    # paused (not after #stop).
    def playing_offset
      Time.from_native(C::Audio.sfMusic_getPlayingOffset(@handle))
    end

    # Seek to `value` (a SFML::Time, or seconds as a Numeric). Works
    # while the music is playing, paused, or stopped.
    def playing_offset=(value)
      t = value.is_a?(Time) ? value : Time.seconds(value.to_f)
      C::Audio.sfMusic_setPlayingOffset(@handle, t.to_native)
    end

    # 3D velocity, Doppler factor, direction, cone — see Sound for
    # the same methods on the simpler buffered source.
    def velocity
      v = C::Audio.sfMusic_getVelocity(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    def velocity=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = vec.x.to_f; packed[:y] = vec.y.to_f; packed[:z] = vec.z.to_f
      C::Audio.sfMusic_setVelocity(@handle, packed)
    end

    def doppler_factor    = C::Audio.sfMusic_getDopplerFactor(@handle)
    def doppler_factor=(v) C::Audio.sfMusic_setDopplerFactor(@handle, v.to_f); end

    def direction
      v = C::Audio.sfMusic_getDirection(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    def direction=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = vec.x.to_f; packed[:y] = vec.y.to_f; packed[:z] = vec.z.to_f
      C::Audio.sfMusic_setDirection(@handle, packed)
    end

    def cone
      SoundCone.from_native(C::Audio.sfMusic_getCone(@handle))
    end

    def cone=(value)
      cone =
        case value
        when SoundCone then value
        when Hash      then SoundCone.new(**value)
        else
          raise ArgumentError, "Music#cone= expects SoundCone or Hash; got #{value.class}"
        end
      C::Audio.sfMusic_setCone(@handle, cone.to_native)
    end

    # See Sound#effect_processor= — same audio-thread DSP callback.
    def effect_processor=(callable)
      @effect_cb = callable.nil? ? nil : Audio._build_effect_processor(callable)
      C::Audio.sfMusic_setEffectProcessor(@handle, @effect_cb, nil)
    end

    # Cached on the Ruby side; see Sound#looping? for the why.
    def looping?
      @looping
    end

    def looping=(value)
      @looping = value ? true : false
      C::Audio.sfMusic_setLooping(@handle, @looping)
    end

    def volume = C::Audio.sfMusic_getVolume(@handle)

    def volume=(value)
      C::Audio.sfMusic_setVolume(@handle, value.to_f)
    end

    def pitch = C::Audio.sfMusic_getPitch(@handle)

    def pitch=(value)
      C::Audio.sfMusic_setPitch(@handle, value.to_f)
    end

    # 3D positional audio — see SFML::Sound for the why.
    def position
      Vector3.from_native(C::Audio.sfMusic_getPosition(@handle))
    end

    def position=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      C::Audio.sfMusic_setPosition(@handle, vec.to_native_f)
    end

    def attenuation = C::Audio.sfMusic_getAttenuation(@handle)

    def attenuation=(value)
      C::Audio.sfMusic_setAttenuation(@handle, value.to_f)
    end

    def min_distance = C::Audio.sfMusic_getMinDistance(@handle)

    def min_distance=(value)
      C::Audio.sfMusic_setMinDistance(@handle, value.to_f)
    end

    def relative_to_listener? = C::Audio.sfMusic_isRelativeToListener(@handle)

    def relative_to_listener=(value)
      C::Audio.sfMusic_setRelativeToListener(@handle, value ? true : false)
    end

    # ---- Stream introspection ----

    def channel_count = C::Audio.sfMusic_getChannelCount(@handle)
    def sample_rate   = C::Audio.sfMusic_getSampleRate(@handle)

    # The portion of the track that loops when `looping = true`.
    # Returns `[offset, length]` of `SFML::Time`s; defaults to the
    # whole track. Set with `loop_points = [Time, Time]`.
    def loop_points
      span = C::Audio.sfMusic_getLoopPoints(@handle)
      [Time.from_native(span[:offset]), Time.from_native(span[:length])]
    end

    def loop_points=(value)
      offset_t, length_t = value
      raise ArgumentError, "expected [offset_time, length_time]" unless offset_t && length_t

      span = C::Audio::TimeSpan.new
      span[:offset][:microseconds] = offset_t.is_a?(Time) ? offset_t.microseconds : Time.seconds(offset_t.to_f).microseconds
      span[:length][:microseconds] = length_t.is_a?(Time) ? length_t.microseconds : Time.seconds(length_t.to_f).microseconds
      C::Audio.sfMusic_setLoopPoints(@handle, span)
    end

    # ---- 3D-audio extras (mirror of Sound's) ----

    def pan = C::Audio.sfMusic_getPan(@handle)

    def pan=(v)
      C::Audio.sfMusic_setPan(@handle, v.to_f)
    end

    def min_gain = C::Audio.sfMusic_getMinGain(@handle)

    def min_gain=(v)
      C::Audio.sfMusic_setMinGain(@handle, v.to_f)
    end

    def max_gain = C::Audio.sfMusic_getMaxGain(@handle)

    def max_gain=(v)
      C::Audio.sfMusic_setMaxGain(@handle, v.to_f)
    end

    def max_distance = C::Audio.sfMusic_getMaxDistance(@handle)

    def max_distance=(v)
      C::Audio.sfMusic_setMaxDistance(@handle, v.to_f)
    end

    def spatialization_enabled? = C::Audio.sfMusic_isSpatializationEnabled(@handle)

    def spatialization_enabled=(v)
      C::Audio.sfMusic_setSpatializationEnabled(@handle, v ? true : false)
    end

    def directional_attenuation_factor
      C::Audio.sfMusic_getDirectionalAttenuationFactor(@handle)
    end

    def directional_attenuation_factor=(v)
      C::Audio.sfMusic_setDirectionalAttenuationFactor(@handle, v.to_f)
    end

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfMusic_destroy))
    end
  end
end
