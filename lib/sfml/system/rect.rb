module SFML
  # An axis-aligned rectangle. Mirrors sfFloatRect / sfIntRect — those structs
  # are just (position: Vector2, size: Vector2). We deliberately keep one
  # Ruby class for both the float and int variants since pattern-matching
  # `case bounds in {position: {x:, y:}, size: {x: w, y: h}}` is what the
  # users reach for either way.
  #
  #   r = SFML::Rect.new([10, 20], [100, 50])
  #   r.contains?([50, 30])    #=> true
  #   r.right                  #=> 110
  #
  # Used by Text#local_bounds, Text#global_bounds, Sprite#texture_rect, etc.
  class Rect
    attr_reader :position, :size

    def initialize(position, size)
      @position = position.is_a?(Vector2) ? position : Vector2.new(*position)
      @size     = size.is_a?(Vector2) ? size : Vector2.new(*size)
      freeze
    end

    def x      = @position.x
    def y      = @position.y
    def width  = @size.x
    def height = @size.y
    alias left x
    alias top  y
    def right  = @position.x + @size.x
    def bottom = @position.y + @size.y

    def contains?(point)
      px, py = point.is_a?(Vector2) ? [point.x, point.y] : [point[0], point[1]]
      px >= left && px < right && py >= top && py < bottom
    end

    def intersects?(other)
      left   < other.right  &&
        right  > other.left  &&
        top    < other.bottom &&
        bottom > other.top
    end

    def ==(other)
      other.is_a?(Rect) && @position == other.position && @size == other.size
    end
    alias eql? ==
    def hash = [@position, @size].hash

    def to_a = [x, y, width, height]
    def to_h = { position: @position, size: @size }
    def deconstruct = [x, y, width, height]
    def deconstruct_keys(_keys) = { position: @position, size: @size }

    def to_s = "Rect(x=#{x}, y=#{y}, w=#{width}, h=#{height})"
    alias inspect to_s

    def self.from_native(struct) # :nodoc:
      new(
        Vector2.new(struct[:position][:x], struct[:position][:y]),
        Vector2.new(struct[:size][:x], struct[:size][:y]),
      )
    end
  end
end
