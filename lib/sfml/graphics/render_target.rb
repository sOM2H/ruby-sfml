module SFML
  module Graphics
    # Shared behaviour between SFML::RenderWindow and SFML::RenderTexture.
    # The two CSFML APIs are near-mirrors of each other (sfRenderWindow_*
    # vs sfRenderTexture_*), so the Ruby side dispatches by the includer's
    # CSFML_PREFIX constant. Adding a new render target only takes:
    #
    #   class NewTarget
    #     include Graphics::RenderTarget
    #     CSFML_PREFIX = :sfNewTarget
    #     ...
    #   end
    #
    # Drawables call `target._draw_native(:CircleShape, handle)` to dispatch
    # through the right CSFML draw function for whichever target they're
    # being rendered to.
    module RenderTarget
      def clear(color = Color::BLACK)
        _csfml(:clear, @handle, color.to_native)
        self
      end

      def display
        _csfml(:display, @handle)
        self
      end

      # Polymorphic draw: any drawable with a #draw_on(target, [states])
      # method. Built-in drawables call back into target._draw_native.
      #
      # Pass shortcut kwargs to apply render states without instantiating
      # SFML::RenderStates yourself:
      #
      #   window.draw(va,    texture: tile_texture)
      #   window.draw(glow,  blend_mode: SFML::BlendMode::ADD)
      #   window.draw(thing, texture: tex, blend_mode: SFML::BlendMode::ADD)
      #
      # Or pass a pre-built object for re-use across calls:
      #
      #   window.draw(thing, render_states: shared_states)
      def draw(drawable, render_states: nil, **opts)
        states     = render_states || RenderStates.from_draw_opts(opts)
        states_ptr = states&.to_native_pointer
        drawable.draw_on(self, states_ptr)
        self
      end

      # @!visibility private
      # Invoke the right CSFML draw function for this target + drawable
      # kind. `kind` is the suffix after `draw`: e.g. :CircleShape →
      # sfRenderWindow_drawCircleShape on a window, sfRenderTexture_drawCircleShape
      # on a texture. `states_ptr` may be nil for default render states.
      def _draw_native(kind, drawable_handle, states_ptr = nil)
        C::Graphics.public_send(
          :"#{self.class::CSFML_PREFIX}_draw#{kind}",
          @handle, drawable_handle, states_ptr,
        )
      end

      def view=(value)
        raise ArgumentError, "#{self.class}#view= requires a SFML::View" unless value.is_a?(View)
        _csfml(:setView, @handle, value.handle)
        @view = value
      end

      def view
        View.from_borrowed(_csfml(:getView, @handle))
      end

      # The default 1:1 view that matches the target's pixel size.
      # Memoised — see the comment in render_window.rb for why.
      def default_view
        @default_view ||= View.from_borrowed(_csfml(:getDefaultView, @handle))
      end

      def map_pixel_to_coords(pixel, view: nil)
        vec = C::System::Vector2i.new
        px, py = pixel.is_a?(Vector2) ? [pixel.x, pixel.y] : pixel
        vec[:x] = Integer(px); vec[:y] = Integer(py)

        v_handle = view ? view.handle : _csfml(:getView, @handle)
        result = _csfml(:mapPixelToCoords, @handle, vec, v_handle)
        Vector2.new(result[:x], result[:y])
      end

      def map_coords_to_pixel(coord, view: nil)
        vec = C::System::Vector2f.new
        cx, cy = coord.is_a?(Vector2) ? [coord.x, coord.y] : coord
        vec[:x] = cx.to_f; vec[:y] = cy.to_f

        v_handle = view ? view.handle : _csfml(:getView, @handle)
        result = _csfml(:mapCoordsToPixel, @handle, vec, v_handle)
        Vector2.new(result[:x], result[:y])
      end

      private

      def _csfml(suffix, *args)
        C::Graphics.public_send(:"#{self.class::CSFML_PREFIX}_#{suffix}", *args)
      end
    end
  end
end
