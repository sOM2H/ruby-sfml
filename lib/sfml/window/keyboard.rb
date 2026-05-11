module SFML
  # Keyboard key code <-> symbol translation, plus Keyboard.key_pressed?(:esc).
  #
  # Two concepts:
  #   * **Key**   — logical / layout-dependent. `:a` on a QWERTY keyboard
  #     is the physical Q on AZERTY. Use this for "what does the user
  #     mean" (text input, layout-aware shortcuts).
  #   * **Scancode** — physical / layout-independent. The key at the
  #     position you expect WASD to be will always be `:scan_w` /
  #     `:scan_a` / `:scan_s` / `:scan_d`. Use this for "the WASD keys"
  #     that should stay in the same physical place regardless of
  #     keyboard layout. Standard in modern games.
  #
  # The KEY_CODES / SCAN_CODES arrays are load-bearing: order matches
  # the sfKeyCode / sfScancode enums in CSFML/Window/Keyboard.h.
  module Keyboard
    KEY_CODES = %i[
      a b c d e f g h i j k l m n o p q r s t u v w x y z
      num0 num1 num2 num3 num4 num5 num6 num7 num8 num9
      escape
      l_control l_shift l_alt l_system
      r_control r_shift r_alt r_system
      menu
      l_bracket r_bracket
      semicolon comma period apostrophe slash backslash grave equal hyphen
      space enter backspace tab
      page_up page_down end_key home insert delete
      add subtract multiply divide
      left right up down
      numpad0 numpad1 numpad2 numpad3 numpad4
      numpad5 numpad6 numpad7 numpad8 numpad9
      f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15
      pause
    ].freeze

    SYMBOL_TO_CODE = KEY_CODES.each_with_index.to_h.freeze

    # Matches sfScancode in CSFML/Window/Keyboard.h exactly.
    # sfScanUnknown is -1, represented here by :scan_unknown via #scancode_to_symbol.
    SCAN_CODES = %i[
      scan_a scan_b scan_c scan_d scan_e scan_f scan_g scan_h
      scan_i scan_j scan_k scan_l scan_m scan_n scan_o scan_p
      scan_q scan_r scan_s scan_t scan_u scan_v scan_w scan_x scan_y scan_z
      scan_num1 scan_num2 scan_num3 scan_num4 scan_num5
      scan_num6 scan_num7 scan_num8 scan_num9 scan_num0
      scan_enter scan_escape scan_backspace scan_tab scan_space
      scan_hyphen scan_equal scan_l_bracket scan_r_bracket scan_backslash
      scan_semicolon scan_apostrophe scan_grave scan_comma scan_period scan_slash
      scan_f1 scan_f2 scan_f3 scan_f4 scan_f5 scan_f6
      scan_f7 scan_f8 scan_f9 scan_f10 scan_f11 scan_f12
      scan_f13 scan_f14 scan_f15 scan_f16 scan_f17 scan_f18
      scan_f19 scan_f20 scan_f21 scan_f22 scan_f23 scan_f24
      scan_caps_lock scan_print_screen scan_scroll_lock scan_pause
      scan_insert scan_home scan_page_up scan_delete scan_end scan_page_down
      scan_right scan_left scan_down scan_up
      scan_num_lock scan_numpad_divide scan_numpad_multiply scan_numpad_minus
      scan_numpad_plus scan_numpad_equal scan_numpad_enter scan_numpad_decimal
      scan_numpad1 scan_numpad2 scan_numpad3 scan_numpad4 scan_numpad5
      scan_numpad6 scan_numpad7 scan_numpad8 scan_numpad9 scan_numpad0
      scan_non_us_backslash scan_application scan_execute scan_mode_change
      scan_help scan_menu scan_select scan_redo scan_undo
      scan_cut scan_copy scan_paste
      scan_volume_mute scan_volume_up scan_volume_down
      scan_media_play_pause scan_media_stop scan_media_next_track scan_media_previous_track
      scan_l_control scan_l_shift scan_l_alt scan_l_system
      scan_r_control scan_r_shift scan_r_alt scan_r_system
      scan_back scan_forward scan_refresh scan_stop scan_search scan_favorites scan_home_page
      scan_launch_application1 scan_launch_application2 scan_launch_mail scan_launch_media_select
    ].freeze

    SCAN_SYMBOL_TO_CODE = SCAN_CODES.each_with_index.to_h.freeze

    # Friendly aliases users might reach for naturally.
    ALIASES = {
      esc:    :escape,
      lctrl:  :l_control,
      rctrl:  :r_control,
      lshift: :l_shift,
      rshift: :r_shift,
      space_bar: :space,
      return: :enter,
    }.freeze

    module_function

    def code_to_symbol(code)
      return :unknown if code < 0 || code >= KEY_CODES.length
      KEY_CODES[code]
    end

    def symbol_to_code(symbol)
      symbol = ALIASES.fetch(symbol, symbol)
      SYMBOL_TO_CODE.fetch(symbol) do
        raise ArgumentError, "Unknown key symbol: #{symbol.inspect}. " \
                             "See SFML::Keyboard::KEY_CODES."
      end
    end

    def scancode_to_symbol(code)
      return :scan_unknown if code < 0 || code >= SCAN_CODES.length
      SCAN_CODES[code]
    end

    def symbol_to_scancode(symbol)
      SCAN_SYMBOL_TO_CODE.fetch(symbol) do
        raise ArgumentError, "Unknown scancode symbol: #{symbol.inspect}. " \
                             "See SFML::Keyboard::SCAN_CODES."
      end
    end

    # SFML::Keyboard.key_pressed?(:escape) — logical key.
    def key_pressed?(symbol)
      C::Window.sfKeyboard_isKeyPressed(symbol_to_code(symbol))
    end

    # SFML::Keyboard.scancode_pressed?(:scan_w) — physical key
    # regardless of keyboard layout.
    def scancode_pressed?(symbol)
      C::Window.sfKeyboard_isScancodePressed(symbol_to_scancode(symbol))
    end

    # Map a physical scancode to whatever logical key it produces under
    # the current OS keyboard layout. Returns a key symbol (or
    # :unknown for unmappable scancodes).
    def localize(scancode)
      code_to_symbol(C::Window.sfKeyboard_localize(symbol_to_scancode(scancode)))
    end

    # Inverse of #localize — find the physical scancode that *would*
    # produce this logical key under the current layout. Returns a
    # scancode symbol.
    def delocalize(key)
      scancode_to_symbol(C::Window.sfKeyboard_delocalize(symbol_to_code(key)))
    end

    # Human-readable description for a scancode under the current
    # layout — e.g. `:scan_w` → `"W"` on QWERTY, `"Z"` on AZERTY.
    def description(scancode)
      C::Window.sfKeyboard_getDescription(symbol_to_scancode(scancode))
    end

    # On-screen / virtual keyboard toggle. No-op on desktop platforms;
    # meaningful on mobile/touchscreen builds.
    def virtual_keyboard_visible=(value)
      C::Window.sfKeyboard_setVirtualKeyboardVisible(!!value)
    end
  end
end
