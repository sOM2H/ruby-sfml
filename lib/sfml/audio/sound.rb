module SFML
  # A short sound that plays from a SoundBuffer held entirely in memory.
  # Cheap to create, suitable for game SFX (blips, hits, footsteps).
  #
  #   buffer = SFML::SoundBuffer.load("blip.wav")
  #   sound  = SFML::Sound.new(buffer, volume: 80, pitch: 1.2, looping: true)
  #   sound.play
  class Sound
    def initialize(buffer, volume: 100.0, pitch: 1.0, looping: false)
      raise ArgumentError, "Sound requires a SFML::SoundBuffer" unless buffer.is_a?(SoundBuffer)

      ptr = C::Audio.sfSound_create(buffer.handle)
      raise Error, "sfSound_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfSound_destroy))
      @buffer  = buffer # keep alive
      # @looping mirrors the loop flag because SFML 3's isLooping reads
      # through an OpenAL source that may be unallocated on systems
      # without an audio device (some CI runners). Caching on the Ruby
      # side keeps observable behaviour deterministic regardless.
      @looping = false

      self.volume  = volume
      self.pitch   = pitch
      self.looping = looping
    end

    attr_reader :buffer

    def buffer=(new_buffer)
      raise ArgumentError, "Sound#buffer= requires a SFML::SoundBuffer" unless new_buffer.is_a?(SoundBuffer)
      C::Audio.sfSound_setBuffer(@handle, new_buffer.handle)
      @buffer = new_buffer
    end

    def play   = C::Audio.sfSound_play(@handle)
    def pause  = C::Audio.sfSound_pause(@handle)
    def stop   = C::Audio.sfSound_stop(@handle)

    def status      = C::Audio::STATUSES[C::Audio.sfSound_getStatus(@handle)]
    def playing?    = status == :playing
    def paused?     = status == :paused
    def stopped?    = status == :stopped

    # Current playback head as a SFML::Time. Reads from the underlying
    # OpenAL source — only meaningful while the sound is playing or
    # paused (not after #stop).
    def playing_offset
      Time.from_native(C::Audio.sfSound_getPlayingOffset(@handle))
    end

    # Seek to `value` (a SFML::Time, or seconds as a Numeric). Works
    # while the sound is playing, paused, or stopped — calling #play
    # afterwards resumes from the new offset.
    def playing_offset=(value)
      t = value.is_a?(Time) ? value : Time.seconds(value.to_f)
      C::Audio.sfSound_setPlayingOffset(@handle, t.to_native)
    end

    # 3D velocity in world units / second — used by the Doppler
    # effect to shift pitch as the source approaches or recedes from
    # the listener.
    def velocity
      v = C::Audio.sfSound_getVelocity(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    def velocity=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = vec.x.to_f; packed[:y] = vec.y.to_f; packed[:z] = vec.z.to_f
      C::Audio.sfSound_setVelocity(@handle, packed)
    end

    # Per-source Doppler scale. 1.0 is realistic; bump it up for an
    # exaggerated Doppler shift, drop to 0 to disable per-source.
    def doppler_factor    = C::Audio.sfSound_getDopplerFactor(@handle)
    def doppler_factor=(v) C::Audio.sfSound_setDopplerFactor(@handle, v.to_f); end

    # The direction the sound's cone points. Used together with
    # #cone= for directional attenuation.
    def direction
      v = C::Audio.sfSound_getDirection(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    def direction=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = vec.x.to_f; packed[:y] = vec.y.to_f; packed[:z] = vec.z.to_f
      C::Audio.sfSound_setDirection(@handle, packed)
    end

    # Directional-attenuation cone — see SFML::SoundCone.
    def cone
      SoundCone.from_native(C::Audio.sfSound_getCone(@handle))
    end

    def cone=(value)
      cone =
        case value
        when SoundCone then value
        when Hash      then SoundCone.new(**value)
        else
          raise ArgumentError, "Sound#cone= expects SoundCone or Hash; got #{value.class}"
        end
      C::Audio.sfSound_setCone(@handle, cone.to_native)
    end

    # Install a real-time DSP filter. The callable is invoked from the
    # CSFML audio thread once per audio frame batch with:
    #   * `input` — Array<Float> of interleaved samples (signed [-1, 1])
    #   * `channels` — Integer channel count (e.g. 2 for stereo)
    # and should return an Array<Float> of the same length (or shorter
    # if the effect produces fewer frames). Pass `nil` to remove an
    # installed processor.
    #
    # CAVEAT: the callback runs on a real-time audio thread and is
    # called every few milliseconds. Ruby + GVL is rarely fast enough
    # for non-trivial DSP — expect glitches for anything heavier than
    # a constant-gain or simple IIR. For real DSP, do it offline.
    def effect_processor=(callable)
      @effect_cb = callable.nil? ? nil : Audio._build_effect_processor(callable)
      C::Audio.sfSound_setEffectProcessor(@handle, @effect_cb, nil)
    end

    def looping?
      @looping
    end

    def looping=(value)
      @looping = value ? true : false
      C::Audio.sfSound_setLooping(@handle, @looping)
    end

    def volume      = C::Audio.sfSound_getVolume(@handle)

    def volume=(value)
      C::Audio.sfSound_setVolume(@handle, value.to_f)
    end

    def pitch       = C::Audio.sfSound_getPitch(@handle)

    def pitch=(value)
      C::Audio.sfSound_setPitch(@handle, value.to_f)
    end

    # ---- 3D positional audio ----
    #
    # Sounds have a 3D position; the SFML::Listener acts as the "ear".
    # Volume falls off with distance from min_distance outward, scaled
    # by attenuation (0 = no falloff, 1 = realistic, higher = sharper).
    # By default a Sound's position is in world coordinates; flip
    # `relative_to_listener = true` and the position becomes relative
    # to the listener — useful for "stuck to the camera" UI sounds.
    #
    # For 2D games, set z = 0 and listener.position to your camera.
    def position
      Vector3.from_native(C::Audio.sfSound_getPosition(@handle))
    end

    def position=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      C::Audio.sfSound_setPosition(@handle, vec.to_native_f)
    end

    def attenuation = C::Audio.sfSound_getAttenuation(@handle)

    def attenuation=(value)
      C::Audio.sfSound_setAttenuation(@handle, value.to_f)
    end

    def min_distance = C::Audio.sfSound_getMinDistance(@handle)

    def min_distance=(value)
      C::Audio.sfSound_setMinDistance(@handle, value.to_f)
    end

    def relative_to_listener? = C::Audio.sfSound_isRelativeToListener(@handle)

    def relative_to_listener=(value)
      C::Audio.sfSound_setRelativeToListener(@handle, value ? true : false)
    end
  end
end
