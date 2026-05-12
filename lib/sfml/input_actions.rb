module SFML
  # Class-level `action` DSL — named bindings over multiple physical
  # inputs. Shared by `SFML::App` and `SFML::Scene`. Pairs with the
  # `Keybindings` mixin: keybindings fire **events** (one-shot, on
  # press), actions are **polled state** ("is the user holding this
  # right now?").
  #
  #   class MyGame < SFML::App
  #     action :jump,    keys: [:space, :w]
  #     action :fire,    mouse_buttons: [:left]
  #     action :left,    keys: [:a, :left],    scancodes: [:scan_a]
  #     action :right,   keys: [:d, :right]
  #     action :crouch,  joy_buttons: [[0, 0]]  # joystick 0, button 0
  #
  #     def update(dt)
  #       speed = 200 * dt.as_seconds
  #       @x += speed if action_pressed?(:right)
  #       @x -= speed if action_pressed?(:left)
  #       @ball.jump if action_pressed?(:jump)
  #     end
  #   end
  #
  # Keys are mapped via `SFML::Keyboard.key_pressed?` — the
  # **logical** key under the current OS layout. Scancodes are
  # mapped via `SFML::Keyboard.scancode_pressed?` — the **physical**
  # position (recommended for WASD-style movement so the keys stay
  # under the same fingers across layouts).
  #
  # `axis(:name)` is a convenience for digital pairs: pass `negative:`
  # and `positive:` actions and you get a Float in [-1, 1].
  #
  #   class Player < SFML::App
  #     action :go_left,  keys: [:a, :left]
  #     action :go_right, keys: [:d, :right]
  #
  #     def update(dt)
  #       move = axis(negative: :go_left, positive: :go_right)
  #       @x += move * 200 * dt.as_seconds
  #     end
  #   end
  module InputActions
    # Class-side: declare a named action.
    #
    # @param name [Symbol] action identifier
    # @param keys [Array<Symbol>] logical key symbols (see Keyboard::KEY_CODES)
    # @param scancodes [Array<Symbol>] physical scancode symbols (see Keyboard::SCAN_CODES)
    # @param mouse_buttons [Array<Symbol>] :left / :right / :middle / :extra1 / :extra2
    # @param joy_buttons [Array<Array<Integer>>] [[joystick_id, button_id], ...]
    def action(name, keys: [], scancodes: [], mouse_buttons: [], joy_buttons: [])
      @action_bindings ||= {}
      @action_bindings[name.to_sym] = {
        keys:          Array(keys).map(&:to_sym),
        scancodes:     Array(scancodes).map(&:to_sym),
        mouse_buttons: Array(mouse_buttons).map(&:to_sym),
        joy_buttons:   Array(joy_buttons).map { |pair| Array(pair).map(&:to_i) },
      }
    end

    # `Hash{action_name => bindings}` — own bindings layered over the
    # parent's. Subclass `action` calls add to the inherited set.
    def action_bindings
      own    = (@action_bindings ||= {})
      parent = superclass.respond_to?(:action_bindings) ? superclass.action_bindings : {}
      parent.merge(own)
    end
  end

  # Instance-side helpers — included into App and Scene so user code
  # can call `action_pressed?` / `axis` from `#update` etc.
  module InputQueries
    # `true` if any input bound to `action_name` is currently held.
    # Looks up bindings on `self.class.action_bindings` (App-style)
    # or falls back to the host App when called from a Scene.
    def action_pressed?(action_name)
      bindings = _resolve_action_bindings[action_name.to_sym]
      return false unless bindings

      bindings[:keys].any?           { |k| Keyboard.key_pressed?(k) }       ||
        bindings[:scancodes].any?    { |s| Keyboard.scancode_pressed?(s) }  ||
        bindings[:mouse_buttons].any? { |b| Mouse.button_pressed?(b) }      ||
        bindings[:joy_buttons].any?  { |(j, b)| Joystick.button_pressed?(j, b) }
    end

    # Synthetic digital axis from two opposing actions. Returns -1.0,
    # 0.0, or +1.0 — never both 1 and -1 (positive wins if both held).
    def axis(negative:, positive:)
      pos = action_pressed?(positive) ? 1.0 : 0.0
      neg = action_pressed?(negative) ? 1.0 : 0.0
      pos - neg
    end

    private

    # When called from a Scene, look up actions on the host App's
    # class first so scene-only code reads global actions naturally.
    # When the receiver IS the App, just use its own class.
    def _resolve_action_bindings
      if respond_to?(:host) && (h = host) && h.class.respond_to?(:action_bindings)
        h.class.action_bindings.merge(self.class.action_bindings)
      else
        self.class.action_bindings
      end
    end
  end
end
