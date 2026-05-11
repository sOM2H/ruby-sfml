module SFML
  # Headless OpenGL context — for compiling shaders, generating
  # textures, or doing GL work without a window. SFML attaches the
  # context to whichever thread constructed it.
  #
  #   ctx = SFML::Context.new
  #   ctx.active = true
  #   # … raw GL work / shader compile …
  #   ctx.active = false
  #
  # CSFML always returns a non-NULL context on creation (it falls back
  # to a pbuffer / EGL surface if no display is available), so the
  # constructor doesn't raise.
  class Context
    def initialize
      ptr = C::Window.sfContext_create
      raise Error, "sfContext_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::Window.method(:sfContext_destroy))
    end

    # Activate / deactivate this context on the current thread. Only
    # one context can be current per thread; setting another active
    # implicitly deactivates this one.
    def active=(value)
      C::Window.sfContext_setActive(@handle, !!value)
    end

    # The settings the GL driver actually granted (might differ from
    # what you asked for if the driver couldn't meet every
    # constraint).
    def settings
      ContextSettings.from_native(C::Window.sfContext_getSettings(@handle))
    end

    # ID of the context currently active on this thread, or 0 if
    # none. Useful for "am I in the GL context I expect?" assertions.
    def self.active_context_id
      C::Window.sfContext_getActiveContextId
    end

    # Is `extension_name` (e.g. "GL_ARB_compute_shader") supported by
    # the active context?
    def self.extension_available?(extension_name)
      C::Window.sfContext_isExtensionAvailable(extension_name.to_s)
    end

    # Look up a raw GL function pointer by name. Useful when
    # interoping with a GL extension that SFML doesn't wrap. Returns
    # an FFI::Pointer (nil pointer if the function isn't loaded).
    def self.gl_function(name)
      C::Window.sfContext_getFunction(name.to_s)
    end

    attr_reader :handle # :nodoc:
  end
end
