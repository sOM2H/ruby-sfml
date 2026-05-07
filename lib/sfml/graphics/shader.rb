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
  # Need an int / bvec / matrix / array uniform? Use the explicit setters
  # (#set_int, #set_ivec2, etc.) — they exist for completeness.
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

    attr_reader :handle # :nodoc:

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
