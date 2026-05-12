module SFML
  # GPU-resident vertex buffer. Same shape as VertexArray but the
  # vertices live in video memory, so a draw call only ships an
  # index/handle instead of re-uploading the geometry every frame.
  # Useful for static meshes, large tilemaps, particle systems with
  # mostly-static positions.
  #
  #   buf = SFML::VertexBuffer.new(
  #     vertices,
  #     primitive_type: :triangles,
  #     usage:          :static,
  #   )
  #   window.draw(buf)
  #
  # Update later (full or partial):
  #
  #   buf.update(new_vertices)              # full replace
  #   buf.update(some_vertices, offset: 32) # patch in place
  #
  # If the GPU doesn't support OpenGL vertex buffer objects,
  # `SFML::VertexBuffer.available?` returns false and you should
  # fall back to `VertexArray`.
  class VertexBuffer
    # VBO usage hints in CSFML enum order.
    USAGES       = C::Graphics::VERTEX_BUFFER_USAGES
    # Usage symbol → integer Hash.
    USAGE_INDEX  = USAGES.each_with_index.to_h.freeze

    # Primitive type symbols in `sfPrimitiveType` order.
    PRIMITIVE_TYPES = VertexArray::PRIMITIVE_TYPES
    # Primitive symbol → integer index Hash.
    PRIMITIVE_INDEX = VertexArray::PRIMITIVE_INDEX

    # Returns the self.
    def self.available?
      C::Graphics.sfVertexBuffer_isAvailable
    end

    # Build a buffer either from an Array of vertices or by giving an
    # explicit `count:` to allocate empty (then fill via #update).
    def initialize(vertices = nil, count: nil, primitive_type: :points, usage: :stream)
      n = vertices ? vertices.length : Integer(count || 0)
      raise ArgumentError, "give either `vertices` or `count:`" if n.zero? && vertices.nil?

      ptype = PRIMITIVE_INDEX.fetch(primitive_type) do
        raise ArgumentError,
              "Unknown primitive type: #{primitive_type.inspect} " \
              "(expected one of #{PRIMITIVE_TYPES.inspect})"
      end
      uidx = USAGE_INDEX.fetch(usage) do
        raise ArgumentError,
              "Unknown VertexBuffer usage: #{usage.inspect} " \
              "(expected one of #{USAGES.inspect})"
      end

      ptr = C::Graphics.sfVertexBuffer_create(n, ptype, uidx)
      raise GraphicsError, "sfVertexBuffer_create returned NULL " \
                   "(VBOs unavailable on this GPU?)" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfVertexBuffer_destroy))

      update(vertices) if vertices && !vertices.empty?
    end

    # Returns the count.
    def count = C::Graphics.sfVertexBuffer_getVertexCount(@handle)
    alias size  count
    alias length count

    # Returns the primitive type.
    def primitive_type
      PRIMITIVE_TYPES[C::Graphics.sfVertexBuffer_getPrimitiveType(@handle)] || :unknown
    end

    # Set the primitive type.
    def primitive_type=(type)
      idx = PRIMITIVE_INDEX.fetch(type) do
        raise ArgumentError, "Unknown primitive type: #{type.inspect}"
      end
      C::Graphics.sfVertexBuffer_setPrimitiveType(@handle, idx)
    end

    # Returns the usage.
    def usage
      USAGES[C::Graphics.sfVertexBuffer_getUsage(@handle)] || :unknown
    end

    # Set the usage.
    def usage=(value)
      idx = USAGE_INDEX.fetch(value) do
        raise ArgumentError, "Unknown VertexBuffer usage: #{value.inspect}"
      end
      C::Graphics.sfVertexBuffer_setUsage(@handle, idx)
    end

    # Replace `vertices.length` slots starting at `offset`. Pass an
    # array longer than the buffer to grow it (CSFML expands when
    # offset==0 and length > current).
    def update(vertices, offset: 0)
      n   = vertices.length
      buf = FFI::MemoryPointer.new(C::Graphics::Vertex, n)
      vertices.each_with_index do |v, i|
        slot = C::Graphics::Vertex.new(buf + i * C::Graphics::Vertex.size)
        slot[:position][:x]   = v.position.x.to_f
        slot[:position][:y]   = v.position.y.to_f
        slot[:color][:r]      = v.color.r
        slot[:color][:g]      = v.color.g
        slot[:color][:b]      = v.color.b
        slot[:color][:a]      = v.color.a
        slot[:tex_coords][:x] = v.tex_coords.x.to_f
        slot[:tex_coords][:y] = v.tex_coords.y.to_f
      end

      ok = C::Graphics.sfVertexBuffer_update(@handle, buf, n, Integer(offset))
      raise GraphicsError, "sfVertexBuffer_update failed " \
                   "(buffer too small or driver rejected the upload?)" unless ok
      self
    end

    # Returns the native handle.
    def native_handle = C::Graphics.sfVertexBuffer_getNativeHandle(@handle)

    # Bind this VBO as the active vertex buffer for the GL pipeline.
    # Useful when mixing raw GL with SFML rendering — pair with
    # `SFML::VertexBuffer.unbind` (or any other draw) to release.
    def bind
      C::Graphics.sfVertexBuffer_bind(@handle)
      self
    end

    # Returns the self.
    def self.unbind
      C::Graphics.sfVertexBuffer_bind(nil)
    end

    # Returns the draw on.
    def draw_on(target, states_ptr = nil) # :nodoc:
      target._draw_native(:VertexBuffer, @handle, states_ptr)
    end

    # Draw a slice of this buffer instead of the whole thing. Useful
    # when you've packed several meshes back-to-back and want to
    # render one at a time.
    def draw_range_on(target, first, count, states_ptr = nil)
      C::Graphics.public_send(
        :"#{target.class::CSFML_PREFIX}_drawVertexBufferRange",
        target.handle, @handle, Integer(first), Integer(count), states_ptr,
      )
    end

    attr_reader :handle # :nodoc:
  end
end
