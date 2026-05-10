module SFML
  # A 2D image stored on the GPU. Used by Sprite (and shapes) to draw textured
  # geometry. Build one with .load:
  #
  #   tex = SFML::Texture.load("assets/hero.png")
  #   tex = SFML::Texture.load("assets/tile.png", smooth: true, repeated: true)
  class Texture
    def self.load(path, smooth: false, repeated: false)
      ptr = C::Graphics.sfTexture_createFromFile(path.to_s, nil)
      raise Error, "Could not load texture from #{path.inspect}" if ptr.null?

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
    def self.create(width, height)
      size = C::System::Vector2u.new
      size[:x] = Integer(width); size[:y] = Integer(height)
      ptr = C::Graphics.sfTexture_create(size)
      raise Error, "sfTexture_create returned NULL — out of GPU memory?" if ptr.null?

      tex = allocate
      tex.send(:_take_ownership, ptr)
      tex
    end

    # Upload a CPU-side SFML::Image to the GPU as a new Texture. Keeps
    # the RGBA byte order and dimensions of the source image.
    def self.from_image(image, smooth: false, repeated: false)
      raise ArgumentError, "Texture.from_image needs a SFML::Image" unless image.is_a?(Image)

      ptr = C::Graphics.sfTexture_createFromImage(image.handle, nil)
      raise Error, "sfTexture_createFromImage returned NULL" if ptr.null?

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
      raise Error, "sfTexture_copyToImage returned NULL" if ptr.null?
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
      raise Error, "sfTexture_copy returned NULL" if ptr.null?

      tex = self.class.allocate
      tex.send(:_take_ownership, ptr)
      tex
    end
    alias clone dup

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
  end
end
