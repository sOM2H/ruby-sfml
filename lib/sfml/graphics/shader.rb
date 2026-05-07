module SFML
  # A GLSL shader. Build one from a vertex and/or fragment source (either
  # a file path or a literal source string), then set uniforms with
  # bracket assignment and pass it to draw via the `shader:` kwarg:
  #
  #   shader = SFML::Shader.from_source(fragment: <<~GLSL)
  #     uniform sampler2D texture;
  #     uniform float time;
  #     void main() {
  #       vec2 uv = gl_TexCoord[0].xy;
  #       uv.x += sin(uv.y * 20.0 + time * 3.0) * 0.02;
  #       gl_FragColor = texture2D(texture, uv) * gl_Color;
  #     }
  #   GLSL
  #
  #   shader[:time] = clock.elapsed.as_seconds
  #   window.draw(sprite, shader: shader)
  #
  # Uniform types are inferred from the Ruby value:
  #   Float / Integer / Numeric  → float (uniform float)
  #   true / false               → bool
  #   SFML::Vector2              → vec2
  #   SFML::Vector3              → vec3
  #   SFML::Color                → vec4 (normalised RGBA)
  #   SFML::Texture              → sampler2D
  #   :current_texture (Symbol)  → sampler2D bound to the drawable's own texture
  #   [a, b]                     → vec2     (floats)
  #   [a, b, c]                  → vec3
  #   [a, b, c, d]               → vec4
  #
  # Array uniforms (`uniform vec2 positions[8];` and friends):
  #   [[x, y], [x, y], ...]      → vec2[]
  #   [[x, y, z], ...]           → vec3[]
  #   [[x, y, z, w], ...]        → vec4[]
  #   [Vector2[a, b], ...]       → vec2[]   (also accepts Vector2 / Vector3)
  #
  # Float arrays (`uniform float weights[N];`) are ambiguous with vec3
  # at length 3, so use the explicit `#set_float_array` setter.
  #
  # Need an int / bvec / matrix uniform? Use `#set_int`, `#set_ivec2`,
  # etc. — they exist for completeness.
  class Shader
    # Class-level: is GLSL available on the current GPU at all?
    def self.available?
      C::Graphics.sfShader_isAvailable
    end

    def self.geometry_available?
      C::Graphics.sfShader_isGeometryAvailable
    end

    # Build a shader from one or more source files. Any of vertex /
    # geometry / fragment may be omitted; at least one must be present.
    def self.from_file(vertex: nil, geometry: nil, fragment: nil)
      _check_at_least_one(vertex, geometry, fragment)
      ptr = C::Graphics.sfShader_createFromFile(
        vertex&.to_s, geometry&.to_s, fragment&.to_s,
      )
      raise Error, "sfShader_createFromFile failed (compile error or missing file?)" if ptr.null?
      _wrap(ptr)
    end

    # Build a shader directly from GLSL source strings.
    def self.from_source(vertex: nil, geometry: nil, fragment: nil)
      _check_at_least_one(vertex, geometry, fragment)
      ptr = C::Graphics.sfShader_createFromMemory(vertex, geometry, fragment)
      raise Error, "sfShader_createFromMemory failed (GLSL compile error?)" if ptr.null?
      _wrap(ptr)
    end

    # Set a uniform by name. Dispatches to the right CSFML setter based
    # on the Ruby value's type — see the class-level docs for the table.
    def []=(name, value)
      n = name.to_s
      case value
      when true, false
        C::Graphics.sfShader_setBoolUniform(@handle, n, value)
      when Integer
        C::Graphics.sfShader_setFloatUniform(@handle, n, value.to_f)
      when Numeric
        C::Graphics.sfShader_setFloatUniform(@handle, n, value.to_f)
      when Vector2
        v = C::System::Vector2f.new
        v[:x] = value.x.to_f; v[:y] = value.y.to_f
        C::Graphics.sfShader_setVec2Uniform(@handle, n, v)
      when Vector3
        v = C::System::Vector3f.new
        v[:x] = value.x.to_f; v[:y] = value.y.to_f; v[:z] = value.z.to_f
        C::Graphics.sfShader_setVec3Uniform(@handle, n, v)
      when Color
        C::Graphics.sfShader_setColorUniform(@handle, n, value.to_native)
      when Texture
        C::Graphics.sfShader_setTextureUniform(@handle, n, value.handle)
      when :current_texture
        C::Graphics.sfShader_setCurrentTextureUniform(@handle, n)
      when Array
        raise ArgumentError, "Shader uniform array must not be empty" if value.empty?

        first = value.first
        if first.is_a?(Array) || first.is_a?(Vector2) || first.is_a?(Vector3)
          _set_vec_array_uniform(n, value)
        else
          case value.length
          when 2 then self[name] = Vector2.new(*value)
          when 3 then self[name] = Vector3.new(*value)
          when 4
            v = C::Graphics::GlslVec4.new
            v[:x] = value[0].to_f; v[:y] = value[1].to_f
            v[:z] = value[2].to_f; v[:w] = value[3].to_f
            C::Graphics.sfShader_setVec4Uniform(@handle, n, v)
          else
            raise ArgumentError, "Shader uniform array must be length 2, 3, or 4 (got #{value.length})"
          end
        end
      else
        raise ArgumentError,
              "Shader uniform value must be Numeric, Vector2/3, Color, Texture, " \
              "Array of 2-4 numbers, or :current_texture (got #{value.class})"
      end
    end

    # Explicit integer setters when a uniform really is `uniform int n`.
    def set_int(name, value)
      C::Graphics.sfShader_setIntUniform(@handle, name.to_s, Integer(value))
    end

    def set_ivec2(name, x, y)
      v = C::System::Vector2i.new
      v[:x] = Integer(x); v[:y] = Integer(y)
      C::Graphics.sfShader_setIvec2Uniform(@handle, name.to_s, v)
    end

    # Set a `uniform float arr[N];` from a plain Ruby array of numbers.
    # Float arrays can't be inferred via `[]=` because they'd collide
    # with the vec3 case at length 3.
    def set_float_array(name, values)
      buf = FFI::MemoryPointer.new(:float, values.length)
      buf.write_array_of_float(values.map(&:to_f))
      C::Graphics.sfShader_setFloatUniformArray(@handle, name.to_s, buf, values.length)
    end

    attr_reader :handle # :nodoc:

    private

    # Detect the inner length (2/3/4), pack a contiguous float buffer,
    # and dispatch to the matching CSFML setVec*UniformArray.
    def _set_vec_array_uniform(name, elements)
      raise ArgumentError, "uniform array must not be empty" if elements.empty?

      flat = elements.flat_map do |el|
        case el
        when Vector2 then [el.x.to_f, el.y.to_f]
        when Vector3 then [el.x.to_f, el.y.to_f, el.z.to_f]
        when Array   then el.map(&:to_f)
        else
          raise ArgumentError, "uniform array element must be Array/Vector2/Vector3 (got #{el.class})"
        end
      end

      stride = flat.length / elements.length
      raise ArgumentError, "uniform array elements must all be the same length" \
        unless flat.length == stride * elements.length

      buf = FFI::MemoryPointer.new(:float, flat.length)
      buf.write_array_of_float(flat)

      case stride
      when 2 then C::Graphics.sfShader_setVec2UniformArray(@handle, name, buf, elements.length)
      when 3 then C::Graphics.sfShader_setVec3UniformArray(@handle, name, buf, elements.length)
      when 4 then C::Graphics.sfShader_setVec4UniformArray(@handle, name, buf, elements.length)
      else
        raise ArgumentError, "uniform array elements must be length 2, 3, or 4 (got #{stride})"
      end
    end

    public

    # @!visibility private
    def self._wrap(ptr)
      shader = allocate
      shader.instance_variable_set(:@handle, FFI::AutoPointer.new(ptr, C::Graphics.method(:sfShader_destroy)))
      shader
    end

    # @!visibility private
    def self._check_at_least_one(*sources)
      return unless sources.compact.empty?
      raise ArgumentError, "Shader needs at least one of vertex:, geometry:, fragment:"
    end
  end
end
