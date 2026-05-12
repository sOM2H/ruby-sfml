module SFML
  # Class-level `on_key` DSL — shared by `SFML::App` and `SFML::Scene`.
  # Each class that extends this module gets:
  #
  #   * `on_key(code, :method_name)` — bind a key to an instance method
  #   * `on_key(code, ->(receiver) { ... })` — bind to a Proc
  #   * `on_key(code) { |receiver| ... }` — bind to a block
  #
  # Inheritance: a subclass's bindings layer on top of the parent's,
  # so `class Sub < Parent; on_key :x, :foo; end` keeps the parent's
  # other bindings while overriding (or adding) `:x`.
  module Keybindings
    # Returns the on key.
    def on_key(code, target = nil, &block)
      @key_handlers ||= {}
      handler = block || target
      raise ArgumentError, "on_key needs a target Symbol/Proc or a block" unless handler
      @key_handlers[code.to_sym] = handler
    end

    # `Hash{key_code => handler}` — own bindings layered over the
    # parent's (own keys win).
    def key_handlers
      own    = (@key_handlers ||= {})
      parent = superclass.respond_to?(:key_handlers) ? superclass.key_handlers : {}
      parent.merge(own)
    end
  end
end
