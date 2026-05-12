module SFML
  # Records audio from the system input (microphone) directly into a
  # SoundBuffer. Quickest path for a "record audio" feature — start,
  # speak, stop, save:
  #
  #   recorder = SFML::SoundBufferRecorder.new
  #   recorder.start(sample_rate: 44100)
  #   sleep 3
  #   recorder.stop
  #   recorder.buffer.save("memo.wav")
  #
  # Recording requires a working input device; SFML::SoundRecorder.available?
  # tells you whether one is present before you start.
  class SoundBufferRecorder
    def initialize
      ptr = C::Audio.sfSoundBufferRecorder_create
      raise AudioError, "sfSoundBufferRecorder_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfSoundBufferRecorder_destroy))
    end

    # Begin capturing samples at the given sample rate. Returns true on
    # success, false if the device couldn't be opened.
    def start(sample_rate: 44_100)
      C::Audio.sfSoundBufferRecorder_start(@handle, Integer(sample_rate))
    end

    def stop
      C::Audio.sfSoundBufferRecorder_stop(@handle)
      self
    end

    def sample_rate
      C::Audio.sfSoundBufferRecorder_getSampleRate(@handle)
    end

    def channel_count
      C::Audio.sfSoundBufferRecorder_getChannelCount(@handle)
    end

    # Set the channel count.
    def channel_count=(value)
      C::Audio.sfSoundBufferRecorder_setChannelCount(@handle, Integer(value))
    end

    # The captured audio so far. Returned as a borrowed SoundBuffer
    # owned by the recorder — copy it (via #save or by feeding to a
    # Sound) before destroying the recorder, or build a Sound that
    # outlives the recorder via the buffer's data.
    def buffer
      ptr = C::Audio.sfSoundBufferRecorder_getBuffer(@handle)
      raise AudioError, "sfSoundBufferRecorder_getBuffer returned NULL" if ptr.null?
      # Borrowed — recorder owns the underlying sf::SoundBuffer.
      buf = SoundBuffer.allocate
      buf.instance_variable_set(:@handle, ptr)
      buf
    end

    # Currently selected input device name (or nil).
    def device
      name = C::Audio.sfSoundBufferRecorder_getDevice(@handle)
      name unless name.nil? || name.empty?
    end

    # Set the device.
    def device=(name)
      ok = C::Audio.sfSoundBufferRecorder_setDevice(@handle, name.to_s)
      raise AudioError, "could not select recording device #{name.inspect}" unless ok
      name
    end

    attr_reader :handle # :nodoc:
  end
end
