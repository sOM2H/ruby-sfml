require "ffi"

module SFML
  # Low-level FFI bindings to CSFML 3.x. One module per CSFML library.
  #
  # End users should not call into here directly. The high-level Ruby classes
  # (SFML::Vector2, SFML::Clock, SFML::RenderWindow, ...) wrap these. This
  # layer exists to be replaceable: when CSFML ships a new minor version, only
  # the files under SFML::C should need to move.
  module C
    # Library name candidates per CSFML module. Each value is an Array passed
    # as a single argument to ffi_lib — FFI then tries the names in order and
    # uses the first one it can dlopen. (Splatting would tell FFI to load all
    # of them at once, not as alternatives.)
    #
    # The bare name ("csfml-system") is what FFI auto-decorates per platform:
    #   Linux   → libcsfml-system.so
    #   macOS   → libcsfml-system.dylib
    #   Windows → csfml-system.dll
    # The remaining entries are explicit fallbacks for systems where the
    # unversioned symlink is missing (e.g. runtime-only installs without -dev).
    LIB_CANDIDATES = {
      system:   ["csfml-system",   "libcsfml-system.so.3.0",   "libcsfml-system.3.0.0.dylib"],
      window:   ["csfml-window",   "libcsfml-window.so.3.0",   "libcsfml-window.3.0.0.dylib"],
      graphics: ["csfml-graphics", "libcsfml-graphics.so.3.0", "libcsfml-graphics.3.0.0.dylib"],
      audio:    ["csfml-audio",    "libcsfml-audio.so.3.0",    "libcsfml-audio.3.0.0.dylib"],
    }.freeze
  end
end

require "sfml/c/system"
require "sfml/c/window"
require "sfml/c/graphics"
require "sfml/c/audio"
