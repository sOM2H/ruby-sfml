require "json"

module SFML
  # A sprite-sheet plus a frame-name → rectangle index. Loads the
  # JSON descriptors that Aseprite and TexturePacker export — both
  # use the same `frames + meta` shape, just with a few field
  # differences we paper over.
  #
  #   atlas = SFML::TextureAtlas.load("hero.json")
  #
  #   atlas.texture                  #=> SFML::Texture
  #   atlas.region("hero-walk-0")    #=> SFML::Rect
  #   atlas.frame_names              #=> [...]
  #   atlas.sprite("hero-walk-0")    #=> ready-to-draw SFML::Sprite
  #   atlas.duration("hero-walk-0")  #=> Integer ms (Aseprite only)
  #
  # The image path inside the JSON is resolved relative to the JSON
  # file's directory. Override with `image: "path/to/img.png"`.
  #
  # Frame lookups are tolerant of the `.png` extension — Aseprite
  # exports `walk-0.png`, but you can write `atlas.region("walk-0")`.
  class TextureAtlas
    IMAGE_EXTS = /\.(?:png|jpg|jpeg|bmp|tga|gif)\z/i

    # @param json_path [String] path to the atlas JSON
    # @param image [String, nil] explicit image path (overrides
    #   the path embedded in the JSON's `meta.image` field)
    # @return [TextureAtlas]
    def self.load(json_path, image: nil, smooth: true)
      data = JSON.parse(File.read(json_path))
      image_path = image || File.expand_path(data.dig("meta", "image") || "", File.dirname(json_path))
      raise LoadError, "TextureAtlas: image not found at #{image_path}" unless File.file?(image_path)

      texture = Texture.load(image_path, smooth: smooth)
      regions, durations = _parse_frames(data["frames"])
      new(texture: texture, regions: regions, durations: durations, source: json_path)
    end

    # Build directly from a Texture + a frame Hash — useful when
    # generating atlases procedurally or when the descriptor lives
    # in a different format you've already parsed.
    def initialize(texture:, regions:, durations: {}, source: nil)
      @texture   = texture
      @regions   = regions.transform_keys { |k| _normalize(k) }.freeze
      @durations = durations.transform_keys { |k| _normalize(k) }.freeze
      @source    = source
    end

    attr_reader :texture, :source

    # Returns the frame names.
    def frame_names = @regions.keys

    # @return [SFML::Rect] the pixel rect for frame `name`.
    # @raise [SFML::LoadError] if the frame isn't in this atlas.
    def region(name)
      @regions[_normalize(name)] or
        raise LoadError, "TextureAtlas: no frame named #{name.inspect} " \
                         "(have: #{@regions.keys.first(5).inspect}...)"
    end

    # Build a fresh Sprite bound to the atlas texture with its
    # texture_rect set to this frame.
    def sprite(name, **opts)
      Sprite.new(@texture, **opts).tap { |s| s.texture_rect = region(name) }
    end

    # Build an Animation from a list of frame names. When `fps:` is
    # nil and Aseprite-style `duration` data is present, the per-frame
    # durations are used directly — letting artists set timing in
    # Aseprite without re-tuning in code. Pass an explicit `fps:` to
    # override.
    def animation(frame_names, fps: nil, loop: true)
      rects = frame_names.map { |n| region(n) }
      if fps.nil? && frame_names.first && duration(frame_names.first) > 0
        # Use Aseprite's per-frame ms timings — collapse to average
        # fps for the Animation; per-frame durations would need a
        # variable-rate Animation we don't ship yet.
        avg_ms = frame_names.map { |n| duration(n) }.sum / frame_names.size.to_f
        fps = 1000.0 / avg_ms if avg_ms > 0
      end
      Animation.new(self, frames: rects, fps: fps || 12, loop: loop)
    end

    # Integer milliseconds per frame, as exported by Aseprite. Returns
    # 0 if the source didn't include durations (TexturePacker etc.).
    def duration(name) = @durations[_normalize(name)] || 0

    # The internal frame-name → Rect hash. Useful for filtering:
    #
    #   walk_frames = atlas.regions.select { |k, _| k.start_with?("walk-") }
    def regions = @regions

    # String representation for debugging.
    def to_s = "#<TextureAtlas #{@regions.size} frames#{@source ? " from #{File.basename(@source)}" : ""}>"
    alias inspect to_s

    # @!visibility private
    def self._parse_frames(raw)
      regions   = {}
      durations = {}

      entries =
        case raw
        when Hash  then raw.map { |name, entry| [name, entry] }
        when Array then raw.map { |entry| [entry.fetch("filename"), entry] }
        else            raise LoadError, "TextureAtlas: unexpected `frames` shape: #{raw.class}"
        end

      entries.each do |name, entry|
        rect = entry.fetch("frame")
        regions[name]   = Rect.new([rect["x"], rect["y"]], [rect["w"], rect["h"]])
        durations[name] = entry["duration"] if entry["duration"]
      end

      [regions, durations]
    end
    private_class_method :_parse_frames

    private

    # Frame names are stored stripped of any image extension so
    # callers can use either `walk-0` or `walk-0.png`.
    def _normalize(name)
      name.to_s.sub(IMAGE_EXTS, "")
    end
  end
end
