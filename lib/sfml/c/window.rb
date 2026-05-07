module SFML
  module C
    module Window
      extend FFI::Library

      ffi_lib LIB_CANDIDATES[:window]

      class VideoMode < FFI::Struct
        layout :size,           System::Vector2u,
               :bits_per_pixel, :uint32
      end

      # sfStyle is a bitmask. sfWindowState is a plain enum.
      module Style
        NONE     = 0
        TITLEBAR = 1 << 0
        RESIZE   = 1 << 1
        CLOSE    = 1 << 2
        DEFAULT  = TITLEBAR | RESIZE | CLOSE
      end

      State = enum :window_state, [:windowed, :fullscreen]

      # sfEventType — order MUST match CSFML/Window/Event.h. We expose this as
      # an :int FFI type and translate to/from Ruby symbols in the high-level
      # SFML::Event class. Order is load-bearing.
      EVENT_TYPES = %i[
        closed
        resized
        focus_lost
        focus_gained
        text_entered
        key_pressed
        key_released
        mouse_wheel_scrolled
        mouse_button_pressed
        mouse_button_released
        mouse_moved
        mouse_moved_raw
        mouse_entered
        mouse_left
        joystick_button_pressed
        joystick_button_released
        joystick_moved
        joystick_connected
        joystick_disconnected
        touch_began
        touch_moved
        touch_ended
        sensor_changed
      ].freeze

      # Per-variant structs of the sfEvent union.
      class KeyEvent < FFI::Struct
        layout :type,     :int,
               :code,     :int32,
               :scancode, :int32,
               :alt,      :bool,
               :control,  :bool,
               :shift,    :bool,
               :system,   :bool
      end

      class TextEvent < FFI::Struct
        layout :type, :int, :unicode, :uint32
      end

      class SizeEvent < FFI::Struct
        layout :type, :int, :size, System::Vector2u
      end

      class MouseMoveEvent < FFI::Struct
        layout :type, :int, :position, System::Vector2i
      end

      class MouseButtonEvent < FFI::Struct
        layout :type,     :int,
               :button,   :int,
               :position, System::Vector2i
      end

      class MouseWheelScrollEvent < FFI::Struct
        layout :type,     :int,
               :wheel,    :int,
               :delta,    :float,
               :position, System::Vector2i
      end

      class JoystickButtonEvent < FFI::Struct
        layout :type,        :int,
               :joystick_id, :uint32,
               :button,      :uint32
      end

      class JoystickMoveEvent < FFI::Struct
        layout :type,        :int,
               :joystick_id, :uint32,
               :axis,        :int,
               :position,    :float
      end

      class JoystickConnectEvent < FFI::Struct
        layout :type,        :int,
               :joystick_id, :uint32
      end

      # sfEvent is a C union. The largest variant (KeyEvent on x86_64: 4+4+4+4
      # = 20 bytes) defines the union size; we allocate a buffer that big and
      # reinterpret per-type. We use a Struct (not Union) here because Ruby
      # FFI handles variable-tag unions awkwardly — the tag is the first int32
      # in every variant, so we read it directly.
      class Event < FFI::Struct
        layout :type, :int, :_pad, [:uint8, 28]

        def event_type
          EVENT_TYPES[self[:type]]
        end
      end

      attach_function :sfVideoMode_getDesktopMode, [], VideoMode.by_value

      attach_function :sfKeyboard_isKeyPressed, [:int], :bool

      # Mouse: position queries here use a sfWindow*. Pass NULL to get
      # desktop-relative coordinates. The render-window variants live in
      # SFML::C::Graphics (different shared library).
      attach_function :sfMouse_isButtonPressed, [:int], :bool
      attach_function :sfMouse_getPosition,     [:pointer], System::Vector2i.by_value
      attach_function :sfMouse_setPosition,     [System::Vector2i.by_value, :pointer], :void

      # ---- Cursor ----
      typedef :pointer, :cursor_t

      attach_function :sfCursor_createFromPixels, [:pointer, System::Vector2u.by_value, System::Vector2u.by_value], :cursor_t
      attach_function :sfCursor_createFromSystem, [:int], :cursor_t
      attach_function :sfCursor_destroy,          [:cursor_t], :void

      # ---- Clipboard ----
      attach_function :sfClipboard_getString,        [], :string
      attach_function :sfClipboard_setString,        [:string], :void
      attach_function :sfClipboard_getUnicodeString, [], :pointer
      attach_function :sfClipboard_setUnicodeString, [:pointer], :void

      # ---- Joystick ----
      class JoystickIdentification < FFI::Struct
        layout :name,       :pointer,  # const char*
               :vendor_id,  :uint32,
               :product_id, :uint32
      end

      attach_function :sfJoystick_isConnected,     [:uint32], :bool
      attach_function :sfJoystick_getButtonCount,  [:uint32], :uint32
      attach_function :sfJoystick_hasAxis,         [:uint32, :int], :bool
      attach_function :sfJoystick_isButtonPressed, [:uint32, :uint32], :bool
      attach_function :sfJoystick_getAxisPosition, [:uint32, :int], :float
      attach_function :sfJoystick_getIdentification, [:uint32], JoystickIdentification.by_value
      attach_function :sfJoystick_update,          [], :void

      # ---- Bare Window (no rendering) ----
      # SFML 3 splits sf::Window (pure window + GL context) from
      # sf::RenderWindow (window + 2D batcher). The bare variant is
      # useful only when you're driving raw OpenGL yourself.
      typedef :pointer, :raw_window_t

      attach_function :sfWindow_create,        [VideoMode.by_value, :string, :uint32, :int, :pointer], :raw_window_t
      attach_function :sfWindow_destroy,       [:raw_window_t], :void
      attach_function :sfWindow_close,         [:raw_window_t], :void
      attach_function :sfWindow_isOpen,        [:raw_window_t], :bool
      attach_function :sfWindow_pollEvent,     [:raw_window_t, :pointer], :bool
      attach_function :sfWindow_waitEvent,     [:raw_window_t, System::Time.by_value, :pointer], :bool
      attach_function :sfWindow_display,       [:raw_window_t], :void
      attach_function :sfWindow_setVisible,    [:raw_window_t, :bool], :void
      attach_function :sfWindow_setTitle,      [:raw_window_t, :string], :void
      attach_function :sfWindow_getSize,       [:raw_window_t], System::Vector2u.by_value
      attach_function :sfWindow_setSize,       [:raw_window_t, System::Vector2u.by_value], :void
      attach_function :sfWindow_getPosition,   [:raw_window_t], System::Vector2i.by_value
      attach_function :sfWindow_setPosition,   [:raw_window_t, System::Vector2i.by_value], :void
      attach_function :sfWindow_setFramerateLimit,      [:raw_window_t, :uint32], :void
      attach_function :sfWindow_setVerticalSyncEnabled, [:raw_window_t, :bool], :void
      attach_function :sfWindow_setKeyRepeatEnabled,    [:raw_window_t, :bool], :void
      attach_function :sfWindow_requestFocus,  [:raw_window_t], :void
      attach_function :sfWindow_hasFocus,      [:raw_window_t], :bool
      attach_function :sfWindow_setActive,     [:raw_window_t, :bool], :bool
      attach_function :sfWindow_setIcon,       [:raw_window_t, System::Vector2u.by_value, :pointer], :void
    end
  end
end
