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

    def duration      = Time.from_native(C::Audio.sfSoundBuffer_getDuration(@handle))
    def sample_rate   = C::Audio.sfSoundBuffer_getSampleRate(@handle)
    def channel_count = C::Audio.sfSoundBuffer_getChannelCount(@handle)

    attr_reader :handle # :nodoc:

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfSoundBuffer_destroy))
    end
  end
end
