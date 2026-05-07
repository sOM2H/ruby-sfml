module SFML
  # Batched geometry: a single CSFML draw call shipping many vertices to
  # the GPU at once. This is how you draw thousands of particles, custom
  # meshes, or tile maps without the per-shape overhead.
  #
  #   va = SFML::VertexArray.new(:triangles)
  #   va << SFML::Vertex.new([100, 100], color: SFML::Color.red)
  #   va << SFML::Vertex.new([200, 100], color: SFML::Color.green)
  #   va << SFML::Vertex.new([150, 200], color: SFML::Color.blue)
  #   window.draw(va)
  #
  # Primitive types control how vertices form geometry:
  #   :points          one isolated point per vertex
  #   :lines           pairs of vertices form line segments
  #   :line_strip      consecutive vertices form a chain of segments
  #   :triangles       triples form independent triangles
  #   :triangle_strip  each new vertex extends the strip
  #   :triangle_fan    every vertex shares a fan-out with vertex 0
  class VertexArray
    include Enumerable

    # Order matches sfPrimitiveType in CSFML/Graphics/PrimitiveType.h.
    PRIMITIVE_TYPES = %i[points lines line_strip triangles triangle_strip triangle_fan].freeze
    PRIMITIVE_INDEX = PRIMITIVE_TYPES.each_with_index.to_h.freeze

    def initialize(primitive_type = :points, vertices = nil)
      ptr = C::Graphics.sfVertexArray_create
      raise Error, "sfVertexArray_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfVertexArray_destroy))

      self.primitive_type = primitive_type
      vertices&.each { |v| append(v) }
    end

    def primitive_type
      PRIMITIVE_TYPES[C::Graphics.sfVertexArray_getPrimitiveType(@handle)] || :unknown
    end

    def primitive_type=(type)
      code = PRIMITIVE_INDEX.fetch(type) do
        raise ArgumentError,
              "Unknown primitive type: #{type.inspect}. Expected one of: #{PRIMITIVE_TYPES.inspect}"
      end
      C::Graphics.sfVertexArray_setPrimitiveType(@handle, code)
    end

    def size = C::Graphics.sfVertexArray_getVertexCount(@handle)
    alias length size
    alias count  size

    def empty? = size.zero?

    def clear
      C::Graphics.sfVertexArray_clear(@handle)
      self
    end

    def resize(n)
      C::Graphics.sfVertexArray_resize(@handle, Integer(n))
      self
    end

    def append(vertex)
      C::Graphics.sfVertexArray_append(@handle, vertex.to_native)
      self
    end
    alias << append

    # Read a vertex by index, or nil if out of range. Returns a fresh
    # SFML::Vertex copy — mutate via `va[i] = new_vertex` to write back,
    # not through the returned object.
    def [](index)
      i = Integer(index)
      return nil if i < 0 || i >= size
      ptr = C::Graphics.sfVertexArray_getVertex(@handle, i)
      Vertex.from_native(C::Graphics::Vertex.new(ptr))
    end

    def []=(index, vertex)
      i = Integer(index)
      # CSFML's sfVertexArray_getVertex aborts the process on out-of-range
      # access (it asserts), so we have to bounds-check on the Ruby side.
      raise IndexError, "vertex index #{i} out of range (size: #{size})" if i < 0 || i >= size

      ptr = C::Graphics.sfVertexArray_getVertex(@handle, i)
      cv = C::Graphics::Vertex.new(ptr)
      cv[:position][:x]   = vertex.position.x.to_f
      cv[:position][:y]   = vertex.position.y.to_f
      cv[:color][:r]      = vertex.color.r
      cv[:color][:g]      = vertex.color.g
      cv[:color][:b]      = vertex.color.b
      cv[:color][:a]      = vertex.color.a
      cv[:tex_coords][:x] = vertex.tex_coords.x.to_f
      cv[:tex_coords][:y] = vertex.tex_coords.y.to_f
      vertex
    end

    def each
      return enum_for(:each) unless block_given?
      size.times { |i| yield self[i] }
      self
    end

    def bounds
      Rect.from_native(C::Graphics.sfVertexArray_getBounds(@handle))
    end

    def draw_on(target, states_ptr = nil) # :nodoc:
      target._draw_native(:VertexArray, @handle, states_ptr)
    end

    attr_reader :handle # :nodoc:
  end
end
