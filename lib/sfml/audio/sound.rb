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
