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

    def self.[](x, y) = new(x, y)
    def self.zero     = new(0, 0)

    def initialize(x = 0, y = 0)
      @x = x
      @y = y
      freeze
    end

    def +(other) = Vector2.new(@x + other.x, @y + other.y)
    def -(other) = Vector2.new(@x - other.x, @y - other.y)
    def *(scalar) = Vector2.new(@x * scalar, @y * scalar)
    def /(scalar) = Vector2.new(@x / scalar.to_f, @y / scalar.to_f)
    def -@ = Vector2.new(-@x, -@y)

    # Lets Ruby evaluate `2 * vec` as `vec * 2`. Without this, Numeric#*
    # would raise TypeError because it doesn't know about Vector2.
    def coerce(other)
      raise TypeError, "Vector2 cannot coerce #{other.class}" unless other.is_a?(Numeric)
      [self, other]
    end

    def ==(other) = other.is_a?(Vector2) && @x == other.x && @y == other.y
    alias eql? ==
    def hash = [@x, @y].hash

    def length    = Math.sqrt(length_sq)
    def length_sq = (@x * @x) + (@y * @y)

    def normalize
      len = length
      return Vector2.zero if len.zero?
      self / len
    end

    def dot(other)   = (@x * other.x) + (@y * other.y)
    def cross(other) = (@x * other.y) - (@y * other.x)

    # Euclidean distance between two points.
    def distance(other)    = (self - _coerce(other)).length
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

    def zero?  = @x.zero? && @y.zero?
    def abs    = Vector2.new(@x.abs, @y.abs)
    def to_v3(z = 0.0) = Vector3.new(@x, @y, z)

    def to_a = [@x, @y]
    def to_h = { x: @x, y: @y }
    def deconstruct = [@x, @y]
    def deconstruct_keys(_keys) = { x: @x, y: @y }

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
