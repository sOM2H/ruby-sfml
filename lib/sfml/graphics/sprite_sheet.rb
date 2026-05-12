module SFML
  # A grid-based slice of a texture. Where `TextureAtlas` loads an
  # already-packed sheet with named frames, `SpriteSheet` slices a
  # uniformly-gridded image into numbered frames at load time.
  #
  # Use a SpriteSheet when your art is a regular grid (run cycles
  # baked at 32×32 cells); use a TextureAtlas when frames are
  # densely packed at irregular sizes.
  #
  #   sheet = SFML::SpriteSheet.load("hero.png", frame_size: [32, 32])
  #
  #   sheet.frame_count       # 8 if the image is 256×32
  #   sheet.region(0)         # SFML::Rect of the first cell
  #   sheet.sprite(0)         # ready-to-draw SFML::Sprite of the first cell
  #
  # `frame_size` can be a `[w, h]` pair (one number for both if
  # `frame_size: 32`). `padding` and `margin` let you skip pixels
  # between cells and around the edge respectively — common when
  # the source image has separators or a 1px outline to prevent
  # bleed.
  class SpriteSheet
    # Returns the self.
    def self.load(path, frame_size:, padding: 0, margin: 0, smooth: true)
      new(texture: Texture.load(path, smooth: smooth),
          frame_size: frame_size, padding: padding, margin: margin)
    end

    def initialize(texture:, frame_size:, padding: 0, margin: 0)
      @texture = texture
      fw, fh = _pair(frame_size)
      pw, ph = _pair(padding)
      mw, mh = _pair(margin)

      tex_w, tex_h = texture.size.x, texture.size.y
      @cols = (tex_w - 2 * mw + pw) / (fw + pw)
      @rows = (tex_h - 2 * mh + ph) / (fh + ph)
      @frame_w, @frame_h = fw, fh

      # Pre-compute every rect once. Cheap (a few hundred at most),
      # and #region becomes a flat array lookup.
      @regions = Array.new(@cols * @rows) do |i|
        col = i % @cols
        row = i / @cols
        x = mw + col * (fw + pw)
        y = mh + row * (fh + ph)
        Rect.new([x, y], [fw, fh])
      end.freeze
    end

    # The texture, cols, rows, frame w, frame h components.
    attr_reader :texture, :cols, :rows, :frame_w, :frame_h

    # Returns the frame count.
    def frame_count = @regions.size

    # The pixel Rect for cell `index` (0 = top-left, increases
    # row-major). Negative indexes wrap (e.g. -1 = last).
    def region(index)
      i = Integer(index) % frame_count
      @regions[i]
    end

    # `[col, row]` accessor for callers who prefer 2D coords.
    def region_at(col, row)
      raise IndexError, "col #{col} out of range (cols: #{@cols})" if col < 0 || col >= @cols
      raise IndexError, "row #{row} out of range (rows: #{@rows})" if row < 0 || row >= @rows
      @regions[row * @cols + col]
    end

    # Fresh Sprite pointing at cell `index`. Combine with `#sprite=`
    # patterns or feed into `SFML::Animation`.
    def sprite(index, **opts)
      Sprite.new(@texture, **opts).tap { |s| s.texture_rect = region(index) }
    end

    # An Animation looping through `frame_indexes` (defaults to all
    # frames in row-major order).
    def animation(frame_indexes: nil, fps: 12, loop: true)
      indexes = frame_indexes || (0...frame_count).to_a
      Animation.new(
        self,
        frames: indexes.map { |i| region(i) },
        fps:    fps,
        loop:   loop,
      )
    end

    # String representation for debugging.
    def to_s = "#<SpriteSheet #{@cols}×#{@rows} (#{@frame_w}×#{@frame_h}px cells)>"
    alias inspect to_s

    private

    # Accept 32 OR [32, 32] OR Vector2[32, 32].
    def _pair(value)
      case value
      when Numeric then [Integer(value), Integer(value)]
      when Vector2 then [Integer(value.x), Integer(value.y)]
      when Array   then value.map { |n| Integer(n) }
      else raise ArgumentError, "expected Integer, [w, h], or Vector2; got #{value.class}"
      end
    end
  end
end
