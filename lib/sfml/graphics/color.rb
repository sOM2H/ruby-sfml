module SFML
  # 32-bit RGBA color, immutable.
  #
  #   SFML::Color.new(255, 100, 50)        # opaque
  #   SFML::Color.new(255, 100, 50, 128)   # half-transparent
  #   SFML::Color.rgb(255, 100, 50)        # alias
  #   SFML::Color.rgba(255, 100, 50, 128)
  #   SFML::Color["#ff6432"]               # hex (RGB or RRGGBB or RRGGBBAA)
  #   SFML::Color.cornflower_blue          # named
  class Color
    attr_reader :r, :g, :b, :a

    def initialize(r, g, b, a = 255)
      @r = Integer(r)
      @g = Integer(g)
      @b = Integer(b)
      @a = Integer(a)
      freeze
    end

    def self.rgb(r, g, b)        = new(r, g, b, 255)
    def self.rgba(r, g, b, a)    = new(r, g, b, a)

    def self.[](hex)
      str = hex.to_s.delete_prefix("#")
      case str.length
      when 3
        new(str[0].hex * 17, str[1].hex * 17, str[2].hex * 17, 255)
      when 6
        new(str[0..1].to_i(16), str[2..3].to_i(16), str[4..5].to_i(16), 255)
      when 8
        new(str[0..1].to_i(16), str[2..3].to_i(16), str[4..5].to_i(16), str[6..7].to_i(16))
      else
        raise ArgumentError, "Color hex must be #RGB, #RRGGBB, or #RRGGBBAA, got #{hex.inspect}"
      end
    end

    def ==(other)
      other.is_a?(Color) && @r == other.r && @g == other.g && @b == other.b && @a == other.a
    end
    alias eql? ==
    def hash = [@r, @g, @b, @a].hash

    def to_a = [@r, @g, @b, @a]
    def to_h = { r: @r, g: @g, b: @b, a: @a }
    def deconstruct = to_a
    def deconstruct_keys(_keys) = to_h

    def to_s = "Color(#{@r}, #{@g}, #{@b}, #{@a})"
    alias inspect to_s

    def to_native # :nodoc:
      C::Graphics::Color.new.tap do |c|
        c[:r] = @r; c[:g] = @g; c[:b] = @b; c[:a] = @a
      end
    end

    def self.from_native(struct) # :nodoc:
      new(struct[:r], struct[:g], struct[:b], struct[:a])
    end

    # Standard SFML colors.
    BLACK       = new(0,   0,   0)
    WHITE       = new(255, 255, 255)
    RED         = new(255, 0,   0)
    GREEN       = new(0,   255, 0)
    BLUE        = new(0,   0,   255)
    YELLOW      = new(255, 255, 0)
    MAGENTA     = new(255, 0,   255)
    CYAN        = new(0,   255, 255)
    TRANSPARENT = new(0,   0,   0,   0)

    # A nicer default than pure black for empty windows.
    CORNFLOWER_BLUE = new(100, 149, 237)

    class << self
      def black           = BLACK
      def white           = WHITE
      def red             = RED
      def green           = GREEN
      def blue            = BLUE
      def yellow          = YELLOW
      def magenta         = MAGENTA
      def cyan            = CYAN
      def transparent     = TRANSPARENT
      def cornflower_blue = CORNFLOWER_BLUE
    end
  end
end
