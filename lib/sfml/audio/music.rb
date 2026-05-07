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

    def looping?
      C::Audio.sfMusic_isLooping(@handle) != 0
    end

    def looping=(value)
      C::Audio.sfMusic_setLooping(@handle, value ? 1 : 0)
    end

    def volume = C::Audio.sfMusic_getVolume(@handle)

    def volume=(value)
      C::Audio.sfMusic_setVolume(@handle, value.to_f)
    end

    def pitch = C::Audio.sfMusic_getPitch(@handle)

    def pitch=(value)
      C::Audio.sfMusic_setPitch(@handle, value.to_f)
    end

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfMusic_destroy))
    end
  end
end
