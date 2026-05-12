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
      # Clear the target's colour buffer (and optionally the stencil
      # buffer in the same call). Pass `stencil:` to clear the stencil
      # buffer to the given integer; pass only `stencil:` to clear the
      # stencil without touching colour.
      #
      #   target.clear                              # default black
      #   target.clear(SFML::Color.cornflower_blue) # only colour
      #   target.clear(SFML::Color.black, stencil: 0)  # both
      #   target.clear(stencil: 0)                  # only stencil
      def clear(color = nil, stencil: nil)
        if stencil && color
          _csfml(:clearColorAndStencil, @handle, color.to_native, _stencil_value(stencil))
        elsif stencil
          _csfml(:clearStencil, @handle, _stencil_value(stencil))
        else
          _csfml(:clear, @handle, (color || Color::BLACK).to_native)
        end
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

      # Draw a one-shot batch of vertices without allocating a
      # SFML::VertexArray. Useful for tight inner loops (a few dozen
      # primitives per frame, where the VertexArray's per-object
      # bookkeeping is itself the cost).
      #
      #   window.draw_primitives(
      #     [SFML::Vertex.new([0, 0], color: SFML::Color.red),
      #      SFML::Vertex.new([100, 0], color: SFML::Color.green),
      #      SFML::Vertex.new([50, 80], color: SFML::Color.blue)],
      #     :triangles,
      #   )
      #
      # Accepts the same render-states kwargs as #draw.
      def draw_primitives(vertices, primitive_type = :points, render_states: nil, **opts)
        type_code = VertexArray::PRIMITIVE_INDEX.fetch(primitive_type) do
          raise ArgumentError, "Unknown primitive type: #{primitive_type.inspect}"
        end

        # Pack the vertex array into a contiguous buffer.
        n   = vertices.length
        buf = FFI::MemoryPointer.new(C::Graphics::Vertex, n)
        vertices.each_with_index do |v, i|
          slot = C::Graphics::Vertex.new(buf + i * C::Graphics::Vertex.size)
          slot[:position][:x]   = v.position.x.to_f
          slot[:position][:y]   = v.position.y.to_f
          slot[:color][:r]      = v.color.r
          slot[:color][:g]      = v.color.g
          slot[:color][:b]      = v.color.b
          slot[:color][:a]      = v.color.a
          slot[:tex_coords][:x] = v.tex_coords.x.to_f
          slot[:tex_coords][:y] = v.tex_coords.y.to_f
        end

        states     = render_states || RenderStates.from_draw_opts(opts)
        states_ptr = states&.to_native_pointer

        C::Graphics.public_send(
          :"#{self.class::CSFML_PREFIX}_drawPrimitives",
          @handle, buf, n, type_code, states_ptr,
        )
        self
      end

      # Set the view.
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

      def _stencil_value(int)
        v = C::Graphics::StencilValue.new
        v[:value] = Integer(int)
        v
      end
    end
  end
end
