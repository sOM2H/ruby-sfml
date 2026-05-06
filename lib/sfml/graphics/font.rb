module SFML
  # A typeface loaded from a TTF/OTF file.
  #
  #   font = SFML::Font.load("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
  #   font = SFML::Font.find("DejaVuSans") # search common locations
  class Font
    SEARCH_PATHS = [
      "/usr/share/fonts",
      "/usr/local/share/fonts",
      "/Library/Fonts",
      "/System/Library/Fonts",
      File.expand_path("~/Library/Fonts"),
      "C:/Windows/Fonts",
    ].freeze

    def self.load(path)
      ptr = C::Graphics.sfFont_createFromFile(path.to_s)
      raise Error, "Could not load font from #{path.inspect}" if ptr.null?

      font = allocate
      font.send(:_take_ownership, ptr)
      font
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

    attr_reader :handle # :nodoc:

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfFont_destroy))
    end
  end
end
