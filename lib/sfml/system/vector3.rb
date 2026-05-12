module SFML
  # 3D vector with float components. Mirrors Vector2's surface — same
  # arithmetic, same coerce trick for `2 * v`, same pattern-match
  # support. Used by the 3D-audio API (`Sound#position`, `Listener`,
  # …) and as a back-end for `Image` size hints.
  class Vector3
    attr_reader :x, :y, :z

    # Compact constructor: `Vector3[1, 2, 3]`.
    def self.[](x, y, z) = new(x, y, z)

    # The (0, 0, 0) vector.
    def self.zero = new(0, 0, 0)

    def initialize(x = 0, y = 0, z = 0)
      @x = x
      @y = y
      @z = z
      freeze
    end

    # Component-wise addition.
    def +(other) = Vector3.new(@x + other.x, @y + other.y, @z + other.z)
    # Component-wise subtraction.
    def -(other) = Vector3.new(@x - other.x, @y - other.y, @z - other.z)
    # Multiply every component by `scalar`.
    def *(scalar) = Vector3.new(@x * scalar, @y * scalar, @z * scalar)
    # Divide every component by `scalar` (promotes to Float).
    def /(scalar) = Vector3.new(@x / scalar.to_f, @y / scalar.to_f, @z / scalar.to_f)
    # Negate every component.
    def -@ = Vector3.new(-@x, -@y, -@z)

    # Value equality — all three components must match.
    def ==(other)
      other.is_a?(Vector3) && @x == other.x && @y == other.y && @z == other.z
    end
    alias eql? ==
    # Hash key support.
    def hash = [@x, @y, @z].hash

    # Euclidean length √(x² + y² + z²). Prefer `length_sq` for
    # comparisons to skip the square root.
    def length    = Math.sqrt(length_sq)
    # Squared length (x² + y² + z²) — faster than `length` when you
    # only need to compare magnitudes.
    def length_sq = (@x * @x) + (@y * @y) + (@z * @z)

    # Unit vector in the same direction. Zero vector returns itself
    # unchanged.
    def normalize
      len = length
      return Vector3.zero if len.zero?
      self / len
    end

    # Scalar dot product.
    def dot(other) = (@x * other.x) + (@y * other.y) + (@z * other.z)

    # 3D cross product (vector perpendicular to both).
    def cross(other)
      Vector3.new(
        (@y * other.z) - (@z * other.y),
        (@z * other.x) - (@x * other.z),
        (@x * other.y) - (@y * other.x)
      )
    end

    # Lets Ruby evaluate `2 * vec` as `vec * 2`.
    def coerce(other)
      raise TypeError, "Vector3 cannot coerce #{other.class}" unless other.is_a?(Numeric)
      [self, other]
    end

    # Euclidean distance between two points — accepts Vector3 or
    # `[x, y, z]`.
    def distance(other)    = (self - _coerce(other)).length
    # Squared distance (skip the square root) for comparisons.
    def distance_sq(other) = (self - _coerce(other)).length_sq

    # Linear interpolation toward `other` at parameter `t` ∈ [0, 1].
    def lerp(other, t)
      o = _coerce(other)
      Vector3.new(@x + (o.x - @x) * t, @y + (o.y - @y) * t, @z + (o.z - @z) * t)
    end

    # Angle between two direction vectors, in radians. Both vectors
    # should be non-zero — returns 0 for either side zero.
    def angle_between(other)
      o  = _coerce(other)
      la = length
      lo = o.length
      return 0.0 if la.zero? || lo.zero?
      cos = (dot(o) / (la * lo)).clamp(-1.0, 1.0)
      Math.acos(cos)
    end

    # Vector projection of `self` onto `other`.
    def project_on(other)
      o = _coerce(other)
      d = o.length_sq
      return Vector3.zero if d.zero?
      o * (dot(o) / d)
    end

    # Reflect this vector across the plane defined by `normal`.
    # `normal` should be unit-length.
    def reflect(normal)
      n = _coerce(normal)
      self - (n * (2 * dot(n)))
    end

    # Clamp the magnitude into [min_len, max_len]. Either bound may
    # be `nil` to leave that side unclamped.
    def clamp_length(min_len = nil, max_len)
      len = length
      return self if len.zero?
      target =
        if    max_len && len > max_len then max_len
        elsif min_len && len < min_len then min_len
        else len
        end
      return self if target == len
      self * (target / len)
    end

    # `true` iff all three components are zero.
    def zero? = @x.zero? && @y.zero? && @z.zero?

    # Per-component absolute value.
    def abs   = Vector3.new(@x.abs, @y.abs, @z.abs)

    # Drop the z component → Vector2.
    def to_v2 = Vector2.new(@x, @y)

    # As `[x, y, z]`.
    def to_a = [@x, @y, @z]

    # As `{x:, y:, z:}`.
    def to_h = { x: @x, y: @y, z: @z }

    # Pattern-match support for `in [x, y, z]`.
    def deconstruct = [@x, @y, @z]

    # Pattern-match support for `in {x:, y:, z:}`.
    def deconstruct_keys(_keys) = { x: @x, y: @y, z: @z }

    # String representation for debugging.
    def to_s = "Vector3(#{@x}, #{@y}, #{@z})"
    alias inspect to_s

    def self.from_native(struct) # :nodoc:
      new(struct[:x], struct[:y], struct[:z])
    end

    def to_native_f # :nodoc:
      C::System::Vector3f.new.tap { |v| v[:x] = @x; v[:y] = @y; v[:z] = @z }
    end

    private

    def _coerce(value)
      value.is_a?(Vector3) ? value : Vector3.new(*value)
    end
  end
end
