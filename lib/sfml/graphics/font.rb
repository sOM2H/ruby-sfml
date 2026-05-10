module SFML
  # A typeface loaded from a TTF/OTF file.
  #
  #   font = SFML::Font.default                                                # bundled DejaVu Sans
  #   font = SFML::Font.load("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
  #   font = SFML::Font.find("DejaVuSans")                                     # search common locations
  class Font
    SEARCH_PATHS = [
      "/usr/share/fonts",
      "/usr/local/share/fonts",
      "/Library/Fonts",
      "/System/Library/Fonts",
      File.expand_path("~/Library/Fonts"),
      "C:/Windows/Fonts",
    ].freeze

    # Path to the font ruby-sfml ships with: DejaVu Sans (Bitstream Vera
    # license, redistributable). See lib/sfml/assets/fonts/DejaVuSans.LICENSE.txt.
    DEFAULT_PATH = File.expand_path("../assets/fonts/DejaVuSans.ttf", __dir__).freeze

    def self.load(path)
      ptr = C::Graphics.sfFont_createFromFile(path.to_s)
      raise Error, "Could not load font from #{path.inspect}" if ptr.null?

      font = allocate
      font.send(:_take_ownership, ptr)
      font
    end

    # Load a font from a Ruby String of bytes — useful when the
    # font lives inside a `data:` URL, an embedded asset, or a
    # network response. The bytes are copied by SFML before this
    # call returns; the caller's String can be GC'd safely.
    def self.from_memory(bytes)
      raise ArgumentError, "expected a String, got #{bytes.class}" unless bytes.is_a?(String)

      buf = FFI::MemoryPointer.new(:uint8, bytes.bytesize)
      buf.write_bytes(bytes)
      ptr = C::Graphics.sfFont_createFromMemory(buf, bytes.bytesize)
      raise Error, "sfFont_createFromMemory returned NULL" if ptr.null?

      font = allocate
      font.send(:_take_ownership, ptr)
      font
    end

    # The default font bundled with ruby-sfml. Use this when you don't
    # care which typeface as long as you can render text — examples,
    # debug HUDs, prototypes. Memoized so subsequent calls return the
    # same Font instance.
    def self.default
      @default ||= load(DEFAULT_PATH)
    end

    # Look up a font on disk by basename (with or without extension). Useful
    # for examples that should "just run" — production code should ship its
    # own font files. Returns nil if nothing is found.
    def self.find(name)
      target = name.to_s.downcase.sub(/\.(ttf|otf)\z/, "")
      SEARCH_PATHS.each do |dir|
        next unless File.directory?(dir)
        match = Dir.glob(File.join(dir, "**", "*.{ttf,otf}")).find do |path|
          File.basename(path).downcase.sub(/\.(ttf|otf)\z/, "") == target
        end
        return load(match) if match
      end
      nil
    end

    def smooth?       = C::Graphics.sfFont_isSmooth(@handle)

    def smooth=(value)
      C::Graphics.sfFont_setSmooth(@handle, !!value)
    end

    # Human-readable family name (e.g. "DejaVu Sans"). Read once
    # via `sfFont_getInfo` — CSFML returns a static C string from
    # FreeType so we copy out into a Ruby String.
    def family
      info = C::Graphics.sfFont_getInfo(@handle)
      info[:family].null? ? nil : info[:family].read_string
    end

    # `true` if the font has a glyph for the given Unicode codepoint
    # (Integer) or single-character String.
    def has_glyph?(codepoint)
      cp = codepoint.is_a?(String) ? codepoint.codepoints.first : Integer(codepoint)
      C::Graphics.sfFont_hasGlyph(@handle, cp || 0)
    end

    # Horizontal kerning offset between two adjacent glyphs at the
    # given character size. Float, in pixels (often negative — the
    # kern pulls the second glyph leftward).
    def kerning(first, second, character_size:, bold: false)
      a = first.is_a?(String)  ? first.codepoints.first  : Integer(first)
      b = second.is_a?(String) ? second.codepoints.first : Integer(second)
      fn = bold ? :sfFont_getBoldKerning : :sfFont_getKerning
      C::Graphics.send(fn, @handle, a || 0, b || 0, Integer(character_size))
    end

    # Distance between two consecutive baselines for the given
    # character size. Float, in pixels.
    def line_spacing(character_size)
      C::Graphics.sfFont_getLineSpacing(@handle, Integer(character_size))
    end

    # Vertical offset of the underline from the baseline (positive
    # values point downward). Float, in pixels.
    def underline_position(character_size)
      C::Graphics.sfFont_getUnderlinePosition(@handle, Integer(character_size))
    end

    # Thickness of the underline stroke. Float, in pixels.
    def underline_thickness(character_size)
      C::Graphics.sfFont_getUnderlineThickness(@handle, Integer(character_size))
    end

    # The internal glyph atlas as a `SFML::Texture` (read-only — we
    # don't own the pointer; CSFML keeps it alive as long as the
    # font does).
    def texture(character_size)
      ptr = C::Graphics.sfFont_getTexture(@handle, Integer(character_size))
      return nil if ptr.null?
      Texture.send(:_borrow, ptr)
    end

    # Deep copy. The returned font has its own atlas state; mutate
    # one without affecting the other.
    def dup
      ptr = C::Graphics.sfFont_copy(@handle)
      raise Error, "sfFont_copy returned NULL" if ptr.null?

      font = self.class.allocate
      font.send(:_take_ownership, ptr)
      font
    end
    alias clone dup

    attr_reader :handle # :nodoc:

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfFont_destroy))
    end
  end
end
