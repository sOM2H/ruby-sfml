module SFML
  # Keyboard key code <-> symbol translation, plus Keyboard.key_pressed?(:esc).
  #
  # The KEY_CODES array order is load-bearing: it matches the sfKeyCode enum
  # in CSFML/Window/Keyboard.h exactly. sfKeyUnknown is -1 and represented
  # here by :unknown returned via #code_to_symbol.
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

    # SFML::Keyboard.key_pressed?(:escape)
    def key_pressed?(symbol)
      C::Window.sfKeyboard_isKeyPressed(symbol_to_code(symbol))
    end
  end
end
