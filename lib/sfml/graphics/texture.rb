module SFML
  # A 2D image stored on the GPU. Used by Sprite (and shapes) to draw textured
  # geometry. Build one with .load:
  #
  #   tex = SFML::Texture.load("assets/hero.png")
  #   tex = SFML::Texture.load("assets/tile.png", smooth: true, repeated: true)
  class Texture
    # Load a texture from a file on disk.
    #
    # Pass `srgb: true` if the source pixels are in sRGB-encoded
    # gamma space (most photo/PNG art assets) and you want the GPU
    # to gamma-decode on sample so blending happens in linear space.
    # Pair with `RenderWindow#new(..., srgb_capable: true)` and your
    # final framebuffer will gamma-encode on present.
    def self.load(path, smooth: false, repeated: false, srgb: false)
      ptr = srgb \
        ? C::Graphics.sfTexture_createSrgbFromFile(path.to_s, nil) \
        : C::Graphics.sfTexture_createFromFile(path.to_s, nil)
      raise LoadError, "Could not load texture from #{path.inspect}" if ptr.null?

      tex = allocate
      tex.send(:_take_ownership, ptr)
      tex.smooth   = smooth
      tex.repeated = repeated
      tex
    end

    # Allocate a blank texture on the GPU at the given size — use
    # `update(image)` afterwards to upload pixels. Useful when
    # you'll be filling the texture from a procedurally-generated
    # Image or repeatedly streaming pixel data into it.
    def self.create(width, height, srgb: false)
      size = C::System::Vector2u.new
      size[:x] = Integer(width); size[:y] = Integer(height)
      ptr = srgb ? C::Graphics.sfTexture_createSrgb(size) : C::Graphics.sfTexture_create(size)
      raise GraphicsError, "sfTexture_create returned NULL — out of GPU memory?" if ptr.null?

      tex = allocate
      tex.send(:_take_ownership, ptr)
      tex
    end

    # Decode + upload a Ruby String of bytes (PNG, JPG, BMP, …) as
    # a texture. Useful for embedded assets / network responses
    # that bypass the disk.
    def self.from_memory(bytes, smooth: false, repeated: false, srgb: false)
      raise ArgumentError, "expected a String, got #{bytes.class}" unless bytes.is_a?(String)

      buf = FFI::MemoryPointer.new(:uint8, bytes.bytesize)
      buf.write_bytes(bytes)
      ptr = srgb \
        ? C::Graphics.sfTexture_createSrgbFromMemory(buf, bytes.bytesize, nil) \
        : C::Graphics.sfTexture_createFromMemory(buf, bytes.bytesize, nil)
      raise LoadError, "sfTexture_createFromMemory returned NULL — unsupported format?" if ptr.null?

      tex = allocate
      tex.send(:_take_ownership, ptr)
      tex.smooth   = smooth
      tex.repeated = repeated
      tex
    end

    # Load a texture from any Ruby IO-like object (File, StringIO,
    # or anything answering read/seek/pos/size). Useful for assets
    # inside a zip archive, served over a socket, or generated on
    # the fly.
    def self.from_stream(io, smooth: false, repeated: false, srgb: false)
      stream = SFML::InputStream.new(io)
      ptr = srgb \
        ? C::Graphics.sfTexture_createSrgbFromStream(stream.to_ptr, nil) \
        : C::Graphics.sfTexture_createFromStream(stream.to_ptr, nil)
      raise LoadError, "sfTexture_createFromStream returned NULL — unsupported format?" if ptr.null?

      tex = allocate
      tex.send(:_take_ownership, ptr)
      tex.smooth   = smooth
      tex.repeated = repeated
      tex
    end

    # Upload a CPU-side SFML::Image to the GPU as a new Texture. Keeps
    # the RGBA byte order and dimensions of the source image.
    def self.from_image(image, smooth: false, repeated: false, srgb: false)
      raise ArgumentError, "Texture.from_image needs a SFML::Image" unless image.is_a?(Image)

      ptr = srgb \
        ? C::Graphics.sfTexture_createSrgbFromImage(image.handle, nil) \
        : C::Graphics.sfTexture_createFromImage(image.handle, nil)
      raise LoadError, "sfTexture_createFromImage returned NULL" if ptr.null?

      tex = allocate
      tex.send(:_take_ownership, ptr)
      tex.smooth   = smooth
      tex.repeated = repeated
      tex
    end

    # Re-upload an Image's pixels to this texture in place. The image
    # must match the texture's size — use this for animated procedural
    # textures (paint-buffer style) without re-allocating GPU memory.
    def update(image)
      raise ArgumentError, "Texture#update needs a SFML::Image" unless image.is_a?(Image)
      offset = C::System::Vector2u.new
      offset[:x] = 0; offset[:y] = 0
      C::Graphics.sfTexture_updateFromImage(@handle, image.handle, offset)
      self
    end

    # Read the texture back from the GPU into a fresh SFML::Image. Slow
    # — useful for screenshots or post-processing inspection.
    def to_image
      ptr = C::Graphics.sfTexture_copyToImage(@handle)
      raise GraphicsError, "sfTexture_copyToImage returned NULL" if ptr.null?
      img = Image.allocate
      img.send(:_take_ownership, ptr)
      img
    end

    def size
      Vector2.from_native(C::Graphics.sfTexture_getSize(@handle))
    end

    def smooth?  = C::Graphics.sfTexture_isSmooth(@handle)

    def smooth=(value)
      C::Graphics.sfTexture_setSmooth(@handle, !!value)
    end

    def repeated? = C::Graphics.sfTexture_isRepeated(@handle)

    def repeated=(value)
      C::Graphics.sfTexture_setRepeated(@handle, !!value)
    end

    def srgb? = C::Graphics.sfTexture_isSrgb(@handle)

    # Generate mipmaps for this texture. Returns `true` if the
    # GPU honoured it. Required for the `_MIPMAP_*` minification
    # filters; otherwise downscaled samples alias.
    def generate_mipmap = C::Graphics.sfTexture_generateMipmap(@handle)

    # Bind this texture to the active OpenGL texture unit. `coord`
    # is one of `:normalized` (default — UVs in [0..1]) or
    # `:pixels` (UVs in [0..size]). Useful when mixing raw
    # OpenGL with SFML rendering. Pass `nil` to unbind:
    #   `SFML::Texture.unbind`.
    COORDINATE_TYPES = {normalized: 0, pixels: 1}.freeze

    def bind(coord: :normalized)
      raise ArgumentError, "coord must be :normalized or :pixels" unless COORDINATE_TYPES.key?(coord)
      C::Graphics.sfTexture_bind(@handle, COORDINATE_TYPES[coord])
    end

    def self.unbind
      C::Graphics.sfTexture_bind(nil, 0)
    end

    # Maximum texture dimension the driver will allocate. Tied to
    # the GL state, so it's a class-level call (no instance).
    def self.maximum_size
      C::Graphics.sfTexture_getMaximumSize
    end

    # Deep copy. The returned texture has its own GPU memory.
    def dup
      ptr = C::Graphics.sfTexture_copy(@handle)
      raise GraphicsError, "sfTexture_copy returned NULL" if ptr.null?

      tex = self.class.allocate
      tex.send(:_take_ownership, ptr)
      tex
    end
    alias clone dup

    # Reallocate this texture's GPU memory at a new size. Returns
    # `false` if the GPU rejects the size (driver limit / OOM);
    # the texture's contents become undefined on success.
    # Pass `srgb: true` to re-allocate as an sRGB-encoded texture.
    def resize(width, height, srgb: false)
      size = C::System::Vector2u.new
      size[:x] = Integer(width); size[:y] = Integer(height)
      if srgb
        C::Graphics.sfTexture_resizeSrgb(@handle, size)
      else
        C::Graphics.sfTexture_resize(@handle, size)
      end
    end

    # Atomically swap the GPU memory between two textures —
    # cheaper than `dup` + reassign for double-buffer-style
    # patterns (paint-buffer ⇄ visible-buffer).
    def swap(other)
      raise ArgumentError, "Texture#swap needs a Texture" unless other.is_a?(Texture)
      C::Graphics.sfTexture_swap(@handle, other.handle)
      self
    end

    # The OpenGL texture-object name (a `glGenTextures` ID).
    # Useful when feeding this texture into raw GL calls.
    def native_handle = C::Graphics.sfTexture_getNativeHandle(@handle)

    # Upload the contents of another texture into this one at
    # `offset` (`[x, y]`). Both textures must remain alive for the
    # duration of the call.
    def update_from_texture(source, offset: [0, 0])
      raise ArgumentError, "expected a Texture" unless source.is_a?(Texture)
      C::Graphics.sfTexture_updateFromTexture(@handle, source.handle, _vec2u(offset))
      self
    end

    # Read the back-buffer of a `RenderWindow` into this texture
    # at `offset`. Useful for capturing the rendered scene
    # without re-drawing into a separate `RenderTexture`.
    def update_from_render_window(window, offset: [0, 0])
      raise ArgumentError, "expected a RenderWindow" unless window.is_a?(RenderWindow)
      C::Graphics.sfTexture_updateFromRenderWindow(@handle, window.handle, _vec2u(offset))
      self
    end

    # Same as `update_from_render_window` for the bare `Window`
    # (when you're managing GL yourself).
    def update_from_window(window, offset: [0, 0])
      raise ArgumentError, "expected a Window" unless window.is_a?(SFML::Window)
      C::Graphics.sfTexture_updateFromWindow(@handle, window.handle, _vec2u(offset))
      self
    end

    attr_reader :handle # :nodoc:

    # Internal — borrow a CSFML-owned `sfTexture*` (e.g. one
    # returned by `sfFont_getTexture`) without registering an
    # auto-destroy hook. The owning object is responsible for
    # outliving any draw call that uses this borrowed handle.
    def self._borrow(ptr)
      tex = allocate
      tex.instance_variable_set(:@handle, ptr)
      tex
    end

    private

    def _take_ownership(ptr)
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfTexture_destroy))
    end

    def _vec2u(value)
      v = C::System::Vector2u.new
      x, y = value.is_a?(Vector2) ? [value.x, value.y] : value
      v[:x] = Integer(x); v[:y] = Integer(y)
      v
    end
  end
end
