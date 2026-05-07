module SFML
  # Static helpers for audio capture. Use SFML::SoundBufferRecorder
  # to actually record; these tell you what hardware is available.
  #
  #   SFML::SoundRecorder.available?           #=> true / false
  #   SFML::SoundRecorder.devices              #=> ["alsa_input.pci-...", ...]
  #   SFML::SoundRecorder.default_device       #=> "alsa_input.pci-..."
  module SoundRecorder
    module_function

    # Is at least one audio input device present on the host?
    def available?
      C::Audio.sfSoundRecorder_isAvailable
    end

    def default_device
      C::Audio.sfSoundRecorder_getDefaultDevice
    end

    # All input devices the OS exposes to SFML, as an Array of String
    # names. Pass any of them to SoundBufferRecorder#device= to switch.
    def devices
      count_buf = FFI::MemoryPointer.new(:size_t)
      array_ptr = C::Audio.sfSoundRecorder_getAvailableDevices(count_buf)
      n = count_buf.read(:size_t)
      return [] if array_ptr.null? || n.zero?
      array_ptr.read_array_of_pointer(n).map { |p| p.read_string }
    end
  end
end
