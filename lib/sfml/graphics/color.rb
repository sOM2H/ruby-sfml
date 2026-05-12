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

    # Build a Color from individual channel values. Each must be an
    # Integer in [0, 255]; alpha defaults to 255 (opaque).
    def initialize(r, g, b, a = 255)
      @r = Integer(r)
      @g = Integer(g)
      @b = Integer(b)
      @a = Integer(a)
      freeze
    end

    # Opaque RGB constructor — alias for `.new(r, g, b)`.
    def self.rgb(r, g, b)        = new(r, g, b, 255)
    # RGBA constructor — alias for `.new(r, g, b, a)`.
    def self.rgba(r, g, b, a)    = new(r, g, b, a)

    # Parse a hex color string. Accepts `#RGB` (each digit doubled),
    # `#RRGGBB` (opaque), or `#RRGGBBAA` (with alpha). The leading
    # `#` is optional.
    #
    #   SFML::Color["#ff6432"]     #=> Color(255, 100, 50, 255)
    #   SFML::Color["#ff643280"]   #=> Color(255, 100, 50, 128)
    #   SFML::Color["#abc"]        #=> Color(170, 187, 204, 255)
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

    # Value equality — all four channels must match.
    def ==(other)
      other.is_a?(Color) && @r == other.r && @g == other.g && @b == other.b && @a == other.a
    end
    alias eql? ==
    # Hash key support.
    def hash = [@r, @g, @b, @a].hash

    # `[r, g, b, a]`.
    def to_a = [@r, @g, @b, @a]
    # `{r:, g:, b:, a:}`.
    def to_h = { r: @r, g: @g, b: @b, a: @a }
    # Pattern-match support for `in [r, g, b, a]`.
    def deconstruct = to_a
    # Pattern-match support for `in {r:, g:, b:, a:}`.
    def deconstruct_keys(_keys) = to_h

    # String representation for debugging.
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

    # Build from a packed 0xRRGGBBAA integer.
    def self.from_integer(value)
      from_native(C::Graphics.sfColor_fromInteger(Integer(value)))
    end

    # Pack this color into a single 0xRRGGBBAA integer.
    def to_integer = C::Graphics.sfColor_toInteger(to_native)

    # Component-wise channel arithmetic (saturating in CSFML — values
    # clamp to [0, 255]).

    def +(other)
      raise ArgumentError, "Color +: expected SFML::Color" unless other.is_a?(Color)
      self.class.from_native(C::Graphics.sfColor_add(to_native, other.to_native))
    end

    # Saturating channel-wise subtraction — values clamp at 0.
    def -(other)
      raise ArgumentError, "Color -: expected SFML::Color" unless other.is_a?(Color)
      self.class.from_native(C::Graphics.sfColor_subtract(to_native, other.to_native))
    end

    # Channel-wise multiply, e.g. for tinting (white modulates to
    # input; black modulates to black). Uses CSFML's normalised
    # formula `(a * b) / 255`.
    def *(other)
      raise ArgumentError, "Color *: expected SFML::Color" unless other.is_a?(Color)
      self.class.from_native(C::Graphics.sfColor_modulate(to_native, other.to_native))
    end
    alias modulate *

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

    # Convenience accessors for the standard named colors, also
    # available as `Color::BLACK` etc. for use in constants.
    class << self
      # Returns the BLACK singleton.
      def black           = BLACK
      # Returns the WHITE singleton.
      def white           = WHITE
      # Returns the RED singleton.
      def red             = RED
      # Returns the GREEN singleton.
      def green           = GREEN
      # Returns the BLUE singleton.
      def blue            = BLUE
      # Returns the YELLOW singleton.
      def yellow          = YELLOW
      # Returns the MAGENTA singleton.
      def magenta         = MAGENTA
      # Returns the CYAN singleton.
      def cyan            = CYAN
      # Returns the TRANSPARENT singleton (alpha = 0).
      def transparent     = TRANSPARENT
      # Returns the CORNFLOWER_BLUE singleton — handy default for empty windows.
      def cornflower_blue = CORNFLOWER_BLUE
    end
  end
end
