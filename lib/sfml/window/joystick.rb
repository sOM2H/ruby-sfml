module SFML
  # Global gamepad / joystick state — peer to Keyboard and Mouse.
  #
  #   if SFML::Joystick.connected?(0)
  #     x = SFML::Joystick.axis_position(0, :x)        # -100.0 .. 100.0
  #     fire = SFML::Joystick.button_pressed?(0, 0)
  #     info = SFML::Joystick.identification(0)
  #     # => { name: "Xbox Controller", vendor_id: 0x045e, product_id: 0x028e }
  #   end
  #
  # SFML supports up to MAX_COUNT joysticks (0..MAX_COUNT-1). Axes are
  # addressed by symbol (:x, :y, :z, :r, :u, :v, :pov_x, :pov_y) so callers
  # don't have to remember the sfJoystickAxis enum order.
  module Joystick
    # Order matches sfJoystickAxis in CSFML/Window/Joystick.h.
    AXES = %i[x y z r u v pov_x pov_y].freeze
    AXIS_INDEX = AXES.each_with_index.to_h.freeze

    # Friendly aliases — POV axes are also called "hat" or "dpad" in some
    # gamepad APIs.
    AXIS_ALIASES = {
      hat_x: :pov_x, hat_y: :pov_y,
      dpad_x: :pov_x, dpad_y: :pov_y,
    }.freeze

    MAX_COUNT        = 8
    MAX_BUTTON_COUNT = 32
    MAX_AXIS_COUNT   = AXES.length

    module_function

    def connected?(joystick)
      C::Window.sfJoystick_isConnected(_id(joystick))
    end

    def button_count(joystick)
      C::Window.sfJoystick_getButtonCount(_id(joystick))
    end

    def has_axis?(joystick, axis)
      C::Window.sfJoystick_hasAxis(_id(joystick), _axis_code(axis))
    end

    # Axis value in the range [-100.0, 100.0]. Returns 0.0 for axes that
    # don't exist on the device, so it's safe to call without first
    # checking has_axis?.
    def axis_position(joystick, axis)
      C::Window.sfJoystick_getAxisPosition(_id(joystick), _axis_code(axis))
    end

    def button_pressed?(joystick, button)
      C::Window.sfJoystick_isButtonPressed(_id(joystick), Integer(button))
    end

    # Returns a Hash {name:, vendor_id:, product_id:} describing the
    # device, or nil if the joystick isn't connected.
    def identification(joystick)
      return nil unless connected?(joystick)
      ident = C::Window.sfJoystick_getIdentification(_id(joystick))
      name_ptr = ident[:name]
      {
        name:       name_ptr.null? ? "" : name_ptr.read_string.force_encoding("UTF-8"),
        vendor_id:  ident[:vendor_id],
        product_id: ident[:product_id],
      }
    end

    # Refresh joystick state. SFML auto-updates as part of pollEvent, so
    # most code never needs this. Call it explicitly only if you're
    # polling joystick state without an active event loop.
    def update
      C::Window.sfJoystick_update
    end

    # @!visibility private
    def _id(joystick)
      n = Integer(joystick)
      raise ArgumentError, "Joystick id must be in 0..#{MAX_COUNT - 1}, got #{n}" if n < 0 || n >= MAX_COUNT
      n
    end

    # @!visibility private
    def _axis_code(axis)
      sym = AXIS_ALIASES.fetch(axis, axis)
      AXIS_INDEX.fetch(sym) do
        raise ArgumentError, "Unknown joystick axis: #{axis.inspect}. Expected: #{AXES.inspect}"
      end
    end
  end
end
