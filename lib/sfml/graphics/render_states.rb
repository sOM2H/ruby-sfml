module SFML
  # The state passed alongside a draw call: blend mode, texture, shader,
  # transform, coordinate type. You rarely instantiate this directly —
  # `window.draw(...)` accepts `blend_mode:`, `texture:`, etc. shortcuts
  # that build a RenderStates internally. Construct one yourself when
  # you need to keep the same combination across many draws:
  #
  #   states = SFML::RenderStates.new(
  #     blend_mode: SFML::BlendMode::ADD,
  #     texture:    glow_texture,
  #   )
  #   window.draw(va,    render_states: states)
  #   window.draw(other, render_states: states)
  #
  # All fields default to the CSFML `sfRenderStates_default` value.
  class RenderStates
    COORDINATE_TYPES = %i[normalized pixels].freeze
    COORDINATE_INDEX = COORDINATE_TYPES.each_with_index.to_h.freeze

    attr_reader :blend_mode, :texture, :shader, :coordinate_type

    def initialize(blend_mode: nil, texture: nil, shader: nil, coordinate_type: :normalized)
      @blend_mode      = blend_mode
      @texture         = texture
      @shader          = shader   # placeholder until SFML::Shader lands in the next P1 step
      @coordinate_type = coordinate_type
      raise ArgumentError, "unknown coordinate_type: #{coordinate_type.inspect}" unless COORDINATE_INDEX.key?(coordinate_type)
      freeze
    end

    # @!visibility private
    # Allocate and populate a sfRenderStates buffer. Returns an
    # FFI::MemoryPointer ready to pass as the `const sfRenderStates*`
    # argument of a CSFML draw function.
    def to_native_pointer
      buffer = C::Graphics::RenderStates.new
      # Start from the CSFML default so we get sane stencil + transform.
      C::Graphics.sfRenderStates_default.pointer.read_bytes(C::Graphics::RenderStates.size)
        .then { |bytes| buffer.pointer.write_bytes(bytes) }

      @blend_mode&.populate(buffer[:blend_mode])
      buffer[:coordinate_type] = COORDINATE_INDEX[@coordinate_type]
      buffer[:texture] = @texture ? @texture.handle : nil
      buffer[:shader]  = @shader  ? @shader.handle  : nil
      buffer.pointer
    end

    # Convenience: build a RenderStates from the same shortcut kwargs
    # that RenderTarget#draw accepts. Returns nil if no opts given (so
    # the draw call uses the CSFML default without allocating anything).
    def self.from_draw_opts(opts)
      return nil if opts.empty?
      new(**opts)
    end
  end
end
