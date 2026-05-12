module SFML
  # 3D vector with float components. Mirrors Vector2's surface.
  class Vector3
    attr_reader :x, :y, :z

    def self.[](x, y, z) = new(x, y, z)
    def self.zero        = new(0, 0, 0)

    def initialize(x = 0, y = 0, z = 0)
      @x = x
      @y = y
      @z = z
      freeze
    end

    def +(other) = Vector3.new(@x + other.x, @y + other.y, @z + other.z)
    def -(other) = Vector3.new(@x - other.x, @y - other.y, @z - other.z)
    def *(scalar) = Vector3.new(@x * scalar, @y * scalar, @z * scalar)
    def /(scalar) = Vector3.new(@x / scalar.to_f, @y / scalar.to_f, @z / scalar.to_f)
    def -@ = Vector3.new(-@x, -@y, -@z)

    def ==(other)
      other.is_a?(Vector3) && @x == other.x && @y == other.y && @z == other.z
    end
    alias eql? ==
    def hash = [@x, @y, @z].hash

    def length    = Math.sqrt(length_sq)
    def length_sq = (@x * @x) + (@y * @y) + (@z * @z)

    def normalize
      len = length
      return Vector3.zero if len.zero?
      self / len
    end

    def dot(other) = (@x * other.x) + (@y * other.y) + (@z * other.z)

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

    def distance(other)    = (self - _coerce(other)).length
    def distance_sq(other) = (self - _coerce(other)).length_sq

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

    def project_on(other)
      o = _coerce(other)
      d = o.length_sq
      return Vector3.zero if d.zero?
      o * (dot(o) / d)
    end

    def reflect(normal)
      n = _coerce(normal)
      self - (n * (2 * dot(n)))
    end

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

    def zero? = @x.zero? && @y.zero? && @z.zero?
    def abs   = Vector3.new(@x.abs, @y.abs, @z.abs)
    def to_v2 = Vector2.new(@x, @y)

    def to_a = [@x, @y, @z]
    def to_h = { x: @x, y: @y, z: @z }
    def deconstruct = [@x, @y, @z]
    def deconstruct_keys(_keys) = { x: @x, y: @y, z: @z }

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
