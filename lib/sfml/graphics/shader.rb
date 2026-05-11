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

    # Build a shader from one or more IO-like streams (any object
    # answering read/seek/pos/size). Useful when shader source lives
    # inside an archive or a network resource.
    def self.from_stream(vertex: nil, geometry: nil, fragment: nil)
      _check_at_least_one(vertex, geometry, fragment)
      streams = [vertex, geometry, fragment].map { |io| io && SFML::InputStream.new(io) }
      ptrs    = streams.map { |s| s ? s.to_ptr : nil }
      ptr = C::Graphics.sfShader_createFromStream(*ptrs)
      raise Error, "sfShader_createFromStream failed (GLSL compile error?)" if ptr.null?
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

    # Set a `uniform bvec2/3/4` from a Ruby Array of booleans. Length
    # picks the dimensionality.
    def set_bvec(name, *components)
      flat = components.flatten
      case flat.length
      when 2
        s = C::Graphics::GlslBvec2.new
        s[:x] = !!flat[0]; s[:y] = !!flat[1]
        C::Graphics.sfShader_setBvec2Uniform(@handle, name.to_s, s)
      when 3
        s = C::Graphics::GlslBvec3.new
        s[:x] = !!flat[0]; s[:y] = !!flat[1]; s[:z] = !!flat[2]
        C::Graphics.sfShader_setBvec3Uniform(@handle, name.to_s, s)
      when 4
        s = C::Graphics::GlslBvec4.new
        s[:x] = !!flat[0]; s[:y] = !!flat[1]; s[:z] = !!flat[2]; s[:w] = !!flat[3]
        C::Graphics.sfShader_setBvec4Uniform(@handle, name.to_s, s)
      else
        raise ArgumentError, "bvec uniform must have 2, 3, or 4 components (got #{flat.length})"
      end
    end

    # Set a `uniform mat3` from a 9-element row-major float array (or
    # an SFML::Transform — its 3×3 matrix is read directly).
    def set_mat3(name, matrix)
      values = _coerce_matrix(matrix, 9, "mat3")
      mat = C::Graphics::GlslMat3.new
      values.each_with_index { |v, i| mat[:array][i] = v }
      C::Graphics.sfShader_setMat3Uniform(@handle, name.to_s, mat.pointer)
    end

    # Set a `uniform mat4` from a 16-element row-major float array.
    def set_mat4(name, matrix)
      values = _coerce_matrix(matrix, 16, "mat4")
      mat = C::Graphics::GlslMat4.new
      values.each_with_index { |v, i| mat[:array][i] = v }
      C::Graphics.sfShader_setMat4Uniform(@handle, name.to_s, mat.pointer)
    end

    # Set a `uniform mat3 arr[N];` / `uniform mat4 arr[N];` from a
    # list of matrices (each a 9- or 16-element flat array, or an
    # SFML::Transform for mat3).
    def set_mat3_array(name, matrices)
      _set_mat_array(name, matrices, 9, :sfShader_setMat3UniformArray)
    end

    def set_mat4_array(name, matrices)
      _set_mat_array(name, matrices, 16, :sfShader_setMat4UniformArray)
    end

    # Bind this shader as the active GL program. Useful when you
    # want to issue raw GL draw calls under SFML's context. Pair
    # with `Shader.unbind` to restore SFML's default. Most users
    # don't need this — just pass the shader to `target.draw(...,
    # render_states: SFML::RenderStates.new(shader: self))`.
    def bind = C::Graphics.sfShader_bind(@handle)

    def self.unbind = C::Graphics.sfShader_bind(nil)

    # The OpenGL program ID. Useful for debug printf / interop
    # with raw GL libraries.
    def native_handle = C::Graphics.sfShader_getNativeHandle(@handle)

    # Set a `vec4` uniform from an integer-channel `SFML::Color`
    # (RGBA 0–255). Equivalent to writing `[c.r/255, ..., c.a/255]`
    # by hand into a vec4 — the CSFML helper does the divide for
    # you.
    def set_int_color(name, color)
      raise ArgumentError, "expected SFML::Color" unless color.is_a?(Color)
      C::Graphics.sfShader_setIntColorUniform(@handle, name.to_s, color.to_native)
    end

    attr_reader :handle # :nodoc:

    private

    def _coerce_matrix(matrix, expected_length, label)
      values =
        case matrix
        when Transform then matrix.matrix
        when Array     then matrix.flatten
        else
          raise ArgumentError, "#{label} uniform requires an Array or SFML::Transform (got #{matrix.class})"
        end
      unless values.length == expected_length
        raise ArgumentError, "#{label} uniform needs #{expected_length} elements (got #{values.length})"
      end
      values.map(&:to_f)
    end

    def _set_mat_array(name, matrices, stride, setter)
      raise ArgumentError, "matrix array must not be empty" if matrices.empty?

      label = stride == 9 ? "mat3" : "mat4"
      flat = matrices.flat_map { |m| _coerce_matrix(m, stride, label) }
      buf  = FFI::MemoryPointer.new(:float, flat.length)
      buf.write_array_of_float(flat)
      C::Graphics.public_send(setter, @handle, name.to_s, buf, matrices.length)
    end

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
