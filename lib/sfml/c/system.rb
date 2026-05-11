module SFML
  module C
    module System
      extend FFI::Library

      ffi_lib LIB_CANDIDATES[:system]

      class Time < FFI::Struct
        layout :microseconds, :int64
      end

      class Vector2f < FFI::Struct
        layout :x, :float, :y, :float
      end

      class Vector2i < FFI::Struct
        layout :x, :int32, :y, :int32
      end

      class Vector2u < FFI::Struct
        layout :x, :uint32, :y, :uint32
      end

      class Vector3f < FFI::Struct
        layout :x, :float, :y, :float, :z, :float
      end

      typedef :pointer, :clock_t

      attach_function :sfClock_create,         [],            :clock_t
      attach_function :sfClock_copy,           [:clock_t],    :clock_t
      attach_function :sfClock_destroy,        [:clock_t],    :void
      attach_function :sfClock_getElapsedTime, [:clock_t],    Time.by_value
      attach_function :sfClock_isRunning,      [:clock_t],    :bool
      attach_function :sfClock_start,          [:clock_t],    :void
      attach_function :sfClock_stop,           [:clock_t],    :void
      attach_function :sfClock_restart,        [:clock_t],    Time.by_value
      attach_function :sfClock_reset,          [:clock_t],    Time.by_value

      attach_function :sfSleep,                [Time.by_value], :void

      # sfBuffer — opaque growable byte buffer used by APIs like
      # sfImage_saveToMemory to return variable-length binary data
      # without forcing the caller to pre-size an output buffer.
      typedef :pointer, :buffer_t

      attach_function :sfBuffer_create,  [],                       :buffer_t
      attach_function :sfBuffer_destroy, [:buffer_t],               :void
      attach_function :sfBuffer_getSize, [:buffer_t],               :size_t
      attach_function :sfBuffer_getData, [:buffer_t],               :pointer

      # sfInputStream — a struct of 4 function pointers Ruby fills in
      # to expose a Ruby IO-like object to CSFML's loader functions.
      # User-data is ignored; we close over the Ruby object in each
      # callback closure directly.
      class InputStream < FFI::Struct
        layout :read,      :pointer,
               :seek,      :pointer,
               :tell,      :pointer,
               :get_size,  :pointer,
               :user_data, :pointer
      end
    end
  end
end
