module SFML
  module Graphics
    # Shared transform interface for Sprite, CircleShape, RectangleShape
    # (and Text once added). Including class must:
    #   1. Define a constant CSFML_PREFIX (Symbol), e.g. :sfCircleShape
    #   2. Hold the FFI handle in @handle
    #
    # All wrappers go through C::Graphics.public_send so the same Ruby code
    # picks up sfSprite_*, sfCircleShape_*, sfRectangleShape_* etc. without
    # repetition. The cost (~1µs of method dispatch on a typical call) is
    # negligible against any GPU work, but the wins on maintainability are
    # large — adding a new shape becomes ~5 lines.
    module Transformable
      # Current 2D position as a Vector2.
      def position
        Vector2.from_native(_csfml(:getPosition, @handle))
      end

      # Move to absolute `[x, y]` — accepts Vector2 or `[x, y]` Array.
      def position=(value)
        _csfml(:setPosition, @handle, _coerce_vec2(value).to_native_f)
      end

      # Current rotation in degrees (counter-clockwise positive).
      def rotation
        _csfml(:getRotation, @handle)
      end

      # Set absolute rotation in degrees.
      def rotation=(degrees)
        _csfml(:setRotation, @handle, degrees.to_f)
      end

      # Current scale factors as a Vector2 (`[1, 1]` means original size).
      def scale
        Vector2.from_native(_csfml(:getScale, @handle))
      end

      # Set the scale — accepts Vector2 or `[sx, sy]` Array.
      def scale=(value)
        _csfml(:setScale, @handle, _coerce_vec2(value).to_native_f)
      end

      # The local origin (pivot for rotation/scale). Default is `[0, 0]`
      # — set it to the centre of the bounding box for "rotate in place".
      def origin
        Vector2.from_native(_csfml(:getOrigin, @handle))
      end

      # Set the origin — accepts Vector2 or `[x, y]` Array.
      def origin=(value)
        _csfml(:setOrigin, @handle, _coerce_vec2(value).to_native_f)
      end

      # Translate by `offset` (relative move). Chainable — returns self.
      def move(offset)
        _csfml(:move, @handle, _coerce_vec2(offset).to_native_f)
        self
      end

      # Rotate by `degrees` (relative). Chainable.
      def rotate(degrees)
        _csfml(:rotate, @handle, degrees.to_f)
        self
      end

      # Multiply current scale by `factors` (relative scale). Chainable.
      def scale_by(factors)
        _csfml(:scale, @handle, _coerce_vec2(factors).to_native_f)
        self
      end

      private

      def _csfml(suffix, *args)
        C::Graphics.public_send(:"#{self.class::CSFML_PREFIX}_#{suffix}", *args)
      end

      # Accept a Vector2 or any [x, y] pair so users can pass a literal:
      #   shape.position = [400, 300]
      def _coerce_vec2(value)
        value.is_a?(Vector2) ? value : Vector2.new(*value)
      end
    end
  end
end
