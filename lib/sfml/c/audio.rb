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

      # Plain-old-data struct that mirrors sfSoundSourceCone.
      class SoundSourceCone < FFI::Struct
        layout :inner_angle, :float,
               :outer_angle, :float,
               :outer_gain,  :float
      end

      # ---- SoundBuffer ----
      attach_function :sfSoundBuffer_createFromFile, [:string], :sound_buffer_t
      attach_function :sfSoundBuffer_destroy,        [:sound_buffer_t], :void
      attach_function :sfSoundBuffer_saveToFile,     [:sound_buffer_t, :string], :bool
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
      attach_function :sfSound_setPlayingOffset,      [:sound_t, System::Time.by_value], :void
      attach_function :sfSound_getPlayingOffset,      [:sound_t], System::Time.by_value
      attach_function :sfSound_setVelocity,           [:sound_t, System::Vector3f.by_value], :void
      attach_function :sfSound_getVelocity,           [:sound_t], System::Vector3f.by_value
      attach_function :sfSound_setDopplerFactor,      [:sound_t, :float], :void
      attach_function :sfSound_getDopplerFactor,      [:sound_t], :float
      attach_function :sfSound_setDirection,          [:sound_t, System::Vector3f.by_value], :void
      attach_function :sfSound_getDirection,          [:sound_t], System::Vector3f.by_value
      attach_function :sfSound_setCone,               [:sound_t, SoundSourceCone.by_value], :void
      attach_function :sfSound_getCone,               [:sound_t], SoundSourceCone.by_value
      # void(*)(const float* in, unsigned int* in_count, float* out, unsigned int* out_count, unsigned int channels, void* userData)
      callback :sf_effect_processor, [:pointer, :pointer, :pointer, :pointer, :uint32, :pointer], :void
      attach_function :sfSound_setEffectProcessor,    [:sound_t, :sf_effect_processor, :pointer], :void

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
      attach_function :sfMusic_setPlayingOffset,      [:music_t, System::Time.by_value], :void
      attach_function :sfMusic_getPlayingOffset,      [:music_t], System::Time.by_value
      attach_function :sfMusic_setVelocity,           [:music_t, System::Vector3f.by_value], :void
      attach_function :sfMusic_getVelocity,           [:music_t], System::Vector3f.by_value
      attach_function :sfMusic_setDopplerFactor,      [:music_t, :float], :void
      attach_function :sfMusic_getDopplerFactor,      [:music_t], :float
      attach_function :sfMusic_setDirection,          [:music_t, System::Vector3f.by_value], :void
      attach_function :sfMusic_getDirection,          [:music_t], System::Vector3f.by_value
      attach_function :sfMusic_setCone,               [:music_t, SoundSourceCone.by_value], :void
      attach_function :sfMusic_getCone,               [:music_t], SoundSourceCone.by_value
      attach_function :sfMusic_setEffectProcessor,    [:music_t, :sf_effect_processor, :pointer], :void

      # ---- SoundStream ----
      # Custom audio source — fills a chunk via a Ruby callback that
      # CSFML invokes from the audio thread. Beware: that callback
      # has to acquire the GVL to run any Ruby code, so don't do
      # heavy work there. Generate samples and return.
      typedef :pointer, :sound_stream_t

      class SoundStreamChunk < FFI::Struct
        layout :samples,      :pointer,
               :sample_count, :uint32
      end

      callback :sound_stream_get_data, [:pointer, :pointer], :bool
      callback :sound_stream_seek,     [System::Time.by_value, :pointer], :void

      attach_function :sfSoundStream_create,
                      [:sound_stream_get_data, :sound_stream_seek,
                       :uint32, :uint32, :pointer, :size_t, :pointer],
                      :sound_stream_t
      attach_function :sfSoundStream_destroy,           [:sound_stream_t], :void
      attach_function :sfSoundStream_play,              [:sound_stream_t], :void
      attach_function :sfSoundStream_pause,             [:sound_stream_t], :void
      attach_function :sfSoundStream_stop,              [:sound_stream_t], :void
      attach_function :sfSoundStream_getChannelCount,   [:sound_stream_t], :uint32
      attach_function :sfSoundStream_getSampleRate,     [:sound_stream_t], :uint32
      attach_function :sfSoundStream_getStatus,         [:sound_stream_t], :int
      attach_function :sfSoundStream_setPlayingOffset,  [:sound_stream_t, System::Time.by_value], :void
      attach_function :sfSoundStream_getPlayingOffset,  [:sound_stream_t], System::Time.by_value
      attach_function :sfSoundStream_setLooping,        [:sound_stream_t, :bool], :void
      attach_function :sfSoundStream_isLooping,         [:sound_stream_t], :bool
      attach_function :sfSoundStream_setVolume,         [:sound_stream_t, :float], :void
      attach_function :sfSoundStream_getVolume,         [:sound_stream_t], :float
      attach_function :sfSoundStream_setPitch,          [:sound_stream_t, :float], :void
      attach_function :sfSoundStream_getPitch,          [:sound_stream_t], :float
      attach_function :sfSoundStream_setPosition,       [:sound_stream_t, System::Vector3f.by_value], :void
      attach_function :sfSoundStream_getPosition,       [:sound_stream_t], System::Vector3f.by_value
      attach_function :sfSoundStream_setMinDistance,    [:sound_stream_t, :float], :void
      attach_function :sfSoundStream_getMinDistance,    [:sound_stream_t], :float
      attach_function :sfSoundStream_setAttenuation,    [:sound_stream_t, :float], :void
      attach_function :sfSoundStream_getAttenuation,    [:sound_stream_t], :float
      attach_function :sfSoundStream_setRelativeToListener, [:sound_stream_t, :bool], :void
      attach_function :sfSoundStream_isRelativeToListener,  [:sound_stream_t], :bool

      # ---- SoundBufferRecorder ----
      # The simple "record into a SoundBuffer" path. Raw sfSoundRecorder
      # (callback-based) and sfSoundStream (custom audio source via
      # callbacks) need Ruby callbacks running on the SFML audio thread —
      # not worth the complexity for a niche feature.
      typedef :pointer, :sound_buffer_recorder_t

      attach_function :sfSoundBufferRecorder_create,           [], :sound_buffer_recorder_t
      attach_function :sfSoundBufferRecorder_destroy,          [:sound_buffer_recorder_t], :void
      attach_function :sfSoundBufferRecorder_start,            [:sound_buffer_recorder_t, :uint32], :bool
      attach_function :sfSoundBufferRecorder_stop,             [:sound_buffer_recorder_t], :void
      attach_function :sfSoundBufferRecorder_getSampleRate,    [:sound_buffer_recorder_t], :uint32
      attach_function :sfSoundBufferRecorder_getBuffer,        [:sound_buffer_recorder_t], :sound_buffer_t
      attach_function :sfSoundBufferRecorder_setDevice,        [:sound_buffer_recorder_t, :string], :bool
      attach_function :sfSoundBufferRecorder_getDevice,        [:sound_buffer_recorder_t], :string
      attach_function :sfSoundBufferRecorder_setChannelCount,  [:sound_buffer_recorder_t, :uint32], :void
      attach_function :sfSoundBufferRecorder_getChannelCount,  [:sound_buffer_recorder_t], :uint32

      # SoundRecorder static helpers — query mic availability and devices.
      attach_function :sfSoundRecorder_isAvailable,            [], :bool
      attach_function :sfSoundRecorder_getDefaultDevice,       [], :string
      attach_function :sfSoundRecorder_getAvailableDevices,    [:pointer], :pointer

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
