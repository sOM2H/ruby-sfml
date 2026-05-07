module SFML
  # A 2D affine transformation. Wraps the 3×3 matrix that SFML uses to
  # combine translation, rotation, scaling, and skew. Useful when you
  # want to:
  #
  #   - Apply the same transform across many drawables (push it via
  #     `RenderStates.new(transform: …)` instead of repeating
  #     `position=`/`rotation=` on every shape).
  #   - Build a transform from primitive ops without holding a Drawable.
  #
  #   t = SFML::Transform.identity
  #         .translate([400, 300])
  #         .rotate(30)
  #         .scale([2, 2])
  #
  #   t.transform_point([10, 0])    #=> Vector2(world coord after t)
  #   inv = t.inverse                #=> reverse mapping
  #
  # Methods are chainable and **mutate in place**, returning self. To
  # work with a fresh copy use `t.dup`. The CSFML constant for the
  # identity is exposed via `Transform.identity`.
  class Transform
    def initialize
      @struct = C::Graphics::Transform.new
      # Start as identity by copying CSFML's sfTransform_Identity.
      identity_bytes = C::Graphics.sfTransform_Identity.pointer.read_bytes(C::Graphics::Transform.size)
      @struct.pointer.write_bytes(identity_bytes)
    end

    def self.identity
      new
    end

    # Build from a flat row-major 9-element float array. Lays out as:
    #   [a, b, c,
    #    d, e, f,
    #    g, h, i]   # SFML stores the 3x3 conceptually as a 4x4 padded
    def self.from_matrix(arr)
      raise ArgumentError, "expected 9-element matrix, got #{arr.length}" if arr.length != 9
      t = new
      9.times { |i| t.struct[:matrix][i] = arr[i].to_f }
      t
    end

    def initialize_dup(other)
      super
      @struct = C::Graphics::Transform.new
      @struct.pointer.write_bytes(other.struct.pointer.read_bytes(C::Graphics::Transform.size))
    end

    # Apply a translation. Mutates self.
    def translate(offset)
      vec = _vec2(offset)
      C::Graphics.sfTransform_translate(@struct.pointer, vec.to_native_f)
      self
    end

    # Apply a rotation by `degrees`. Optional `center` to pivot around
    # a non-origin point.
    def rotate(degrees, center: nil)
      if center
        c = _vec2(center)
        C::Graphics.sfTransform_rotateWithCenter(@struct.pointer, degrees.to_f, c.to_native_f)
      else
        C::Graphics.sfTransform_rotate(@struct.pointer, degrees.to_f)
      end
      self
    end

    # Apply a scale. With `center:`, scales around that pivot.
    def scale(factors, center: nil)
      f = _vec2(factors)
      if center
        c = _vec2(center)
        C::Graphics.sfTransform_scaleWithCenter(@struct.pointer, f.to_native_f, c.to_native_f)
      else
        C::Graphics.sfTransform_scale(@struct.pointer, f.to_native_f)
      end
      self
    end

    # Multiply this transform by another. `t.combine(t2)` is `t * t2`
    # in left-to-right order (apply t2's transformation, then t's).
    def combine(other)
      raise ArgumentError, "Transform#combine needs another SFML::Transform" unless other.is_a?(Transform)
      C::Graphics.sfTransform_combine(@struct.pointer, other.struct.pointer)
      self
    end

    # Return a new Transform that's the inverse of this one — applying
    # both in sequence yields the identity.
    def inverse
      result = C::Graphics.sfTransform_getInverse(@struct.pointer)
      t = allocate_new_with(result)
      t
    end

    # Map a point through the transform. Returns a Vector2.
    def transform_point(point)
      vec = _vec2(point)
      r   = C::Graphics.sfTransform_transformPoint(@struct.pointer, vec.to_native_f)
      Vector2.new(r[:x], r[:y])
    end

    # Map a SFML::Rect through the transform. Returns a new Rect.
    def transform_rect(rect)
      raise ArgumentError, "Transform#transform_rect needs a SFML::Rect" unless rect.is_a?(Rect)
      native = C::Graphics::FloatRect.new
      native[:position][:x] = rect.x.to_f
      native[:position][:y] = rect.y.to_f
      native[:size][:x]     = rect.width.to_f
      native[:size][:y]     = rect.height.to_f

      r = C::Graphics.sfTransform_transformRect(@struct.pointer, native)
      Rect.from_native(r)
    end

    # Read the matrix as a flat 9-element Array of floats (row-major).
    def matrix
      (0...9).map { |i| @struct[:matrix][i] }
    end

    def ==(other)
      return false unless other.is_a?(Transform)
      C::Graphics.sfTransform_equal(@struct.pointer, other.struct.pointer)
    end
    alias eql? ==
    def hash = matrix.hash

    def to_s = "Transform(#{matrix.map { |v| v.round(3) }.inspect})"
    alias inspect to_s

    # @!visibility private
    attr_reader :struct

    private

    def allocate_new_with(native_struct)
      t = self.class.allocate
      new_buf = C::Graphics::Transform.new
      new_buf.pointer.write_bytes(native_struct.pointer.read_bytes(C::Graphics::Transform.size))
      t.instance_variable_set(:@struct, new_buf)
      t
    end

    def _vec2(value)
      value.is_a?(Vector2) ? value : Vector2.new(*value)
    end
  end
end
