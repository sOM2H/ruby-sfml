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
  end
end
