module SFML
  module Graphics
    # Methods shared across CircleShape / RectangleShape / ConvexShape:
    # texture binding, geometry introspection, transform readout, dup.
    # Including class must define CSFML_PREFIX (Symbol) and hold the FFI
    # handle in @handle (same contract as Graphics::Transformable).
    #
    # Texture binding follows the Sprite pattern: keep a Ruby reference
    # to the bound texture in @texture so the GC doesn't collect the GPU
    # resource while the shape still draws with it.
    module ShapeInspectable
      def texture
        ptr = _csfml(:getTexture, @handle)
        return nil if ptr.null?
        Texture.send(:_borrow, ptr)
      end

      # `reset_rect: true` snaps the texture-rect to the full texture size,
      # which is usually what you want when binding a fresh texture.
      def set_texture(tex, reset_rect: false)
        raise ArgumentError, "expected SFML::Texture or nil" unless tex.nil? || tex.is_a?(Texture)
        _csfml(:setTexture, @handle, tex ? tex.handle : nil, reset_rect)
        @texture = tex
        self
      end

      # Set the texture.
      def texture=(tex)
        set_texture(tex, reset_rect: false)
      end

      def texture_rect
        Rect.from_native(_csfml(:getTextureRect, @handle))
      end

      # Set the texture rect.
      def texture_rect=(rect)
        raise ArgumentError, "texture_rect= requires a SFML::Rect" unless rect.is_a?(Rect)
        native = C::Graphics::IntRect.new
        native[:position][:x] = Integer(rect.x)
        native[:position][:y] = Integer(rect.y)
        native[:size][:x]     = Integer(rect.width)
        native[:size][:y]     = Integer(rect.height)
        _csfml(:setTextureRect, @handle, native)
      end

      # Single polygon vertex by index. The full list is exposed by the
      # subclass-specific `#points` method on ConvexShape; CircleShape
      # synthesises N points from its radius+point_count.
      def point(index)
        Vector2.from_native(_csfml(:getPoint, @handle, Integer(index)))
      end

      # Centroid of the polygon's vertex list (CSFML 3.0+).
      def geometric_center
        Vector2.from_native(_csfml(:getGeometricCenter, @handle))
      end

      # AABB before transform — the rectangle the geometry would occupy
      # if the shape were drawn at the origin with no rotation/scale.
      def local_bounds
        Rect.from_native(_csfml(:getLocalBounds, @handle))
      end

      # AABB after the shape's full transform — the world-space rect the
      # renderer uses for culling and hit-tests.
      def global_bounds
        Rect.from_native(_csfml(:getGlobalBounds, @handle))
      end

      def transform
        _csfml(:getTransform, @handle)
      end

      def inverse_transform
        _csfml(:getInverseTransform, @handle)
      end

      # Deep copy. Texture binding is shared (textures are GPU objects,
      # cheap to alias); transform/colour state is independent.
      def dup
        ptr = _csfml(:copy, @handle)
        raise GraphicsError, "#{self.class.name}#dup returned NULL" if ptr.null?

        destroy_fn = C::Graphics.method(:"#{self.class::CSFML_PREFIX}_destroy")
        copy = self.class.allocate
        copy.instance_variable_set(:@handle, FFI::AutoPointer.new(ptr, destroy_fn))
        copy.instance_variable_set(:@texture, @texture) if defined?(@texture)
        copy
      end
      alias clone dup
    end
  end
end
