module SFML
  # Global mouse state — peer to SFML::Keyboard. Use it for "is this
  # button held right now?" and for current pointer coordinates outside
  # of the event loop.
  #
  #   SFML::Mouse.button_pressed?(:left)    #=> true while LMB is held
  #   SFML::Mouse.position                  #=> Vector2 — desktop coords
  #   SFML::Mouse.position(window)          #=> Vector2 — relative to window
  #   SFML::Mouse.set_position([400, 300], window)
  #
  # Buttons are addressed by symbol; the raw sfMouseButton enum order is
  # exposed via BUTTONS for users who need it.
  module Mouse
    BUTTONS = %i[left right middle extra1 extra2].freeze
    BUTTON_INDEX = BUTTONS.each_with_index.to_h.freeze

    # Friendly aliases — SFML 2 used "X-button" terminology; some users
    # still reach for it.
    ALIASES = {
      x1:        :extra1,
      x2:        :extra2,
      x_button1: :extra1,
      x_button2: :extra2,
    }.freeze

    module_function

    # Returns true if the named mouse button is currently held.
    def button_pressed?(button)
      C::Window.sfMouse_isButtonPressed(_code(button))
    end

    # Pointer position. With no argument, returns desktop-relative
    # coordinates. With a RenderWindow, returns coordinates relative to
    # that window's client area (top-left = 0, 0).
    def position(window = nil)
      vec = if window
              C::Graphics.sfMouse_getPositionRenderWindow(window.handle)
            else
              C::Window.sfMouse_getPosition(nil)
            end
      Vector2.new(vec[:x], vec[:y])
    end

    # Move the OS pointer. Without `window`, the coordinates are desktop-
    # relative. Useful for FPS-style mouse-look (warp the cursor back to
    # screen centre each frame).
    def set_position(point, window = nil)
      px, py = point.is_a?(Vector2) ? [point.x, point.y] : point
      vec = C::System::Vector2i.new
      vec[:x] = Integer(px)
      vec[:y] = Integer(py)

      if window
        C::Graphics.sfMouse_setPositionRenderWindow(vec, window.handle)
      else
        C::Window.sfMouse_setPosition(vec, nil)
      end
    end

    # @!visibility private
    def _code(button)
      sym = ALIASES.fetch(button, button)
      BUTTON_INDEX.fetch(sym) do
        raise ArgumentError,
              "Unknown mouse button: #{button.inspect}. " \
              "Expected one of: #{BUTTONS.inspect}"
      end
    end
  end
end
