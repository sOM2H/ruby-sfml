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
      attach_function :sfSound_create,        [:sound_buffer_t], :sound_t
      attach_function :sfSound_destroy,       [:sound_t], :void
      attach_function :sfSound_play,          [:sound_t], :void
      attach_function :sfSound_pause,         [:sound_t], :void
      attach_function :sfSound_stop,          [:sound_t], :void
      attach_function :sfSound_setBuffer,     [:sound_t, :sound_buffer_t], :void
      attach_function :sfSound_setLooping,    [:sound_t, :bool], :void
      attach_function :sfSound_isLooping,     [:sound_t], :bool
      attach_function :sfSound_getStatus,     [:sound_t], :int
      attach_function :sfSound_setVolume,     [:sound_t, :float], :void
      attach_function :sfSound_getVolume,     [:sound_t], :float
      attach_function :sfSound_setPitch,      [:sound_t, :float], :void
      attach_function :sfSound_getPitch,      [:sound_t], :float

      # 3D positional audio
      attach_function :sfSound_setPosition,           [:sound_t, System::Vector3f.by_value], :void
      attach_function :sfSound_getPosition,           [:sound_t], System::Vector3f.by_value
      attach_function :sfSound_setMinDistance,        [:sound_t, :float], :void
      attach_function :sfSound_getMinDistance,        [:sound_t], :float
      attach_function :sfSound_setAttenuation,        [:sound_t, :float], :void
      attach_function :sfSound_getAttenuation,        [:sound_t], :float
      attach_function :sfSound_setRelativeToListener, [:sound_t, :bool], :void
      attach_function :sfSound_isRelativeToListener,  [:sound_t], :bool

      # ---- Music ----
      attach_function :sfMusic_createFromFile, [:string], :music_t
      attach_function :sfMusic_destroy,        [:music_t], :void
      attach_function :sfMusic_play,           [:music_t], :void
      attach_function :sfMusic_pause,          [:music_t], :void
      attach_function :sfMusic_stop,           [:music_t], :void
      attach_function :sfMusic_setLooping,     [:music_t, :bool], :void
      attach_function :sfMusic_isLooping,      [:music_t], :bool
      attach_function :sfMusic_getStatus,      [:music_t], :int
      attach_function :sfMusic_setVolume,      [:music_t, :float], :void
      attach_function :sfMusic_getVolume,      [:music_t], :float
      attach_function :sfMusic_setPitch,       [:music_t, :float], :void
      attach_function :sfMusic_getPitch,       [:music_t], :float
      attach_function :sfMusic_getDuration,    [:music_t], System::Time.by_value

      attach_function :sfMusic_setPosition,           [:music_t, System::Vector3f.by_value], :void
      attach_function :sfMusic_getPosition,           [:music_t], System::Vector3f.by_value
      attach_function :sfMusic_setMinDistance,        [:music_t, :float], :void
      attach_function :sfMusic_getMinDistance,        [:music_t], :float
      attach_function :sfMusic_setAttenuation,        [:music_t, :float], :void
      attach_function :sfMusic_getAttenuation,        [:music_t], :float
      attach_function :sfMusic_setRelativeToListener, [:music_t, :bool], :void
      attach_function :sfMusic_isRelativeToListener,  [:music_t], :bool

      # ---- Listener (the "ear" — global, no handle) ----
      attach_function :sfListener_setGlobalVolume, [:float], :void
      attach_function :sfListener_getGlobalVolume, [], :float
      attach_function :sfListener_setPosition,     [System::Vector3f.by_value], :void
      attach_function :sfListener_getPosition,     [], System::Vector3f.by_value
      attach_function :sfListener_setDirection,    [System::Vector3f.by_value], :void
      attach_function :sfListener_getDirection,    [], System::Vector3f.by_value
      attach_function :sfListener_setUpVector,     [System::Vector3f.by_value], :void
      attach_function :sfListener_getUpVector,     [], System::Vector3f.by_value
    end
  end
end
