module SFML
  # How source pixels combine with destination pixels when drawing.
  # Use the named constants for the common cases:
  #
  #   window.draw(sprite, blend_mode: SFML::BlendMode::ADD)
  #
  # ADD       — bright shapes accumulate (great for glow / lighting)
  # MULTIPLY  — darken (shadows, screen-style overlays)
  # MIN / MAX — pick the darker / brighter pixel
  # NONE      — overwrite, ignoring the destination
  # ALPHA     — the default; src*α blended onto dst
  #
  # Build a custom mode with kwargs:
  #
  #   SFML::BlendMode.new(
  #     color_src: :src_alpha, color_dst: :one, color_eq: :add,
  #     alpha_src: :one,       alpha_dst: :one, alpha_eq: :add,
  #   )
  class BlendMode
    # Order matches sfBlendFactor in CSFML 3.
    FACTORS = %i[
      zero one src_color one_minus_src_color dst_color one_minus_dst_color
      src_alpha one_minus_src_alpha dst_alpha one_minus_dst_alpha
    ].freeze
    # Blend-factor symbol → integer Hash.
    FACTOR_INDEX = FACTORS.each_with_index.to_h.freeze

    # Blend-equation symbols in CSFML enum order.
    EQUATIONS = %i[add subtract reverse_subtract min max].freeze
    # Blend-equation symbol → integer Hash.
    EQUATION_INDEX = EQUATIONS.each_with_index.to_h.freeze

    # The color src, color dst, color eq components.
    attr_reader :color_src, :color_dst, :color_eq,
                :alpha_src, :alpha_dst, :alpha_eq

    def initialize(color_src:, color_dst:, color_eq:,
                   alpha_src:, alpha_dst:, alpha_eq:)
      @color_src = _check_factor(color_src)
      @color_dst = _check_factor(color_dst)
      @color_eq  = _check_equation(color_eq)
      @alpha_src = _check_factor(alpha_src)
      @alpha_dst = _check_factor(alpha_dst)
      @alpha_eq  = _check_equation(alpha_eq)
      freeze
    end

    def ==(other)
      other.is_a?(BlendMode) &&
        color_src == other.color_src && color_dst == other.color_dst && color_eq == other.color_eq &&
        alpha_src == other.alpha_src && alpha_dst == other.alpha_dst && alpha_eq == other.alpha_eq
    end
    alias eql? ==
    # Returns the hash.
    def hash = [color_src, color_dst, color_eq, alpha_src, alpha_dst, alpha_eq].hash

    # Returns the to s.
    def to_s
      "BlendMode(color: #{color_src}/#{color_dst}/#{color_eq}, alpha: #{alpha_src}/#{alpha_dst}/#{alpha_eq})"
    end
    alias inspect to_s

    # @!visibility private
    # Write our six fields into a CSFML BlendMode struct (or a sub-struct
    # of an existing RenderStates buffer).
    def populate(struct)
      struct[:color_src_factor] = FACTOR_INDEX[@color_src]
      struct[:color_dst_factor] = FACTOR_INDEX[@color_dst]
      struct[:color_equation]   = EQUATION_INDEX[@color_eq]
      struct[:alpha_src_factor] = FACTOR_INDEX[@alpha_src]
      struct[:alpha_dst_factor] = FACTOR_INDEX[@alpha_dst]
      struct[:alpha_equation]   = EQUATION_INDEX[@alpha_eq]
      struct
    end

    # @!visibility private
    def self.from_native(struct)
      new(
        color_src: FACTORS[struct[:color_src_factor]],
        color_dst: FACTORS[struct[:color_dst_factor]],
        color_eq:  EQUATIONS[struct[:color_equation]],
        alpha_src: FACTORS[struct[:alpha_src_factor]],
        alpha_dst: FACTORS[struct[:alpha_dst_factor]],
        alpha_eq:  EQUATIONS[struct[:alpha_equation]],
      )
    end

    # Defined as private at the bottom of the file would arrive too late
    # — the constants below call .new through .from_native, which goes
    # through #initialize, which uses these checks.
    private

    def _check_factor(name)
      raise ArgumentError, "Unknown blend factor: #{name.inspect}" unless FACTOR_INDEX.key?(name)
      name
    end

    def _check_equation(name)
      raise ArgumentError, "Unknown blend equation: #{name.inspect}" unless EQUATION_INDEX.key?(name)
      name
    end

    public

    # Built-in modes — read straight out of CSFML's global constants so
    # we never have to hand-maintain the canonical factor lists.
    ALPHA    = from_native(C::Graphics.sfBlendAlpha)
    ADD      = from_native(C::Graphics.sfBlendAdd)
    MULTIPLY = from_native(C::Graphics.sfBlendMultiply)
    MIN      = from_native(C::Graphics.sfBlendMin)
    MAX      = from_native(C::Graphics.sfBlendMax)
    # The 0.0.0.0 / empty placeholder address.
    NONE     = from_native(C::Graphics.sfBlendNone)
  end
end
