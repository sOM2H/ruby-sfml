module SFML
  # Polling API for touchscreen input. Each finger is identified by an
  # integer (0 = first contact, 1 = second, etc.). The same fingers
  # also surface through the event loop as `:touch_began`,
  # `:touch_moved`, `:touch_ended` events with `finger:` and
  # `position:` fields.
  #
  #   if SFML::Touch.down?(0)
  #     pos = SFML::Touch.position(0, relative_to: window)
  #     ...
  #   end
  #
  # On desktop platforms without touchscreen hardware these always
  # return `false` / `[0, 0]`.
  module Touch
    module_function

    # True while finger `n` is currently in contact with the screen.
    def down?(finger = 0)
      C::Window.sfTouch_isDown(Integer(finger))
    end

    # Position of finger `n`. Without `relative_to:`, returns
    # desktop-relative coordinates; pass a Window or RenderWindow to
    # get window-local coordinates.
    def position(finger = 0, relative_to: nil)
      f = Integer(finger)
      vec =
        case relative_to
        when nil          then C::Window.sfTouch_getPosition(f, nil)
        when RenderWindow then C::Graphics.sfTouch_getPositionRenderWindow(f, relative_to.handle)
        when Window       then C::Window.sfTouch_getPosition(f, relative_to.handle)
        else
          raise ArgumentError, "relative_to: must be SFML::Window, SFML::RenderWindow, or nil"
        end
      Vector2.new(vec[:x], vec[:y])
    end
  end
end
