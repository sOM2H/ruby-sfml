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
      raise AudioError, "sfSound_create returned NULL" if ptr.null?
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

    # The buffer.
    attr_reader :buffer

    # Replace the `SoundBuffer` this Sound is bound to. Stopping
    # first is recommended — otherwise the change takes effect mid-frame.
    def buffer=(new_buffer)
      raise ArgumentError, "Sound#buffer= requires a SFML::SoundBuffer" unless new_buffer.is_a?(SoundBuffer)
      C::Audio.sfSound_setBuffer(@handle, new_buffer.handle)
      @buffer = new_buffer
    end

    # Start playback. If the sound was paused, resumes from there.
    # If it was already playing, restarts from the beginning.
    def play   = C::Audio.sfSound_play(@handle)
    # Pause playback. `#play` resumes from this point; `#stop` rewinds.
    def pause  = C::Audio.sfSound_pause(@handle)
    # Stop playback and rewind to the start.
    def stop   = C::Audio.sfSound_stop(@handle)

    # Playback state — one of `:stopped`, `:paused`, `:playing`.
    def status      = C::Audio::STATUSES[C::Audio.sfSound_getStatus(@handle)]
    # Convenience predicate for `status == :playing`.
    def playing?    = status == :playing
    # Convenience predicate for `status == :paused`.
    def paused?     = status == :paused
    # Convenience predicate for `status == :stopped`.
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

    # Set the 3D velocity — accepts a Vector3 or `[x, y, z]`.
    def velocity=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      packed = C::System::Vector3f.new
      packed[:x] = vec.x.to_f; packed[:y] = vec.y.to_f; packed[:z] = vec.z.to_f
      C::Audio.sfSound_setVelocity(@handle, packed)
    end

    # Per-source Doppler scale. 1.0 is realistic; bump it up for an
    # exaggerated Doppler shift, drop to 0 to disable per-source.
    def doppler_factor    = C::Audio.sfSound_getDopplerFactor(@handle)
    # Set the per-source Doppler scale. See `#doppler_factor`.
    def doppler_factor=(v) C::Audio.sfSound_setDopplerFactor(@handle, v.to_f); end

    # The direction the sound's cone points. Used together with
    # #cone= for directional attenuation.
    def direction
      v = C::Audio.sfSound_getDirection(@handle)
      Vector3.new(v[:x], v[:y], v[:z])
    end

    # Set the direction vector — accepts Vector3 or `[x, y, z]`.
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

    # Set the cone. Accepts a `SoundCone` or a Hash with
    # `inner_angle`, `outer_angle`, `outer_gain`.
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

    # `true` if the sound restarts after reaching the end.
    def looping?
      @looping
    end

    # Toggle looping playback. With `true`, the sound restarts from
    # the start after every play-through.
    def looping=(value)
      @looping = value ? true : false
      C::Audio.sfSound_setLooping(@handle, @looping)
    end

    # Playback volume in [0, 100] — 100 = unattenuated.
    def volume      = C::Audio.sfSound_getVolume(@handle)

    # Set the playback volume in [0, 100].
    def volume=(value)
      C::Audio.sfSound_setVolume(@handle, value.to_f)
    end

    # Pitch multiplier. 1.0 = normal, 2.0 = octave up, 0.5 = octave
    # down. Also shifts playback duration proportionally.
    def pitch       = C::Audio.sfSound_getPitch(@handle)

    # Set the pitch multiplier — see `#pitch`.
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

    # Set the 3D position — accepts Vector3 or `[x, y, z]`.
    def position=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      C::Audio.sfSound_setPosition(@handle, vec.to_native_f)
    end

    # Falloff sharpness with distance. 0 = no falloff, 1 = realistic
    # (1/distance), higher = steeper.
    def attenuation = C::Audio.sfSound_getAttenuation(@handle)

    # Set the attenuation — see `#attenuation`.
    def attenuation=(value)
      C::Audio.sfSound_setAttenuation(@handle, value.to_f)
    end

    # Distance below which volume is not attenuated.
    def min_distance = C::Audio.sfSound_getMinDistance(@handle)

    # Set the min-distance — see `#min_distance`.
    def min_distance=(value)
      C::Audio.sfSound_setMinDistance(@handle, value.to_f)
    end

    # If `true`, `#position` is interpreted relative to the listener
    # (useful for HUD/UI sounds that should stay glued to the
    # camera).
    def relative_to_listener? = C::Audio.sfSound_isRelativeToListener(@handle)

    # Toggle listener-relative positioning.
    def relative_to_listener=(value)
      C::Audio.sfSound_setRelativeToListener(@handle, value ? true : false)
    end

    # The buffer this Sound is currently bound to (the one passed
    # to `.new`, or whoever last called `buffer=`). Returns nil
    # if the underlying source has none.
    def buffer
      ptr = C::Audio.sfSound_getBuffer(@handle)
      return nil if ptr.null?
      @buffer  # keep Ruby reference alive (the C handle is borrowed from it)
    end

    # Stereo pan in [-1.0, 1.0]: -1 = full left, 0 = centre, 1 = full right.
    def pan = C::Audio.sfSound_getPan(@handle)

    # Set the stereo pan — see `#pan`.
    def pan=(v)
      C::Audio.sfSound_setPan(@handle, v.to_f)
    end

    # Output gain clamping. `min_gain` floors the attenuated
    # gain; `max_gain` caps it. Useful when you want a sound to
    # always be at least faintly audible (or never louder than
    # the listener's local SFX volume).
    def min_gain = C::Audio.sfSound_getMinGain(@handle)

    # Set the min-gain floor — see `#min_gain`.
    def min_gain=(v)
      C::Audio.sfSound_setMinGain(@handle, v.to_f)
    end

    # The upper gain bound — see `#min_gain`.
    def max_gain = C::Audio.sfSound_getMaxGain(@handle)

    # Set the max-gain cap — see `#max_gain`.
    def max_gain=(v)
      C::Audio.sfSound_setMaxGain(@handle, v.to_f)
    end

    # The distance beyond which the source is fully attenuated.
    def max_distance = C::Audio.sfSound_getMaxDistance(@handle)

    # Set the max-distance — see `#max_distance`.
    def max_distance=(v)
      C::Audio.sfSound_setMaxDistance(@handle, v.to_f)
    end

    # Whether 3D-positional / Doppler / cone math is applied at
    # mix time. Off → the sound plays as a simple stereo source.
    def spatialization_enabled? = C::Audio.sfSound_isSpatializationEnabled(@handle)

    # Toggle 3D spatialisation — see `#spatialization_enabled?`.
    def spatialization_enabled=(v)
      C::Audio.sfSound_setSpatializationEnabled(@handle, v ? true : false)
    end

    # Multiplier on the Listener's directional attenuation cone.
    # 0 = source ignores the listener's facing direction (no
    # cone falloff); 1 = full cone effect.
    def directional_attenuation_factor
      C::Audio.sfSound_getDirectionalAttenuationFactor(@handle)
    end

    # Set the directional-attenuation factor — see
    # `#directional_attenuation_factor`.
    def directional_attenuation_factor=(v)
      C::Audio.sfSound_setDirectionalAttenuationFactor(@handle, v.to_f)
    end

    # Independent copy — same buffer (buffers are shareable),
    # independent transport state (volume/pan/spatialisation/etc).
    def dup
      ptr = C::Audio.sfSound_copy(@handle)
      raise AudioError, "sfSound_copy returned NULL" if ptr.null?

      copy = self.class.allocate
      copy.instance_variable_set(:@handle,
        FFI::AutoPointer.new(ptr, C::Audio.method(:sfSound_destroy)))
      copy.instance_variable_set(:@buffer, @buffer)
      copy
    end
    alias clone dup
  end
end
