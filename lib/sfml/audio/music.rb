module SFML
  # A streamed audio source. Use this for long tracks (background music) so
  # the file isn't loaded into memory all at once.
  #
  #   bgm = SFML::Music.load("assets/track.ogg", looping: true, volume: 60)
  #   bgm.play
  class Music
    def self.load(path, **opts)
      ptr = C::Audio.sfMusic_createFromFile(path.to_s)
      raise Error, "Could not load music from #{path.inspect}" if ptr.null?

      m = allocate
      m.send(:_take_ownership, ptr)
      m.instance_variable_set(:@looping, false)
      m.volume  = opts[:volume]  if opts.key?(:volume)
      m.pitch   = opts[:pitch]   if opts.key?(:pitch)
      m.looping = opts[:looping] if opts.key?(:looping)
      m
    end

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

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfMusic_destroy))
    end
  end
end
