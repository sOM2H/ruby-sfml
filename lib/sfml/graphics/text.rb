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

    # Bitmask values for each style symbol.
    STYLES = {
      regular:        0,
      bold:           1 << 0,
      italic:         1 << 1,
      underlined:     1 << 2,
      strike_through: 1 << 3,
    }.freeze

    # Build a Text. `font` must be an `SFML::Font`; `string` defaults
    # to empty. Optional kwargs: `:character_size`, `:fill_color`,
    # `:outline_color`, `:outline_thickness`, `:style`, plus the
    # standard transform options.
    def initialize(font, string = "", **opts)
      raise ArgumentError, "Text requires a SFML::Font" unless font.is_a?(Font)

      ptr = C::Graphics.sfText_create(font.handle)
      raise GraphicsError, "sfText_create returned NULL" if ptr.null?
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

    # The font.
    attr_reader :font

    # Replace the font used to render this Text.
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

    # Replace the displayed string. Accepts any Ruby String — UTF-8
    # codepoints are converted to UTF-32 for CSFML internally.
    def string=(value)
      str = value.to_s.encode("UTF-8")
      cps = str.unpack("U*")  # array of integer codepoints
      buf = FFI::MemoryPointer.new(:uint32, cps.length + 1)
      buf.write_array_of_uint32(cps + [0])
      C::Graphics.sfText_setUnicodeString(@handle, buf)
    end

    # Font size in pixels (e.g. 14, 18, 24).
    def character_size = C::Graphics.sfText_getCharacterSize(@handle)

    # Set the font size.
    def character_size=(value)
      C::Graphics.sfText_setCharacterSize(@handle, Integer(value))
    end

    # Body fill color.
    def fill_color = Color.from_native(C::Graphics.sfText_getFillColor(@handle))

    # Set the fill color.
    def fill_color=(c)
      C::Graphics.sfText_setFillColor(@handle, c.to_native)
    end

    # Outline color (only visible when `#outline_thickness > 0`).
    def outline_color = Color.from_native(C::Graphics.sfText_getOutlineColor(@handle))

    # Set the outline color.
    def outline_color=(c)
      C::Graphics.sfText_setOutlineColor(@handle, c.to_native)
    end

    # Outline thickness in pixels.
    def outline_thickness = C::Graphics.sfText_getOutlineThickness(@handle)

    # Set the outline thickness.
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

    # The character spacing modifier — a multiplier on the font's
    # natural advance. Read with no args, set with a Float (1.0 =
    # default).
    def letter_spacing = C::Graphics.sfText_getLetterSpacing(@handle)

    # Set the letter-spacing multiplier.
    def letter_spacing=(value)
      C::Graphics.sfText_setLetterSpacing(@handle, Float(value))
    end

    # The line-spacing multiplier (1.0 = default).
    def line_spacing = C::Graphics.sfText_getLineSpacing(@handle)

    # Set the line-spacing multiplier.
    def line_spacing=(value)
      C::Graphics.sfText_setLineSpacing(@handle, Float(value))
    end

    # The screen-space position of the character at byte index
    # `index` in the Text's current string. Returns a `Vector2`.
    # Useful for positioning a caret in a text field, drawing
    # selection highlights, or anchoring tooltips.
    def find_character_pos(index)
      Vector2.from_native(C::Graphics.sfText_findCharacterPos(@handle, Integer(index)))
    end

    # Combined translation/scale/rotation as a SFML::Transform.
    # Same matrix the renderer uses to draw the Text.
    def transform
      C::Graphics.sfText_getTransform(@handle)
    end

    # Inverse of `#transform` — maps world-space coords back to
    # the Text's local space.
    def inverse_transform
      C::Graphics.sfText_getInverseTransform(@handle)
    end

    # Deep copy. The returned Text holds the same Font reference
    # (Fonts are shareable; each owns its own glyph atlas).
    def dup
      ptr = C::Graphics.sfText_copy(@handle)
      raise GraphicsError, "sfText_copy returned NULL" if ptr.null?

      copy = self.class.allocate
      copy.instance_variable_set(:@handle, FFI::AutoPointer.new(ptr, C::Graphics.method(:sfText_destroy)))
      copy.instance_variable_set(:@font, @font)
      copy
    end
    alias clone dup

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

    # Returns the draw on.
    def draw_on(target, states_ptr = nil) # :nodoc:
      target._draw_native(:Text, @handle, states_ptr)
    end

    attr_reader :handle # :nodoc:
  end
end
