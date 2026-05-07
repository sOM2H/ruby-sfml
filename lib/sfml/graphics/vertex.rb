module SFML
  # A single point of geometry: position, colour, and texture coordinate.
  # Plain Ruby value object — VertexArray copies it into / out of CSFML
  # storage, so mutating a Vertex after appending doesn't propagate.
  #
  #   SFML::Vertex.new([10, 20])
  #   SFML::Vertex.new([10, 20], color: SFML::Color.red)
  #   SFML::Vertex.new([10, 20], color: SFML::Color.red, tex_coords: [0, 0])
  class Vertex
    attr_accessor :position, :color, :tex_coords

    def initialize(position = Vector2.zero, color: Color::WHITE, tex_coords: Vector2.zero)
      @position   = _coerce_vec2(position)
      @color      = color
      @tex_coords = _coerce_vec2(tex_coords)
    end

    def to_s
      "Vertex(#{@position.x}, #{@position.y})"
    end
    alias inspect to_s

    # @!visibility private
    def to_native
      v = C::Graphics::Vertex.new
      v[:position][:x]   = @position.x.to_f
      v[:position][:y]   = @position.y.to_f
      v[:color][:r]      = @color.r
      v[:color][:g]      = @color.g
      v[:color][:b]      = @color.b
      v[:color][:a]      = @color.a
      v[:tex_coords][:x] = @tex_coords.x.to_f
      v[:tex_coords][:y] = @tex_coords.y.to_f
      v
    end

    # @!visibility private
    def self.from_native(struct)
      new(
        Vector2.new(struct[:position][:x], struct[:position][:y]),
        color:      Color.new(struct[:color][:r], struct[:color][:g],
                              struct[:color][:b], struct[:color][:a]),
        tex_coords: Vector2.new(struct[:tex_coords][:x], struct[:tex_coords][:y]),
      )
    end

    private

    def _coerce_vec2(value)
      value.is_a?(Vector2) ? value : Vector2.new(*value)
    end
  end
end
