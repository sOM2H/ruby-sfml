module SFML
  module C
    module Audio
      extend FFI::Library

      ffi_lib LIB_CANDIDATES[:audio]

      typedef :pointer, :sound_buffer_t
      typedef :pointer, :sound_t
      typedef :pointer, :music_t

      # sfSoundStatus = { sfStopped, sfPaused, sfPlaying } in that order.
      STATUSES = %i[stopped paused playing].freeze

      # ---- SoundBuffer ----
      attach_function :sfSoundBuffer_createFromFile, [:string], :sound_buffer_t
      attach_function :sfSoundBuffer_destroy,        [:sound_buffer_t], :void
      attach_function :sfSoundBuffer_getDuration,    [:sound_buffer_t], System::Time.by_value
      attach_function :sfSoundBuffer_getSampleRate,  [:sound_buffer_t], :uint32
      attach_function :sfSoundBuffer_getChannelCount,[:sound_buffer_t], :uint32

      # ---- Sound ----
      # We use :uchar instead of :bool for setLooping/isLooping. CSFML 3
      # declares the param as C99 `bool` (1 byte), but FFI's :bool ABI
      # marshalling has been observed to misbehave on some Linux builds
      # of CSFML 3 (volume/pitch through :float work, looping through
      # :bool silently doesn't stick). :uchar with explicit 0/1 is what
      # CSFML's headers semantically promise and is portable across ABIs.
      attach_function :sfSound_create,        [:sound_buffer_t], :sound_t
      attach_function :sfSound_destroy,       [:sound_t], :void
      attach_function :sfSound_play,          [:sound_t], :void
      attach_function :sfSound_pause,         [:sound_t], :void
      attach_function :sfSound_stop,          [:sound_t], :void
      attach_function :sfSound_setBuffer,     [:sound_t, :sound_buffer_t], :void
      attach_function :sfSound_setLooping,    [:sound_t, :uchar], :void
      attach_function :sfSound_isLooping,     [:sound_t], :uchar
      attach_function :sfSound_getStatus,     [:sound_t], :int
      attach_function :sfSound_setVolume,     [:sound_t, :float], :void
      attach_function :sfSound_getVolume,     [:sound_t], :float
      attach_function :sfSound_setPitch,      [:sound_t, :float], :void
      attach_function :sfSound_getPitch,      [:sound_t], :float

      # ---- Music ----
      attach_function :sfMusic_createFromFile, [:string], :music_t
      attach_function :sfMusic_destroy,        [:music_t], :void
      attach_function :sfMusic_play,           [:music_t], :void
      attach_function :sfMusic_pause,          [:music_t], :void
      attach_function :sfMusic_stop,           [:music_t], :void
      attach_function :sfMusic_setLooping,     [:music_t, :uchar], :void
      attach_function :sfMusic_isLooping,      [:music_t], :uchar
      attach_function :sfMusic_getStatus,      [:music_t], :int
      attach_function :sfMusic_setVolume,      [:music_t, :float], :void
      attach_function :sfMusic_getVolume,      [:music_t], :float
      attach_function :sfMusic_setPitch,       [:music_t, :float], :void
      attach_function :sfMusic_getPitch,       [:music_t], :float
      attach_function :sfMusic_getDuration,    [:music_t], System::Time.by_value
    end
  end
end
