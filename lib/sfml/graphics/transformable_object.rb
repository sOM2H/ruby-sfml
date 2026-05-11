module SFML
  # Standalone transformable — a pure CSFML transform container (no
  # geometry attached). Useful as a base for custom drawables that
  # combine a transform with their own rendering: parent the child's
  # vertices to this object's `#transform` and you get position /
  # rotation / scale / origin for free.
  #
  # Most users want the `Graphics::Transformable` mixin instead — this
  # standalone class exists for symmetry with the C++ API.
  #
  #   t = SFML::TransformableObject.new(position: [400, 300], rotation: 45)
  #   t.transform   #=> SFML::C::Graphics::Transform (use via RenderStates)
  class TransformableObject
    include Graphics::Transformable
    CSFML_PREFIX = :sfTransformable

    def initialize(**opts)
      ptr = C::Graphics.sfTransformable_create
      raise Error, "sfTransformable_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Graphics.method(:sfTransformable_destroy))

      self.position = opts[:position] if opts.key?(:position)
      self.origin   = opts[:origin]   if opts.key?(:origin)
      self.rotation = opts[:rotation] if opts.key?(:rotation)
      self.scale    = opts[:scale]    if opts.key?(:scale)
    end

    def transform
      C::Graphics.sfTransformable_getTransform(@handle)
    end

    def inverse_transform
      C::Graphics.sfTransformable_getInverseTransform(@handle)
    end

    def dup
      ptr = C::Graphics.sfTransformable_copy(@handle)
      raise Error, "sfTransformable_copy returned NULL" if ptr.null?
      copy = self.class.allocate
      copy.instance_variable_set(:@handle,
        FFI::AutoPointer.new(ptr, C::Graphics.method(:sfTransformable_destroy)))
      copy
    end
    alias clone dup

    attr_reader :handle # :nodoc:
  end
end
