module SFML
  # Callback-based audio-capture base class. Subclass and override
  # `#on_start` (initialise capture state, return `true` to begin),
  # `#on_process_samples(samples, channels)` (called every audio chunk
  # with an Array<Integer> of interleaved int16 PCM, return `true` to
  # keep recording or `false` to stop), and `#on_stop` (release any
  # resources).
  #
  # The simpler "record to a SoundBuffer" path lives in
  # SFML::SoundBufferRecorder — reach for SoundRecorder only when you
  # need to stream samples somewhere else (file, socket, DSP pipeline).
  #
  #   class LevelMeter < SFML::SoundRecorder
  #     def on_start
  #       @peak = 0
  #       true
  #     end
  #
  #     def on_process_samples(samples, _channels)
  #       @peak = [@peak, *samples.map(&:abs)].max
  #       true
  #     end
  #
  #     def on_stop
  #       puts "Peak: #{@peak}"
  #     end
  #   end
  #
  #   meter = LevelMeter.new
  #   meter.start(sample_rate: 44_100)
  #   sleep 2
  #   meter.stop
  #
  # CAVEATS
  # * All three callbacks run on CSFML's audio thread; heavy Ruby work
  #   on the audio thread will glitch the capture.
  # * Always keep a reference to the SoundRecorder object — if the Ruby
  #   object is GC'd while CSFML is mid-capture, the process crashes.
  class SoundRecorder
    # ---- Static helpers (work without a recorder instance) ------------

    def self.available?
      C::Audio.sfSoundRecorder_isAvailable
    end

    def self.default_device
      C::Audio.sfSoundRecorder_getDefaultDevice
    end

    # All input devices the OS exposes to SFML, as an Array of String
    # names. Pass any of them to SoundRecorder#device= or
    # SoundBufferRecorder#device= to switch.
    def self.devices
      count_buf = FFI::MemoryPointer.new(:size_t)
      array_ptr = C::Audio.sfSoundRecorder_getAvailableDevices(count_buf)
      n = count_buf.read(:size_t)
      return [] if array_ptr.null? || n.zero?
      array_ptr.read_array_of_pointer(n).map { |p| p.read_string }
    end

    # ---- Instance API -------------------------------------------------

    def initialize
      # Strong refs so the GC doesn't disappear callbacks under CSFML.
      @start_cb = FFI::Function.new(:bool, [:pointer]) do |_user|
        on_start ? true : false
      end
      @process_cb = FFI::Function.new(:bool, [:pointer, :size_t, :pointer]) do |samples_ptr, count, _user|
        samples = count.zero? ? [] : samples_ptr.read_array_of_int16(count)
        on_process_samples(samples, channel_count) ? true : false
      end
      @stop_cb = FFI::Function.new(:void, [:pointer]) do |_user|
        on_stop
        nil
      end

      ptr = C::Audio.sfSoundRecorder_create(@start_cb, @process_cb, @stop_cb, nil)
      raise AudioError, "sfSoundRecorder_create returned NULL" if ptr.null?

      @handle = FFI::AutoPointer.new(ptr, C::Audio.method(:sfSoundRecorder_destroy))
    end

    # ---- Subclass hooks ----

    # Called once before the capture starts. Return `true` to begin
    # the capture or `false` to abort. Default does nothing and
    # accepts the start.
    def on_start
      true
    end

    # Called with each chunk of captured audio. `samples` is an
    # Array<Integer> of interleaved int16 PCM (length = frames *
    # channels). Return `true` to keep capturing or `false` to stop.
    # Default raises so subclasses must implement it.
    def on_process_samples(_samples, _channels)
      raise NoMethodError, "#{self.class} must override #on_process_samples"
    end

    # Called once after the capture is done. Default is a no-op.
    def on_stop; end

    # ---- Public recorder API ----

    def start(sample_rate: 44_100)
      C::Audio.sfSoundRecorder_start(@handle, Integer(sample_rate)) ||
        raise(AudioError, "sfSoundRecorder_start failed (no input device or driver error)")
      self
    end

    def stop
      C::Audio.sfSoundRecorder_stop(@handle)
      self
    end

    def sample_rate   = C::Audio.sfSoundRecorder_getSampleRate(@handle)
    def channel_count = C::Audio.sfSoundRecorder_getChannelCount(@handle)

    def channel_count=(n)
      C::Audio.sfSoundRecorder_setChannelCount(@handle, Integer(n))
    end

    def device = C::Audio.sfSoundRecorder_getDevice(@handle)

    def device=(name)
      C::Audio.sfSoundRecorder_setDevice(@handle, name.to_s) ||
        raise(AudioError, "sfSoundRecorder_setDevice failed for #{name.inspect}")
    end

    # The channel layout the recorder is producing, as an Array of
    # `sfSoundChannel` enum values (1 = Mono, 2 = FrontLeft,
    # 3 = FrontRight, etc — see SoundBuffer::DEFAULT_CHANNEL_MAPS).
    def channel_map
      count_buf = FFI::MemoryPointer.new(:size_t)
      ptr = C::Audio.sfSoundRecorder_getChannelMap(@handle, count_buf)
      n = count_buf.read(:size_t)
      return [] if ptr.null? || n.zero?
      ptr.read_array_of_int32(n)
    end

    attr_reader :handle # :nodoc:
  end
end
