module SFML
  # Drawable rendered text. Like Sprite, requires a Font at construction time
  # in SFML 3, and we hold a Ruby reference to it to keep the GPU resource
  # alive while the Text object is in use.
  #
  #   font = SFML::Font.find("DejaVuSans")
  #   score = SFML::Text.new(font, "0 : 0",
  #     character_size: 48,
  #     fill_color: SFML::Color.white,
  #     position: [400, 30],
  #     style: %i[bold])
  #   window.draw(score)
  #   score.string = "1 : 0"  # mutate freely after construction
  class Text
    include Graphics::Transformable
    CSFML_PREFIX = :sfText

    STYLES = {
      regular:        0,
      bold:           1 << 0,
      italic:         1 << 1,
      underlined:     1 << 2,
      strike_through: 1 << 3,
    }.freeze

    def initialize(font, string = "", **opts)
      raise ArgumentError, "Text requires a SFML::Font" unless font.is_a?(Font)

      ptr = C::Graphics.sfText_create(font.handle)
      raise Error, "sfText_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfText_destroy))
      @font   = font # keep alive for GC

      self.string             = string
      self.character_size     = opts[:character_size]    if opts.key?(:character_size)
      self.fill_color         = opts[:fill_color]        if opts.key?(:fill_color)
      self.outline_color      = opts[:outline_color]     if opts.key?(:outline_color)
      self.outline_thickness  = opts[:outline_thickness] if opts.key?(:outline_thickness)
      self.style              = opts[:style]             if opts.key?(:style)
      self.position           = opts[:position]          if opts.key?(:position)
      self.origin             = opts[:origin]            if opts.key?(:origin)
      self.rotation           = opts[:rotation]          if opts.key?(:rotation)
      self.scale              = opts[:scale]             if opts.key?(:scale)
    end

    attr_reader :font

    def font=(new_font)
      raise ArgumentError, "Text#font= requires a SFML::Font" unless new_font.is_a?(Font)
      C::Graphics.sfText_setFont(@handle, new_font.handle)
      @font = new_font
    end

    # Read the current string back as Ruby UTF-8. CSFML returns a pointer
    # to a null-terminated sfChar32 (UTF-32) array; we walk it until the
    # zero terminator and pack the codepoints back into a UTF-8 String.
    def string
      ptr = C::Graphics.sfText_getUnicodeString(@handle)
      return "" if ptr.null?

      codepoints = []
      offset = 0
      loop do
        cp = ptr.get_uint32(offset)
        break if cp.zero?
        codepoints << cp
        offset += 4
      end
      codepoints.pack("U*")
    end

    def string=(value)
      str = value.to_s.encode("UTF-8")
      cps = str.unpack("U*")  # array of integer codepoints
      buf = FFI::MemoryPointer.new(:uint32, cps.length + 1)
      buf.write_array_of_uint32(cps + [0])
      C::Graphics.sfText_setUnicodeString(@handle, buf)
    end

    def character_size = C::Graphics.sfText_getCharacterSize(@handle)

    def character_size=(value)
      C::Graphics.sfText_setCharacterSize(@handle, Integer(value))
    end

    def fill_color = Color.from_native(C::Graphics.sfText_getFillColor(@handle))

    def fill_color=(c)
      C::Graphics.sfText_setFillColor(@handle, c.to_native)
    end

    def outline_color = Color.from_native(C::Graphics.sfText_getOutlineColor(@handle))

    def outline_color=(c)
      C::Graphics.sfText_setOutlineColor(@handle, c.to_native)
    end

    def outline_thickness = C::Graphics.sfText_getOutlineThickness(@handle)

    def outline_thickness=(t)
      C::Graphics.sfText_setOutlineThickness(@handle, t.to_f)
    end

    # Returns an Array of style symbols, e.g. [:bold, :italic].
    def style
      bits = C::Graphics.sfText_getStyle(@handle)
      return [:regular] if bits.zero?
      STYLES.each_with_object([]) do |(name, value), acc|
        acc << name if value != 0 && (bits & value) != 0
      end
    end

    # Accepts a single Symbol, an Array of Symbols, or a raw integer bitmask.
    def style=(value)
      bits = case value
             when Integer then value
             when Symbol  then STYLES.fetch(value)
             when Array
               value.reduce(0) { |acc, sym| acc | STYLES.fetch(sym) }
             else
               raise ArgumentError, "Text#style= expects Symbol, Array, or Integer; got #{value.class}"
             end
      C::Graphics.sfText_setStyle(@handle, bits)
    end

    # Bounding box of the text in its own (untransformed) coordinate system.
    # Use this to centre or align glyphs precisely:
    #   text.origin = [text.local_bounds.width / 2, 0]
    def local_bounds
      Rect.from_native(C::Graphics.sfText_getLocalBounds(@handle))
    end

    # Bounding box after applying the Text's transform (position/scale/rotation).
    def global_bounds
      Rect.from_native(C::Graphics.sfText_getGlobalBounds(@handle))
    end

    def draw_on(target) # :nodoc:
      target._draw_native(:Text, @handle)
    end

    attr_reader :handle # :nodoc:
  end
end
