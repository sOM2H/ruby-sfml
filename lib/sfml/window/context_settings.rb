module SFML
  # Configuration for the underlying OpenGL context that backs a
  # `Window` / `RenderWindow`. Passed at window-creation time to
  # request anti-aliasing, depth/stencil buffers, or a specific
  # OpenGL version.
  #
  #   settings = SFML::ContextSettings.new(antialiasing: 4)
  #   window   = SFML::RenderWindow.new(800, 600, "Smooth", context: settings)
  #
  # Or use the `RenderWindow.new` shortcut directly:
  #
  #   window = SFML::RenderWindow.new(800, 600, "Smooth", antialiasing: 4)
  #
  # Anti-aliasing is the most common knob — typical values are 0
  # (off), 2, 4, or 8. The driver picks the closest level it
  # actually supports; query `window.context_settings` after
  # creation to see what you got.
  class ContextSettings
    DEFAULT_DEPTH_BITS    = 0
    DEFAULT_STENCIL_BITS  = 0
    DEFAULT_AA_LEVEL      = 0
    DEFAULT_MAJOR_VERSION = 1
    DEFAULT_MINOR_VERSION = 1

    ATTRIBUTE_FLAGS = {
      default: C::Window::ContextAttribute::DEFAULT,
      core:    C::Window::ContextAttribute::CORE,
      debug:   C::Window::ContextAttribute::DEBUG,
    }.freeze

    # The depth bits, stencil bits, antialiasing components.
    attr_reader :depth_bits, :stencil_bits, :antialiasing,
                :major_version, :minor_version, :attribute_flags,
                :srgb_capable

    def initialize(depth_bits: DEFAULT_DEPTH_BITS,
                   stencil_bits: DEFAULT_STENCIL_BITS,
                   antialiasing: DEFAULT_AA_LEVEL,
                   major_version: DEFAULT_MAJOR_VERSION,
                   minor_version: DEFAULT_MINOR_VERSION,
                   attributes: :default,
                   srgb_capable: false)
      @depth_bits      = Integer(depth_bits)
      @stencil_bits    = Integer(stencil_bits)
      @antialiasing    = Integer(antialiasing)
      @major_version   = Integer(major_version)
      @minor_version   = Integer(minor_version)
      @attribute_flags = _attribute_mask(attributes)
      @srgb_capable    = !!srgb_capable
      freeze
    end

    # Build the matching CSFML struct on the heap. Returned struct
    # is owned by the caller (FFI::AutoPointer is *not* set — pass
    # by reference into a window-creation call and let it copy).
    def to_native
      s = C::Window::ContextSettings.new
      s[:depth_bits]          = @depth_bits
      s[:stencil_bits]        = @stencil_bits
      s[:anti_aliasing_level] = @antialiasing
      s[:major_version]       = @major_version
      s[:minor_version]       = @minor_version
      s[:attribute_flags]     = @attribute_flags
      s[:s_rgb_capable]       = @srgb_capable
      s
    end

    # Returns the self.
    def self.from_native(struct)
      attrs = ATTRIBUTE_FLAGS.find { |_, v| v == struct[:attribute_flags] }&.first || :default
      new(
        depth_bits:      struct[:depth_bits],
        stencil_bits:    struct[:stencil_bits],
        antialiasing:    struct[:anti_aliasing_level],
        major_version:   struct[:major_version],
        minor_version:   struct[:minor_version],
        attributes:      attrs,
        srgb_capable:    struct[:s_rgb_capable],
      )
    end

    def ==(other)
      other.is_a?(ContextSettings) &&
        depth_bits == other.depth_bits &&
        stencil_bits == other.stencil_bits &&
        antialiasing == other.antialiasing &&
        major_version == other.major_version &&
        minor_version == other.minor_version &&
        attribute_flags == other.attribute_flags &&
        srgb_capable == other.srgb_capable
    end
    alias eql? ==

    # Returns the hash.
    def hash = [@depth_bits, @stencil_bits, @antialiasing,
                @major_version, @minor_version, @attribute_flags,
                @srgb_capable].hash

    # Returns the to s.
    def to_s
      "ContextSettings(aa=#{@antialiasing}, depth=#{@depth_bits}, " \
        "stencil=#{@stencil_bits}, gl=#{@major_version}.#{@minor_version})"
    end
    alias inspect to_s

    private

    def _attribute_mask(attrs)
      case attrs
      when Integer       then attrs
      when Symbol        then ATTRIBUTE_FLAGS.fetch(attrs) do
        raise ArgumentError, "unknown attribute :#{attrs}; one of #{ATTRIBUTE_FLAGS.keys}"
      end
      when Array
        attrs.reduce(0) do |mask, name|
          mask | ATTRIBUTE_FLAGS.fetch(name) do
            raise ArgumentError, "unknown attribute :#{name}; one of #{ATTRIBUTE_FLAGS.keys}"
          end
        end
      else
        raise ArgumentError, "expected Symbol/Array/Integer, got #{attrs.class}"
      end
    end
  end
end
