module SFML
  # Cached, search-path-driven asset loader. Use it to avoid repeating file
  # paths and to load each asset exactly once.
  #
  #   font  = SFML::Assets.font("DejaVuSans")
  #   tex   = SFML::Assets.texture("hero")           # finds hero.png/.jpg/.bmp
  #   blip  = SFML::Assets.sound("blip")             # finds blip.wav/.ogg/...
  #   music = SFML::Assets.music("track")            # NOT cached (stateful)
  #
  # By default the search root is `<dir of $0>/assets/`. Override:
  #
  #   SFML::Assets.root = File.expand_path("data", __dir__)
  #   SFML::Assets.add_search_path("/usr/local/share/mygame")
  #
  # Cache survives until you call .clear or the process exits.
  module Assets
    # File extensions recognised as image / texture assets.
    TEXTURE_EXTS = %w[.png .jpg .jpeg .bmp .gif .tga].freeze
    # File extensions recognised as short-sound assets.
    SOUND_EXTS   = %w[.wav .ogg .flac .mp3].freeze
    # File extensions recognised as music (streamed) assets — same as `SOUND_EXTS`.
    MUSIC_EXTS   = SOUND_EXTS
    # File extensions recognised as font assets.
    FONT_EXTS    = %w[.ttf .otf].freeze

    class NotFound < SFML::Error; end

    class << self
      # Current list of directories scanned by `#font`, `#texture`,
      # etc. Defaults to `<dir of $0>/assets/`. Mutate via
      # `#root=` / `#add_search_path` / `#search_paths=`.
      def search_paths
        @search_paths ||= [default_root]
      end

      # Replace the entire search-path list. Resets the cache so
      # the next load re-resolves from the new locations.
      def search_paths=(paths)
        @search_paths = Array(paths).map { |p| File.expand_path(p) }
        @cache&.clear
      end

      # Convenience for "use exactly this one directory" — shorthand
      # for `search_paths = [path]`.
      def root=(path)
        self.search_paths = [path]
      end

      # Append a directory to the end of `#search_paths` unless it's
      # already present. Useful for adding mod / DLC directories
      # without nuking the default search root.
      def add_search_path(path)
        search_paths << File.expand_path(path) unless search_paths.include?(File.expand_path(path))
      end

      # Drop everything from the in-memory cache. New loads will re-read
      # from disk and recreate textures, fonts, sound buffers.
      def clear
        @cache&.clear
        self
      end

      # Load (or fetch from cache) an `SFML::Font` by name — searches
      # `#search_paths` for any of `FONT_EXTS`, falls back to system
      # fonts via `Font.find`.
      def font(name)
        cache[[:font, name]] ||= load_font(name)
      end

      # Load (or fetch from cache) an `SFML::Texture` by name.
      def texture(name)
        cache[[:texture, name]] ||= load_texture(name)
      end

      # Load (or fetch from cache) an `SFML::SoundBuffer` by name.
      def sound(name)
        cache[[:sound, name]] ||= load_sound_buffer(name)
      end

      # Load a fresh `SFML::Music` by name. **Not cached** — each
      # caller gets its own playback position.
      def music(name)
        path = locate(name, MUSIC_EXTS) or raise NotFound,
          "Music #{name.inspect} not found. Searched: #{search_paths.inspect}"
        Music.load(path)
      end

      private

      # Returns the cache.
      def cache
        @cache ||= {}
      end

      # Returns the default root.
      def default_root
        File.expand_path("assets", File.dirname($PROGRAM_NAME || "."))
      end

      # Returns the load font.
      def load_font(name)
        path = locate(name, FONT_EXTS)
        return Font.load(path) if path
        # Fall back to a system-font search — fonts are large and rarely
        # shipped with games, so this often does the right thing.
        Font.find(name) or raise NotFound,
          "Font #{name.inspect} not found in #{search_paths.inspect} or system fonts"
      end

      # Returns the load texture.
      def load_texture(name)
        path = locate(name, TEXTURE_EXTS) or raise NotFound,
          "Texture #{name.inspect} not found. Searched: #{search_paths.inspect}"
        Texture.load(path)
      end

      # Returns the load sound buffer.
      def load_sound_buffer(name)
        path = locate(name, SOUND_EXTS) or raise NotFound,
          "Sound #{name.inspect} not found. Searched: #{search_paths.inspect}"
        SoundBuffer.load(path)
      end

      # Finds an asset on disk. If `name` already has a matching extension,
      # uses it as-is; otherwise tries each extension in order.
      def locate(name, extensions)
        name_str = name.to_s
        candidates =
          if extensions.any? { |ext| name_str.end_with?(ext) }
            [name_str]
          else
            extensions.map { |ext| "#{name_str}#{ext}" }
          end

        search_paths.each do |dir|
          candidates.each do |cand|
            full = File.join(dir, cand)
            return full if File.file?(full)
          end
        end
        nil
      end
    end
  end
end
