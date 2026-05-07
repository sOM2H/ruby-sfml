module SFML
  # A window event. Holds a type symbol and a Hash of type-specific data.
  # Pattern-match it directly; that's the intended interface:
  #
  #   case event
  #   in {type: :closed}                              then ...
  #   in {type: :key_pressed, code: :escape}          then ...
  #   in {type: :resized, size:}                      then ...
  #   in {type: :mouse_moved, position: {x:, y:}}     then ...
  #   in {type: :mouse_wheel_scrolled, delta:}        then ...
  #   end
  #
  # Type-specific fields are also reachable as plain methods (`event.code`,
  # `event.position`) for the cases when pattern matching is overkill.
  class Event
    # Order matches sfMouseButton in CSFML 3: left, right, middle,
    # extra1, extra2. (CSFML 2 called the last two x_button1/x_button2,
    # but SFML 3 dropped the X-button terminology.)
    MOUSE_BUTTONS = %i[left right middle extra1 extra2].freeze
    MOUSE_WHEELS  = %i[vertical horizontal].freeze

    attr_reader :type, :data

    def initialize(type, data = {})
      @type = type
      @data = data.freeze
      freeze
    end

    def [](key)        = @data[key]
    def fetch(*args, &) = @data.fetch(*args, &)

    def deconstruct_keys(_keys)
      { type: @type, **@data }
    end

    def respond_to_missing?(name, _private = false)
      @data.key?(name) || super
    end

    def method_missing(name, *args)
      return @data[name] if args.empty? && @data.key?(name)
      super
    end

    def to_s = "#<SFML::Event #{@type} #{@data.inspect}>"
    alias inspect to_s

    # Reads the sfEvent union buffer, decodes the discriminator, and reads
    # the type-specific variant. CSFML lays each variant out with the
    # sfEventType as the first field, so we can re-interpret the same memory
    # as the right struct.
    def self.from_native(buffer)
      type_index = buffer[:type]
      type_sym   = C::Window::EVENT_TYPES[type_index] || :unknown

      data = decode(type_sym, buffer.to_ptr)
      new(type_sym, data)
    end

    def self.decode(type_sym, ptr)
      case type_sym
      when :closed, :focus_lost, :focus_gained,
           :mouse_entered, :mouse_left
        EMPTY

      when :resized
        s = C::Window::SizeEvent.new(ptr)
        { size: Vector2.new(s[:size][:x], s[:size][:y]) }

      when :key_pressed, :key_released
        k = C::Window::KeyEvent.new(ptr)
        {
          code:    Keyboard.code_to_symbol(k[:code]),
          alt:     k[:alt],
          control: k[:control],
          shift:   k[:shift],
          system:  k[:system],
        }

      when :text_entered
        t = C::Window::TextEvent.new(ptr)
        { unicode: t[:unicode], char: [t[:unicode]].pack("U*") }

      when :mouse_moved
        m = C::Window::MouseMoveEvent.new(ptr)
        { position: Vector2.new(m[:position][:x], m[:position][:y]) }

      when :mouse_moved_raw
        m = C::Window::MouseMoveEvent.new(ptr)
        # Raw event re-uses the same struct shape but the field is a delta.
        { delta: Vector2.new(m[:position][:x], m[:position][:y]) }

      when :mouse_button_pressed, :mouse_button_released
        b = C::Window::MouseButtonEvent.new(ptr)
        {
          button:   MOUSE_BUTTONS[b[:button]] || :unknown,
          position: Vector2.new(b[:position][:x], b[:position][:y]),
        }

      when :mouse_wheel_scrolled
        w = C::Window::MouseWheelScrollEvent.new(ptr)
        {
          wheel:    MOUSE_WHEELS[w[:wheel]] || :unknown,
          delta:    w[:delta],
          position: Vector2.new(w[:position][:x], w[:position][:y]),
        }

      when :joystick_button_pressed, :joystick_button_released
        b = C::Window::JoystickButtonEvent.new(ptr)
        { joystick_id: b[:joystick_id], button: b[:button] }

      when :joystick_moved
        m = C::Window::JoystickMoveEvent.new(ptr)
        {
          joystick_id: m[:joystick_id],
          axis:        Joystick::AXES[m[:axis]] || :unknown,
          position:    m[:position],
        }

      when :joystick_connected, :joystick_disconnected
        c = C::Window::JoystickConnectEvent.new(ptr)
        { joystick_id: c[:joystick_id] }

      else
        EMPTY
      end
    end

    EMPTY = {}.freeze
    private_constant :EMPTY
  end
end
