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

      # See CSFML/Graphics/RenderWindow.h. We pass NULL for sfContextSettings
      # in the high-level wrapper; that matches SFML defaults.
      attach_function :sfRenderWindow_create,
                      [Window::VideoMode.by_value, :string, :uint32, :int, :pointer],
                      :render_window_t

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
      attach_function :sfRenderWindow_setMinimumSize,         [:render_window_t, :pointer], :void
      attach_function :sfRenderWindow_setMaximumSize,         [:render_window_t, :pointer], :void

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

      # Mouse position queries relative to a render-window.
      attach_function :sfMouse_getPositionRenderWindow,
                      [:render_window_t], System::Vector2i.by_value
      attach_function :sfMouse_setPositionRenderWindow,
                      [System::Vector2i.by_value, :render_window_t], :void

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
      attach_function :sfTexture_createFromFile, [:string, :pointer], :texture_t
      attach_function :sfTexture_createFromImage,[:image_t, :pointer], :texture_t
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
      attach_function :sfImage_copy,              [:image_t], :image_t
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

      # Bulk array uniform setters. The array argument is a packed
      # buffer of N elements (N×{1,2,3,4} floats); the length argument
      # is the *element* count, not the float count.
      attach_function :sfShader_setFloatUniformArray, [:shader_t, :string, :pointer, :size_t], :void
      attach_function :sfShader_setVec2UniformArray,  [:shader_t, :string, :pointer, :size_t], :void
      attach_function :sfShader_setVec3UniformArray,  [:shader_t, :string, :pointer, :size_t], :void
      attach_function :sfShader_setVec4UniformArray,  [:shader_t, :string, :pointer, :size_t], :void

      # ---- Font ----
      attach_function :sfFont_createFromFile, [:string], :font_t
      attach_function :sfFont_destroy,        [:font_t], :void
      attach_function :sfFont_setSmooth,      [:font_t, :bool], :void
      attach_function :sfFont_isSmooth,       [:font_t], :bool

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
      attach_function :sfText_setLineSpacing,     [:text_t, :float], :void
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
