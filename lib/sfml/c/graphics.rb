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
      attach_function :sfRenderWindow_getSize,                [:render_window_t], System::Vector2u.by_value
      attach_function :sfRenderWindow_setSize,                [:render_window_t, System::Vector2u.by_value], :void

      typedef :pointer, :texture_t
      typedef :pointer, :sprite_t
      typedef :pointer, :circle_shape_t
      typedef :pointer, :rectangle_shape_t
      typedef :pointer, :font_t
      typedef :pointer, :text_t
      typedef :pointer, :view_t
      typedef :pointer, :image_t
      typedef :pointer, :render_states_t

      attach_function :sfRenderWindow_drawSprite,
                      [:render_window_t, :sprite_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawCircleShape,
                      [:render_window_t, :circle_shape_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawRectangleShape,
                      [:render_window_t, :rectangle_shape_t, :render_states_t], :void
      attach_function :sfRenderWindow_drawText,
                      [:render_window_t, :text_t, :render_states_t], :void

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
