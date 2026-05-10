module SFML
  module C
    module Graphics
      extend FFI::Library

      ffi_lib LIB_CANDIDATES[:graphics]

      class Color < FFI::Struct
        layout :r, :uint8, :g, :uint8, :b, :uint8, :a, :uint8
      end

      class FloatRect < FFI::Struct
        layout :position, System::Vector2f, :size, System::Vector2f
      end

      class IntRect < FFI::Struct
        layout :position, System::Vector2i, :size, System::Vector2i
      end

      # Render-state plumbing. The struct shapes mirror CSFML 3 exactly so
      # we can construct sfRenderStates by populating fields from kwargs
      # and passing the buffer pointer to sfRenderWindow_drawXxx.
      class BlendMode < FFI::Struct
        layout :color_src_factor, :int,
               :color_dst_factor, :int,
               :color_equation,   :int,
               :alpha_src_factor, :int,
               :alpha_dst_factor, :int,
               :alpha_equation,   :int
      end

      class StencilValue < FFI::Struct
        layout :value, :uint32
      end

      class StencilMode < FFI::Struct
        layout :comparison,        :int,
               :update_operation,  :int,
               :reference,         StencilValue,
               :mask,              StencilValue,
               :only_write_mask,   :bool
      end

      class Transform < FFI::Struct
        layout :matrix, [:float, 9]
      end

      class RenderStates < FFI::Struct
        layout :blend_mode,      BlendMode,
               :stencil_mode,    StencilMode,
               :transform,       Transform,
               :coordinate_type, :int,
               :texture,         :pointer,
               :shader,          :pointer
      end

      # CSFML exposes default-initialised values as global constants.
      # We read them at load time and copy from them when building Ruby
      # RenderStates / BlendMode to avoid hand-coding the SFML defaults.
      attach_variable :sfBlendAlpha,           BlendMode
      attach_variable :sfBlendAdd,             BlendMode
      attach_variable :sfBlendMultiply,        BlendMode
      attach_variable :sfBlendMin,             BlendMode
      attach_variable :sfBlendMax,             BlendMode
      attach_variable :sfBlendNone,            BlendMode
      attach_variable :sfRenderStates_default, RenderStates
      attach_variable :sfTransform_Identity,   Transform

      attach_function :sfTransform_combine,           [:pointer, :pointer], :void
      attach_function :sfTransform_translate,         [:pointer, System::Vector2f.by_value], :void
      attach_function :sfTransform_rotate,            [:pointer, :float], :void
      attach_function :sfTransform_rotateWithCenter,  [:pointer, :float, System::Vector2f.by_value], :void
      attach_function :sfTransform_scale,             [:pointer, System::Vector2f.by_value], :void
      attach_function :sfTransform_scaleWithCenter,   [:pointer, System::Vector2f.by_value, System::Vector2f.by_value], :void
      attach_function :sfTransform_getInverse,        [:pointer], Transform.by_value
      attach_function :sfTransform_transformPoint,    [:pointer, System::Vector2f.by_value], System::Vector2f.by_value
      attach_function :sfTransform_transformRect,     [:pointer, FloatRect.by_value], FloatRect.by_value
      attach_function :sfTransform_equal,             [:pointer, :pointer], :bool

      typedef :pointer, :render_window_t

      # See CSFML/Graphics/RenderWindow.h. The fifth param is a
      # `const sfContextSettings*` — pass `nil` for SFML defaults
      # or the pointer to a populated ContextSettings struct for
      # MSAA / depth-buffer / GL-version tuning.
      attach_function :sfRenderWindow_create,
                      [Window::VideoMode.by_value, :string, :uint32, :int, :pointer],
                      :render_window_t

      attach_function :sfRenderWindow_getSettings, [:render_window_t], Window::ContextSettings.by_value
      attach_function :sfRenderWindow_destroy,                [:render_window_t], :void
      attach_function :sfRenderWindow_close,                  [:render_window_t], :void
      attach_function :sfRenderWindow_isOpen,                 [:render_window_t], :bool
      attach_function :sfRenderWindow_pollEvent,              [:render_window_t, :pointer], :bool
      attach_function :sfRenderWindow_setTitle,               [:render_window_t, :string], :void
      attach_function :sfRenderWindow_setVerticalSyncEnabled, [:render_window_t, :bool], :void
      attach_function :sfRenderWindow_setFramerateLimit,      [:render_window_t, :uint32], :void
      attach_function :sfRenderWindow_display,                [:render_window_t], :void
      attach_function :sfRenderWindow_clear,                  [:render_window_t, Color.by_value], :void
      attach_function :sfRenderWindow_clearStencil,           [:render_window_t, StencilValue.by_value], :void
      attach_function :sfRenderWindow_clearColorAndStencil,   [:render_window_t, Color.by_value, StencilValue.by_value], :void
      attach_function :sfRenderWindow_getSize,                [:render_window_t], System::Vector2u.by_value
      attach_function :sfRenderWindow_setSize,                [:render_window_t, System::Vector2u.by_value], :void
      attach_function :sfRenderWindow_setIcon,                [:render_window_t, System::Vector2u.by_value, :pointer], :void

      typedef :pointer, :vertex_buffer_t
      attach_function :sfRenderWindow_setMinimumSize,         [:render_window_t, :pointer], :void
      attach_function :sfRenderWindow_setMaximumSize,         [:render_window_t, :pointer], :void
      attach_function :sfRenderWindow_createFromHandle,       [:pointer, :pointer], :render_window_t
      attach_function :sfRenderWindow_getNativeHandle,        [:render_window_t], :pointer
      attach_function :sfRenderWindow_hasFocus,               [:render_window_t], :bool
      attach_function :sfRenderWindow_requestFocus,           [:render_window_t], :void
      attach_function :sfRenderWindow_getPosition,            [:render_window_t], System::Vector2i.by_value
      attach_function :sfRenderWindow_setPosition,            [:render_window_t, System::Vector2i.by_value], :void
      attach_function :sfRenderWindow_setVisible,             [:render_window_t, :bool], :void
      attach_function :sfRenderWindow_setKeyRepeatEnabled,    [:render_window_t, :bool], :void
      attach_function :sfRenderWindow_setJoystickThreshold,   [:render_window_t, :float], :void
      attach_function :sfRenderWindow_setActive,              [:render_window_t, :bool], :bool
      attach_function :sfRenderWindow_pushGLStates,           [:render_window_t], :void
      attach_function :sfRenderWindow_popGLStates,            [:render_window_t], :void
      attach_function :sfRenderWindow_resetGLStates,          [:render_window_t], :void
      attach_function :sfRenderWindow_isSrgb,                 [:render_window_t], :bool
      attach_function :sfRenderWindow_waitEvent,              [:render_window_t, System::Time.by_value, :pointer], :bool
      attach_function :sfRenderWindow_getScissor,             [:render_window_t, :pointer], IntRect.by_value
      attach_function :sfRenderWindow_getViewport,            [:render_window_t, :pointer], IntRect.by_value

      typedef :pointer, :texture_t
      typedef :pointer, :render_texture_t
      typedef :pointer, :sprite_t
      typedef :pointer, :circle_shape_t
      typedef :pointer, :rectangle_shape_t
      typedef :pointer, :convex_shape_t
      typedef :pointer, :font_t
      typedef :pointer, :text_t
      typedef :pointer, :view_t
      typedef :pointer, :image_t
      typedef :pointer, :vertex_array_t
      typedef :pointer, :shader_t
      typedef :pointer, :render_states_t

      # GLSL types: vec2/vec3 are typedef'd to sfVector2f/sfVector3f, so
      # we don't need separate structs for those. The other arities are
      # fresh struct shapes.
      class GlslVec4 < FFI::Struct
        layout :x, :float, :y, :float, :z, :float, :w, :float
      end

      class GlslIvec3 < FFI::Struct
        layout :x, :int32, :y, :int32, :z, :int32
      end

      class GlslIvec4 < FFI::Struct
        layout :x, :int32, :y, :int32, :z, :int32, :w, :int32
      end

      class Vertex < FFI::Struct
        layout :position,   System::Vector2f,
               :color,      Color,
               :tex_coords, System::Vector2f
      end

      attach_function :sfRenderWindow_drawSprite,
                      [:render_window_t, :sprite_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawCircleShape,
                      [:render_window_t, :circle_shape_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawRectangleShape,
                      [:render_window_t, :rectangle_shape_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawConvexShape,
                      [:render_window_t, :convex_shape_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawText,
                      [:render_window_t, :text_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawVertexArray,
                      [:render_window_t, :vertex_array_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawVertexBuffer,
                      [:render_window_t, :vertex_buffer_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawVertexBufferRange,
                      [:render_window_t, :vertex_buffer_t, :uint32, :uint32, :render_states_t], :void

      # Mouse position queries relative to a render-window.
      attach_function :sfMouse_getPositionRenderWindow,
                      [:render_window_t], System::Vector2i.by_value
      attach_function :sfMouse_setPositionRenderWindow,
                      [System::Vector2i.by_value, :render_window_t], :void

      # Touch position relative to a render-window.
      attach_function :sfTouch_getPositionRenderWindow,
                      [:uint32, :render_window_t], System::Vector2i.by_value

      # ---- View ----
      attach_function :sfView_create,         [], :view_t
      attach_function :sfView_createFromRect, [FloatRect.by_value], :view_t
      attach_function :sfView_copy,           [:view_t], :view_t
      attach_function :sfView_destroy,        [:view_t], :void
      attach_function :sfView_setCenter,      [:view_t, System::Vector2f.by_value], :void
      attach_function :sfView_getCenter,      [:view_t], System::Vector2f.by_value
      attach_function :sfView_setSize,        [:view_t, System::Vector2f.by_value], :void
      attach_function :sfView_getSize,        [:view_t], System::Vector2f.by_value
      attach_function :sfView_setRotation,    [:view_t, :float], :void
      attach_function :sfView_getRotation,    [:view_t], :float
      attach_function :sfView_setViewport,    [:view_t, FloatRect.by_value], :void
      attach_function :sfView_getViewport,    [:view_t], FloatRect.by_value
      attach_function :sfView_setScissor,     [:view_t, FloatRect.by_value], :void
      attach_function :sfView_getScissor,     [:view_t], FloatRect.by_value
      attach_function :sfView_move,           [:view_t, System::Vector2f.by_value], :void
      attach_function :sfView_rotate,         [:view_t, :float], :void
      attach_function :sfView_zoom,           [:view_t, :float], :void

      # RenderWindow ↔ View bridge
      attach_function :sfRenderWindow_setMouseCursor,        [:render_window_t, :pointer], :void
      attach_function :sfRenderWindow_setMouseCursorVisible, [:render_window_t, :bool], :void
      attach_function :sfRenderWindow_setMouseCursorGrabbed, [:render_window_t, :bool], :void

      attach_function :sfRenderWindow_setView,        [:render_window_t, :view_t], :void
      attach_function :sfRenderWindow_getView,        [:render_window_t], :view_t
      attach_function :sfRenderWindow_getDefaultView, [:render_window_t], :view_t

      attach_function :sfRenderWindow_mapPixelToCoords,
                      [:render_window_t, System::Vector2i.by_value, :view_t],
                      System::Vector2f.by_value
      attach_function :sfRenderWindow_mapCoordsToPixel,
                      [:render_window_t, System::Vector2f.by_value, :view_t],
                      System::Vector2i.by_value

      # ---- Texture ----
      attach_function :sfTexture_create,         [System::Vector2u.by_value], :texture_t
      attach_function :sfTexture_createFromFile, [:string, :pointer], :texture_t
      attach_function :sfTexture_createFromImage,[:image_t, :pointer], :texture_t
      attach_function :sfTexture_createFromMemory,[:pointer, :size_t, :pointer], :texture_t
      attach_function :sfTexture_copy,           [:texture_t], :texture_t
      attach_function :sfTexture_resize,         [:texture_t, System::Vector2u.by_value], :bool
      attach_function :sfTexture_swap,           [:texture_t, :texture_t], :void
      attach_function :sfTexture_getNativeHandle,[:texture_t], :uint
      attach_function :sfTexture_updateFromTexture,
                      [:texture_t, :texture_t, System::Vector2u.by_value], :void
      attach_function :sfTexture_updateFromRenderWindow,
                      [:texture_t, :render_window_t, System::Vector2u.by_value], :void
      attach_function :sfTexture_updateFromWindow,
                      [:texture_t, :pointer, System::Vector2u.by_value], :void
      attach_function :sfTexture_isSrgb,         [:texture_t], :bool
      attach_function :sfTexture_generateMipmap, [:texture_t], :bool
      attach_function :sfTexture_getMaximumSize, [], :uint
      # `sfTexture_bind` takes a CoordinateType enum (0 = normalised,
      # 1 = pixels). Pass NULL to unbind.
      attach_function :sfTexture_bind,           [:texture_t, :int], :void
      attach_function :sfTexture_destroy,        [:texture_t], :void
      attach_function :sfTexture_getSize,        [:texture_t], System::Vector2u.by_value
      attach_function :sfTexture_setSmooth,      [:texture_t, :bool], :void
      attach_function :sfTexture_isSmooth,       [:texture_t], :bool
      attach_function :sfTexture_setRepeated,    [:texture_t, :bool], :void
      attach_function :sfTexture_isRepeated,     [:texture_t], :bool
      attach_function :sfTexture_copyToImage,    [:texture_t], :image_t
      attach_function :sfTexture_updateFromImage,[:texture_t, :image_t, System::Vector2u.by_value], :void
      attach_function :sfTexture_updateFromPixels,
                      [:texture_t, :pointer, System::Vector2u.by_value, System::Vector2u.by_value], :void

      # ---- Image ----
      attach_function :sfImage_create,            [System::Vector2u.by_value], :image_t
      attach_function :sfImage_createFromColor,   [System::Vector2u.by_value, Color.by_value], :image_t
      attach_function :sfImage_createFromPixels,  [System::Vector2u.by_value, :pointer], :image_t
      attach_function :sfImage_createFromFile,    [:string], :image_t
      attach_function :sfImage_createFromMemory,  [:pointer, :size_t], :image_t
      attach_function :sfImage_copy,              [:image_t], :image_t
      attach_function :sfImage_copyImage,         [:image_t, :image_t, System::Vector2u.by_value, IntRect.by_value, :bool], :bool
      attach_function :sfImage_destroy,           [:image_t], :void
      attach_function :sfImage_saveToFile,        [:image_t, :string], :bool
      attach_function :sfImage_saveToMemory,      [:image_t, :pointer, :string], :bool
      attach_function :sfImage_getSize,           [:image_t], System::Vector2u.by_value
      attach_function :sfImage_setPixel,          [:image_t, System::Vector2u.by_value, Color.by_value], :void
      attach_function :sfImage_getPixel,          [:image_t, System::Vector2u.by_value], Color.by_value
      attach_function :sfImage_getPixelsPtr,      [:image_t], :pointer
      attach_function :sfImage_createMaskFromColor, [:image_t, Color.by_value, :uint8], :void
      attach_function :sfImage_flipHorizontally,  [:image_t], :void
      attach_function :sfImage_flipVertically,    [:image_t], :void

      # ---- Sprite (transform-style methods are shared with shapes; same shape) ----
      attach_function :sfSprite_create,        [:texture_t], :sprite_t
      attach_function :sfSprite_destroy,       [:sprite_t], :void
      attach_function :sfSprite_setPosition,   [:sprite_t, System::Vector2f.by_value], :void
      attach_function :sfSprite_getPosition,   [:sprite_t], System::Vector2f.by_value
      attach_function :sfSprite_setRotation,   [:sprite_t, :float], :void
      attach_function :sfSprite_getRotation,   [:sprite_t], :float
      attach_function :sfSprite_setScale,      [:sprite_t, System::Vector2f.by_value], :void
      attach_function :sfSprite_getScale,      [:sprite_t], System::Vector2f.by_value
      attach_function :sfSprite_setOrigin,     [:sprite_t, System::Vector2f.by_value], :void
      attach_function :sfSprite_getOrigin,     [:sprite_t], System::Vector2f.by_value
      attach_function :sfSprite_move,          [:sprite_t, System::Vector2f.by_value], :void
      attach_function :sfSprite_rotate,        [:sprite_t, :float], :void
      attach_function :sfSprite_scale,         [:sprite_t, System::Vector2f.by_value], :void
      attach_function :sfSprite_setColor,      [:sprite_t, Color.by_value], :void
      attach_function :sfSprite_getColor,      [:sprite_t], Color.by_value
      attach_function :sfSprite_setTexture,    [:sprite_t, :texture_t, :bool], :void
      attach_function :sfSprite_getTexture,    [:sprite_t], :texture_t
      attach_function :sfSprite_copy,          [:sprite_t], :sprite_t
      attach_function :sfSprite_getTransform,  [:sprite_t], Transform.by_value
      attach_function :sfSprite_getInverseTransform, [:sprite_t], Transform.by_value

      # ---- CircleShape ----
      attach_function :sfCircleShape_create,             [], :circle_shape_t
      attach_function :sfCircleShape_destroy,            [:circle_shape_t], :void
      attach_function :sfCircleShape_setRadius,          [:circle_shape_t, :float], :void
      attach_function :sfCircleShape_getRadius,          [:circle_shape_t], :float
      attach_function :sfCircleShape_setPointCount,      [:circle_shape_t, :size_t], :void
      attach_function :sfCircleShape_getPointCount,      [:circle_shape_t], :size_t
      attach_function :sfCircleShape_setFillColor,       [:circle_shape_t, Color.by_value], :void
      attach_function :sfCircleShape_getFillColor,       [:circle_shape_t], Color.by_value
      attach_function :sfCircleShape_setOutlineColor,    [:circle_shape_t, Color.by_value], :void
      attach_function :sfCircleShape_getOutlineColor,    [:circle_shape_t], Color.by_value
      attach_function :sfCircleShape_setOutlineThickness,[:circle_shape_t, :float], :void
      attach_function :sfCircleShape_getOutlineThickness,[:circle_shape_t], :float
      attach_function :sfCircleShape_setPosition,        [:circle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfCircleShape_getPosition,        [:circle_shape_t], System::Vector2f.by_value
      attach_function :sfCircleShape_setRotation,        [:circle_shape_t, :float], :void
      attach_function :sfCircleShape_getRotation,        [:circle_shape_t], :float
      attach_function :sfCircleShape_setScale,           [:circle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfCircleShape_getScale,           [:circle_shape_t], System::Vector2f.by_value
      attach_function :sfCircleShape_setOrigin,          [:circle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfCircleShape_getOrigin,          [:circle_shape_t], System::Vector2f.by_value
      attach_function :sfCircleShape_move,               [:circle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfCircleShape_rotate,             [:circle_shape_t, :float], :void
      attach_function :sfCircleShape_scale,              [:circle_shape_t, System::Vector2f.by_value], :void

      # ---- RectangleShape ----
      attach_function :sfRectangleShape_create,             [], :rectangle_shape_t
      attach_function :sfRectangleShape_destroy,            [:rectangle_shape_t], :void
      attach_function :sfRectangleShape_setSize,            [:rectangle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfRectangleShape_getSize,            [:rectangle_shape_t], System::Vector2f.by_value
      attach_function :sfRectangleShape_setFillColor,       [:rectangle_shape_t, Color.by_value], :void
      attach_function :sfRectangleShape_getFillColor,       [:rectangle_shape_t], Color.by_value
      attach_function :sfRectangleShape_setOutlineColor,    [:rectangle_shape_t, Color.by_value], :void
      attach_function :sfRectangleShape_getOutlineColor,    [:rectangle_shape_t], Color.by_value
      attach_function :sfRectangleShape_setOutlineThickness,[:rectangle_shape_t, :float], :void
      attach_function :sfRectangleShape_getOutlineThickness,[:rectangle_shape_t], :float
      attach_function :sfRectangleShape_setPosition,        [:rectangle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfRectangleShape_getPosition,        [:rectangle_shape_t], System::Vector2f.by_value
      attach_function :sfRectangleShape_setRotation,        [:rectangle_shape_t, :float], :void
      attach_function :sfRectangleShape_getRotation,        [:rectangle_shape_t], :float
      attach_function :sfRectangleShape_setScale,           [:rectangle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfRectangleShape_getScale,           [:rectangle_shape_t], System::Vector2f.by_value
      attach_function :sfRectangleShape_setOrigin,          [:rectangle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfRectangleShape_getOrigin,          [:rectangle_shape_t], System::Vector2f.by_value
      attach_function :sfRectangleShape_move,               [:rectangle_shape_t, System::Vector2f.by_value], :void
      attach_function :sfRectangleShape_rotate,             [:rectangle_shape_t, :float], :void
      attach_function :sfRectangleShape_scale,              [:rectangle_shape_t, System::Vector2f.by_value], :void

      # ---- ConvexShape ----
      attach_function :sfConvexShape_create,                [], :convex_shape_t
      attach_function :sfConvexShape_destroy,               [:convex_shape_t], :void
      attach_function :sfConvexShape_setPointCount,         [:convex_shape_t, :size_t], :void
      attach_function :sfConvexShape_getPointCount,         [:convex_shape_t], :size_t
      attach_function :sfConvexShape_setPoint,              [:convex_shape_t, :size_t, System::Vector2f.by_value], :void
      attach_function :sfConvexShape_getPoint,              [:convex_shape_t, :size_t], System::Vector2f.by_value
      attach_function :sfConvexShape_setFillColor,          [:convex_shape_t, Color.by_value], :void
      attach_function :sfConvexShape_getFillColor,          [:convex_shape_t], Color.by_value
      attach_function :sfConvexShape_setOutlineColor,       [:convex_shape_t, Color.by_value], :void
      attach_function :sfConvexShape_getOutlineColor,       [:convex_shape_t], Color.by_value
      attach_function :sfConvexShape_setOutlineThickness,   [:convex_shape_t, :float], :void
      attach_function :sfConvexShape_getOutlineThickness,   [:convex_shape_t], :float
      attach_function :sfConvexShape_setPosition,           [:convex_shape_t, System::Vector2f.by_value], :void
      attach_function :sfConvexShape_getPosition,           [:convex_shape_t], System::Vector2f.by_value
      attach_function :sfConvexShape_setRotation,           [:convex_shape_t, :float], :void
      attach_function :sfConvexShape_getRotation,           [:convex_shape_t], :float
      attach_function :sfConvexShape_setScale,              [:convex_shape_t, System::Vector2f.by_value], :void
      attach_function :sfConvexShape_getScale,              [:convex_shape_t], System::Vector2f.by_value
      attach_function :sfConvexShape_setOrigin,             [:convex_shape_t, System::Vector2f.by_value], :void
      attach_function :sfConvexShape_getOrigin,             [:convex_shape_t], System::Vector2f.by_value
      attach_function :sfConvexShape_move,                  [:convex_shape_t, System::Vector2f.by_value], :void
      attach_function :sfConvexShape_rotate,                [:convex_shape_t, :float], :void
      attach_function :sfConvexShape_scale,                 [:convex_shape_t, System::Vector2f.by_value], :void

      # ---- VertexArray ----
      attach_function :sfVertexArray_create,            [], :vertex_array_t
      attach_function :sfVertexArray_destroy,           [:vertex_array_t], :void
      attach_function :sfVertexArray_getVertexCount,    [:vertex_array_t], :size_t
      attach_function :sfVertexArray_getVertex,         [:vertex_array_t, :size_t], :pointer
      attach_function :sfVertexArray_clear,             [:vertex_array_t], :void
      attach_function :sfVertexArray_resize,            [:vertex_array_t, :size_t], :void
      attach_function :sfVertexArray_append,            [:vertex_array_t, Vertex.by_value], :void
      attach_function :sfVertexArray_setPrimitiveType,  [:vertex_array_t, :int], :void
      attach_function :sfVertexArray_getPrimitiveType,  [:vertex_array_t], :int
      attach_function :sfVertexArray_getBounds,         [:vertex_array_t], FloatRect.by_value

      # ---- RenderTexture ----
      attach_function :sfRenderTexture_create,          [System::Vector2u.by_value, :pointer], :render_texture_t
      attach_function :sfRenderTexture_destroy,         [:render_texture_t], :void
      attach_function :sfRenderTexture_getSize,         [:render_texture_t], System::Vector2u.by_value
      attach_function :sfRenderTexture_setActive,       [:render_texture_t, :bool], :bool
      attach_function :sfRenderTexture_display,         [:render_texture_t], :void
      attach_function :sfRenderTexture_clear,           [:render_texture_t, Color.by_value], :void
      attach_function :sfRenderTexture_clearStencil,    [:render_texture_t, StencilValue.by_value], :void
      attach_function :sfRenderTexture_clearColorAndStencil,
                                                        [:render_texture_t, Color.by_value, StencilValue.by_value], :void
      attach_function :sfRenderTexture_setView,         [:render_texture_t, :view_t], :void
      attach_function :sfRenderTexture_getView,         [:render_texture_t], :view_t
      attach_function :sfRenderTexture_getDefaultView,  [:render_texture_t], :view_t
      attach_function :sfRenderTexture_getTexture,      [:render_texture_t], :texture_t
      attach_function :sfRenderTexture_setSmooth,       [:render_texture_t, :bool], :void
      attach_function :sfRenderTexture_isSmooth,        [:render_texture_t], :bool
      attach_function :sfRenderTexture_setRepeated,     [:render_texture_t, :bool], :void
      attach_function :sfRenderTexture_isRepeated,      [:render_texture_t], :bool
      attach_function :sfRenderTexture_isSrgb,          [:render_texture_t], :bool
      attach_function :sfRenderTexture_generateMipmap,  [:render_texture_t], :bool
      attach_function :sfRenderTexture_getMaximumAntiAliasingLevel, [], :uint
      attach_function :sfRenderTexture_pushGLStates,    [:render_texture_t], :void
      attach_function :sfRenderTexture_popGLStates,     [:render_texture_t], :void
      attach_function :sfRenderTexture_resetGLStates,   [:render_texture_t], :void
      attach_function :sfRenderTexture_getScissor,      [:render_texture_t, :view_t], IntRect.by_value
      attach_function :sfRenderTexture_getViewport,     [:render_texture_t, :view_t], IntRect.by_value

      attach_function :sfRenderTexture_mapPixelToCoords,
                      [:render_texture_t, System::Vector2i.by_value, :view_t],
                      System::Vector2f.by_value
      attach_function :sfRenderTexture_mapCoordsToPixel,
                      [:render_texture_t, System::Vector2f.by_value, :view_t],
                      System::Vector2i.by_value

      # Mirror sfRenderWindow_drawXxx for textures.
      attach_function :sfRenderTexture_drawSprite,          [:render_texture_t, :sprite_t,           :render_states_t], :void
      attach_function :sfRenderTexture_drawCircleShape,     [:render_texture_t, :circle_shape_t,     :render_states_t], :void
      attach_function :sfRenderTexture_drawRectangleShape,  [:render_texture_t, :rectangle_shape_t,  :render_states_t], :void
      attach_function :sfRenderTexture_drawConvexShape,     [:render_texture_t, :convex_shape_t,     :render_states_t], :void
      attach_function :sfRenderTexture_drawText,            [:render_texture_t, :text_t,             :render_states_t], :void
      attach_function :sfRenderTexture_drawVertexArray,     [:render_texture_t, :vertex_array_t,     :render_states_t], :void
      attach_function :sfRenderTexture_drawVertexBuffer,    [:render_texture_t, :vertex_buffer_t,    :render_states_t], :void
      attach_function :sfRenderTexture_drawVertexBufferRange,
                      [:render_texture_t, :vertex_buffer_t, :uint32, :uint32, :render_states_t], :void

      # ---- Raw primitive drawing (without a VertexArray object) ----
      attach_function :sfRenderWindow_drawPrimitives,
                      [:render_window_t,  :pointer, :size_t, :int, :render_states_t], :void
      attach_function :sfRenderTexture_drawPrimitives,
                      [:render_texture_t, :pointer, :size_t, :int, :render_states_t], :void

      # ---- Shader ----
      attach_function :sfShader_createFromFile,   [:string, :string, :string], :shader_t
      attach_function :sfShader_createFromMemory, [:string, :string, :string], :shader_t
      attach_function :sfShader_destroy,          [:shader_t], :void
      attach_function :sfShader_isAvailable,      [], :bool
      attach_function :sfShader_bind,             [:shader_t], :void
      attach_function :sfShader_getNativeHandle,  [:shader_t], :uint
      attach_function :sfShader_setIntColorUniform, [:shader_t, :string, Color.by_value], :void
      attach_function :sfShader_isGeometryAvailable, [], :bool

      attach_function :sfShader_setFloatUniform,  [:shader_t, :string, :float], :void
      attach_function :sfShader_setVec2Uniform,   [:shader_t, :string, System::Vector2f.by_value], :void
      attach_function :sfShader_setVec3Uniform,   [:shader_t, :string, System::Vector3f.by_value], :void
      attach_function :sfShader_setVec4Uniform,   [:shader_t, :string, GlslVec4.by_value], :void
      attach_function :sfShader_setIntUniform,    [:shader_t, :string, :int32], :void
      attach_function :sfShader_setIvec2Uniform,  [:shader_t, :string, System::Vector2i.by_value], :void
      attach_function :sfShader_setIvec3Uniform,  [:shader_t, :string, GlslIvec3.by_value], :void
      attach_function :sfShader_setIvec4Uniform,  [:shader_t, :string, GlslIvec4.by_value], :void
      attach_function :sfShader_setBoolUniform,   [:shader_t, :string, :bool], :void
      attach_function :sfShader_setColorUniform,  [:shader_t, :string, Color.by_value], :void
      attach_function :sfShader_setTextureUniform,[:shader_t, :string, :texture_t], :void
      attach_function :sfShader_setCurrentTextureUniform, [:shader_t, :string], :void

      # ---- VertexBuffer (static GPU vertex buffer) ----
      # USAGE order matches sfVertexBufferUsage in CSFML.
      VERTEX_BUFFER_USAGES = %i[stream dynamic static].freeze

      attach_function :sfVertexBuffer_create,         [:uint32, :int, :int], :vertex_buffer_t
      attach_function :sfVertexBuffer_copy,           [:vertex_buffer_t], :vertex_buffer_t
      attach_function :sfVertexBuffer_destroy,        [:vertex_buffer_t], :void
      attach_function :sfVertexBuffer_getVertexCount, [:vertex_buffer_t], :uint32
      attach_function :sfVertexBuffer_update,         [:vertex_buffer_t, :pointer, :uint32, :uint32], :bool
      attach_function :sfVertexBuffer_updateFromVertexBuffer,
                      [:vertex_buffer_t, :vertex_buffer_t], :bool
      attach_function :sfVertexBuffer_swap,           [:vertex_buffer_t, :vertex_buffer_t], :void
      attach_function :sfVertexBuffer_getNativeHandle,[:vertex_buffer_t], :uint32
      attach_function :sfVertexBuffer_setPrimitiveType,[:vertex_buffer_t, :int], :void
      attach_function :sfVertexBuffer_getPrimitiveType,[:vertex_buffer_t], :int
      attach_function :sfVertexBuffer_setUsage,       [:vertex_buffer_t, :int], :void
      attach_function :sfVertexBuffer_getUsage,       [:vertex_buffer_t], :int
      attach_function :sfVertexBuffer_isAvailable,    [], :bool

      # Bulk array uniform setters. The array argument is a packed
      # buffer of N elements (N×{1,2,3,4} floats); the length argument
      # is the *element* count, not the float count.
      attach_function :sfShader_setFloatUniformArray, [:shader_t, :string, :pointer, :size_t], :void
      attach_function :sfShader_setVec2UniformArray,  [:shader_t, :string, :pointer, :size_t], :void
      attach_function :sfShader_setVec3UniformArray,  [:shader_t, :string, :pointer, :size_t], :void
      attach_function :sfShader_setVec4UniformArray,  [:shader_t, :string, :pointer, :size_t], :void

      # ---- Font ----
      # `sfFontInfo` carries one field — the human-readable font
      # family. CSFML 3 expanded this struct's surface area only
      # through the existing `getInfo` getter; new fields would
      # arrive as additional struct members.
      class FontInfo < FFI::Struct
        layout :family, :pointer   # C string; copy out before the font is destroyed
      end

      attach_function :sfFont_createFromFile,        [:string], :font_t
      attach_function :sfFont_createFromMemory,      [:pointer, :size_t], :font_t
      attach_function :sfFont_copy,                  [:font_t], :font_t
      attach_function :sfFont_destroy,               [:font_t], :void
      attach_function :sfFont_setSmooth,             [:font_t, :bool], :void
      attach_function :sfFont_isSmooth,              [:font_t], :bool
      attach_function :sfFont_getInfo,               [:font_t], FontInfo.by_value
      attach_function :sfFont_hasGlyph,              [:font_t, :uint32], :bool
      attach_function :sfFont_getKerning,            [:font_t, :uint32, :uint32, :uint], :float
      attach_function :sfFont_getBoldKerning,        [:font_t, :uint32, :uint32, :uint], :float
      attach_function :sfFont_getLineSpacing,        [:font_t, :uint], :float
      attach_function :sfFont_getUnderlinePosition,  [:font_t, :uint], :float
      attach_function :sfFont_getUnderlineThickness, [:font_t, :uint], :float
      attach_function :sfFont_getTexture,            [:font_t, :uint], :texture_t

      # ---- Text ----
      attach_function :sfText_create,             [:font_t], :text_t
      attach_function :sfText_destroy,            [:text_t], :void
      # CSFML 3's sfText_setString takes a Latin-1 char*, so a multi-byte
      # UTF-8 string would render each byte as a separate (garbage) glyph.
      # We always go through the Unicode (UTF-32 / sfChar32*) variant,
      # converting to/from Ruby UTF-8 in the high-level wrapper.
      attach_function :sfText_setUnicodeString,   [:text_t, :pointer], :void
      attach_function :sfText_getUnicodeString,   [:text_t], :pointer
      attach_function :sfText_setFont,            [:text_t, :font_t], :void
      attach_function :sfText_setCharacterSize,   [:text_t, :uint32], :void
      attach_function :sfText_getCharacterSize,   [:text_t], :uint32
      attach_function :sfText_setFillColor,       [:text_t, Color.by_value], :void
      attach_function :sfText_getFillColor,       [:text_t], Color.by_value
      attach_function :sfText_setOutlineColor,    [:text_t, Color.by_value], :void
      attach_function :sfText_getOutlineColor,    [:text_t], Color.by_value
      attach_function :sfText_setOutlineThickness,[:text_t, :float], :void
      attach_function :sfText_getOutlineThickness,[:text_t], :float
      attach_function :sfText_setStyle,           [:text_t, :uint32], :void
      attach_function :sfText_getStyle,           [:text_t], :uint32
      attach_function :sfText_setLetterSpacing,   [:text_t, :float], :void
      attach_function :sfText_getLetterSpacing,   [:text_t], :float
      attach_function :sfText_setLineSpacing,     [:text_t, :float], :void
      attach_function :sfText_getLineSpacing,     [:text_t], :float
      attach_function :sfText_findCharacterPos,   [:text_t, :size_t], System::Vector2f.by_value
      attach_function :sfText_getFont,            [:text_t], :font_t
      attach_function :sfText_copy,               [:text_t], :text_t
      attach_function :sfText_getString,          [:text_t], :string
      attach_function :sfText_getTransform,       [:text_t], Transform.by_value
      attach_function :sfText_getInverseTransform,[:text_t], Transform.by_value
      attach_function :sfText_setPosition,        [:text_t, System::Vector2f.by_value], :void
      attach_function :sfText_getPosition,        [:text_t], System::Vector2f.by_value
      attach_function :sfText_setRotation,        [:text_t, :float], :void
      attach_function :sfText_getRotation,        [:text_t], :float
      attach_function :sfText_setScale,           [:text_t, System::Vector2f.by_value], :void
      attach_function :sfText_getScale,           [:text_t], System::Vector2f.by_value
      attach_function :sfText_setOrigin,          [:text_t, System::Vector2f.by_value], :void
      attach_function :sfText_getOrigin,          [:text_t], System::Vector2f.by_value
      attach_function :sfText_move,               [:text_t, System::Vector2f.by_value], :void
      attach_function :sfText_rotate,             [:text_t, :float], :void
      attach_function :sfText_scale,              [:text_t, System::Vector2f.by_value], :void
      attach_function :sfText_getLocalBounds,     [:text_t], FloatRect.by_value
      attach_function :sfText_getGlobalBounds,    [:text_t], FloatRect.by_value

      attach_function :sfSprite_setTextureRect,   [:sprite_t, IntRect.by_value], :void
      attach_function :sfSprite_getTextureRect,   [:sprite_t], IntRect.by_value
      attach_function :sfSprite_getLocalBounds,   [:sprite_t], FloatRect.by_value
      attach_function :sfSprite_getGlobalBounds,  [:sprite_t], FloatRect.by_value
    end
  end
end
