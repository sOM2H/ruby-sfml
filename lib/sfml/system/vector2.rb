module SFML
  # 2D vector with float components. Operator-friendly and pattern-matchable.
  #
  #   v = SFML::Vector2[3, 4]
  #   v.length          #=> 5.0
  #   v + Vector2[1, 1] #=> Vector2(4, 5)
  #   v * 2             #=> Vector2(6, 8)
  #   x, y = v          # destructures via to_a
  class Vector2
    attr_reader :x, :y

    # Compact constructor: `Vector2[3, 4]` reads naturally as a literal.
    def self.[](x, y) = new(x, y)

    # The (0, 0) vector. Reused as a singleton-style fallback (e.g.
    # `#normalize` returns this for the zero vector).
    def self.zero = new(0, 0)

    def initialize(x = 0, y = 0)
      @x = x
      @y = y
      freeze
    end

    # Component-wise addition.
    def +(other) = Vector2.new(@x + other.x, @y + other.y)
    # Component-wise subtraction.
    def -(other) = Vector2.new(@x - other.x, @y - other.y)
    # Multiply both components by `scalar`.
    def *(scalar) = Vector2.new(@x * scalar, @y * scalar)
    # Divide both components by `scalar`. Always promotes to Float.
    def /(scalar) = Vector2.new(@x / scalar.to_f, @y / scalar.to_f)
    # Negate both components.
    def -@ = Vector2.new(-@x, -@y)

    # Lets Ruby evaluate `2 * vec` as `vec * 2`. Without this, Numeric#*
    # would raise TypeError because it doesn't know about Vector2.
    def coerce(other)
      raise TypeError, "Vector2 cannot coerce #{other.class}" unless other.is_a?(Numeric)
      [self, other]
    end

    # Value equality — two Vector2s are equal when both components match.
    def ==(other) = other.is_a?(Vector2) && @x == other.x && @y == other.y
    alias eql? ==
    # Hash key support — Vector2s can be Hash keys / Set members.
    def hash = [@x, @y].hash

    # Euclidean length √(x² + y²). For comparisons prefer `length_sq` —
    # avoids the square root.
    def length    = Math.sqrt(length_sq)
    # Squared length (x² + y²) — comparisons can use this without the
    # `sqrt` call.
    def length_sq = (@x * @x) + (@y * @y)

    # Unit vector pointing the same way as `self`. Returns the zero
    # vector unchanged (no division by zero).
    def normalize
      len = length
      return Vector2.zero if len.zero?
      self / len
    end

    # Scalar dot product. Positive when both vectors point roughly the
    # same way, negative when opposite, zero when perpendicular.
    def dot(other)   = (@x * other.x) + (@y * other.y)

    # Scalar 2D cross product (a.k.a. perpendicular dot). Positive when
    # `other` is counter-clockwise from `self`, negative when clockwise.
    def cross(other) = (@x * other.y) - (@y * other.x)

    # Euclidean distance to `other` — accepts a Vector2 or `[x, y]`.
    def distance(other)    = (self - _coerce(other)).length

    # Squared distance to `other` — skip the `sqrt` if you only need to
    # compare two distances.
    def distance_sq(other) = (self - _coerce(other)).length_sq

    # Angle of this vector relative to +X axis, in radians (-π..π].
    def angle = Math.atan2(@y, @x)

    # Angle from this vector to `other` as positions, in radians.
    def angle_to(other)
      o = _coerce(other)
      Math.atan2(o.y - @y, o.x - @x)
    end

    # Vector rotated by `degrees` counter-clockwise. Use `rotated_rad`
    # if you already have radians.
    def rotated(degrees) = rotated_rad(degrees * Math::PI / 180.0)

    # Vector rotated by `radians` counter-clockwise.
    def rotated_rad(radians)
      c, s = Math.cos(radians), Math.sin(radians)
      Vector2.new(@x * c - @y * s, @x * s + @y * c)
    end

    # 90° counter-clockwise rotation — equivalent to `rotated_rad(π/2)`
    # but skips the trig. Handy for "the normal of an edge in 2D".
    def perpendicular = Vector2.new(-@y, @x)

    # Linear interpolation toward `other`. `t` in [0, 1] gives the
    # standard mix; outside the range extrapolates.
    def lerp(other, t)
      o = _coerce(other)
      Vector2.new(@x + (o.x - @x) * t, @y + (o.y - @y) * t)
    end

    # Vector projection of `self` onto `other`.
    def project_on(other)
      o = _coerce(other)
      d = o.length_sq
      return Vector2.zero if d.zero?
      o * (dot(o) / d)
    end

    # Reflect this vector across the plane with `normal`. `normal`
    # should be unit-length for the standard "bounce" behaviour.
    def reflect(normal)
      n = _coerce(normal)
      self - (n * (2 * dot(n)))
    end

    # Clamp the magnitude into [min_len, max_len]. Either bound may be
    # nil to leave that side unclamped.
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

    # `true` iff both components are zero.
    def zero?  = @x.zero? && @y.zero?

    # Per-component absolute value.
    def abs    = Vector2.new(@x.abs, @y.abs)

    # Promote to a Vector3 with optional `z` (default 0).
    def to_v3(z = 0.0) = Vector3.new(@x, @y, z)

    # As a 2-element `[x, y]` Array — supports splat destructuring:
    # `x, y = vec`.
    def to_a = [@x, @y]

    # As a `{x:, y:}` Hash.
    def to_h = { x: @x, y: @y }

    # Pattern-match support for `in [x, y]`.
    def deconstruct = [@x, @y]

    # Pattern-match support for `in {x:, y:}`.
    def deconstruct_keys(_keys) = { x: @x, y: @y }

    # String representation for debugging.
    def to_s = "Vector2(#{@x}, #{@y})"
    alias inspect to_s

    def self.from_native(struct) # :nodoc:
      new(struct[:x], struct[:y])
    end

    def to_native_f # :nodoc:
      C::System::Vector2f.new.tap { |v| v[:x] = @x; v[:y] = @y }
    end

    private

    # Accept Vector2 or [x, y] interchangeably so user code can write
    #   pos.distance(target)  # Vector2
    #   pos.distance([10, 20])
    def _coerce(value)
      value.is_a?(Vector2) ? value : Vector2.new(*value)
    end
  end
end
