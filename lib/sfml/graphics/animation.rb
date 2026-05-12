module SFML
  # A frame-based animation that drives a Sprite's `texture_rect`
  # over time. Pair it with a `SpriteSheet` or `TextureAtlas`.
  #
  #   sheet  = SFML::SpriteSheet.load("hero.png", frame_size: [32, 32])
  #   walk   = sheet.animation(fps: 12, loop: true)
  #
  #   def update(dt)
  #     walk.update(dt)
  #   end
  #
  #   def draw
  #     window.draw(walk.sprite)
  #   end
  #
  # `Animation` is a self-contained drawable — it builds its own
  # internal `Sprite` and advances `texture_rect` on each `#update`.
  # Use `#sprite` to access the current frame's Sprite for
  # transform setters (`position=`, `rotation=`, etc.), or call
  # `Animation#draw_on(target)` directly.
  #
  # `frames` may be:
  #
  # * An Array of `SFML::Rect` — used as texture_rects in order.
  # * An Array of Integer indexes paired with `sprite_sheet:`.
  # * Constructed implicitly via `SpriteSheet#animation` or
  #   `TextureAtlas#animation` (see those classes).
  class Animation
    # @param source [SpriteSheet, TextureAtlas, Texture] backing image
    # @param frames [Array<SFML::Rect>] texture rects to cycle through
    # @param fps [Numeric] frames per second
    # @param loop [Boolean] restart at the end if true; pause if false
    def initialize(source, frames:, fps: 12, loop: true)
      raise ArgumentError, "Animation needs at least one frame" if frames.empty?

      texture =
        case source
        when Texture       then source
        when SpriteSheet,
             TextureAtlas  then source.texture
        else raise ArgumentError, "Animation source must be Texture / SpriteSheet / TextureAtlas"
        end

      @frames        = frames
      @frame_seconds = 1.0 / Float(fps)
      @loop          = loop
      @sprite        = Sprite.new(texture)
      @sprite.texture_rect = @frames.first
      @elapsed       = 0.0
      @frame_index   = 0
      @done          = false
    end

    attr_reader :sprite, :frame_index

    # Returns whether the animation has reached the end (only
    # meaningful for non-looping animations).
    def done? = @done

    # `true` if playing.
    def playing? = !@done

    # Advance by `dt` (a `SFML::Time` or seconds Float). Updates
    # the internal sprite's texture_rect to the current frame.
    def update(dt)
      return if @done

      seconds = dt.is_a?(Time) ? dt.as_seconds : Float(dt)
      @elapsed += seconds

      while @elapsed >= @frame_seconds
        @elapsed -= @frame_seconds
        @frame_index += 1
        if @frame_index >= @frames.size
          if @loop
            @frame_index = 0
          else
            @frame_index = @frames.size - 1
            @done = true
            break
          end
        end
      end

      @sprite.texture_rect = @frames[@frame_index]
      self
    end

    # Rewind to the first frame and clear the done flag.
    def reset
      @frame_index = 0
      @elapsed     = 0.0
      @done        = false
      @sprite.texture_rect = @frames.first
      self
    end

    # Total animation duration in seconds.
    def duration = @frames.size * @frame_seconds

    # Drawable interface — forwards to the internal Sprite.
    def draw_on(target, states_ptr = nil)
      @sprite.draw_on(target, states_ptr)
    end

    # Transform passthroughs so callers can write `anim.position =`
    # instead of `anim.sprite.position =`. The full surface of
    # Sprite stays accessible via `#sprite` for advanced cases
    # (color, scale_by, custom blend states, etc.).
    def position    = @sprite.position
    # Set the position.
    def position=(v); @sprite.position = v; end
    # Returns the rotation.
    def rotation    = @sprite.rotation
    # Set the rotation.
    def rotation=(v); @sprite.rotation = v; end
    # Returns the scale.
    def scale       = @sprite.scale
    # Set the scale.
    def scale=(v);    @sprite.scale = v; end
    # Returns the origin.
    def origin      = @sprite.origin
    # Set the origin.
    def origin=(v);   @sprite.origin = v; end
    # Returns the color.
    def color       = @sprite.color
    # Set the color.
    def color=(v);    @sprite.color = v; end
  end
end
