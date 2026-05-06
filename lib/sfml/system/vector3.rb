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
  end
end
