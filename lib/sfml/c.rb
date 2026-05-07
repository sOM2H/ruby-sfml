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
      network:  ["csfml-network",  "libcsfml-network.so.3.0",  "libcsfml-network.3.0.0.dylib"],
    }.freeze
  end
end

# Version probe — runs before any binding modules attach their full
# function tables. We try to attach a single CSFML 3.0+ symbol; if it's
# missing the linked libcsfml is older (e.g. Ubuntu 22.04 / 24.04 ship
# CSFML 2.5 in their repos). Trip a clear SFML::LoadError now rather
# than letting users hit a cryptic FFI::NotFoundError mid-attach when
# they `require "sfml"` for the first time.
begin
  probe = Module.new
  probe.extend FFI::Library
  probe.ffi_lib SFML::C::LIB_CANDIDATES[:system]
  # sfClock_isRunning is part of the SFML 3.0 sf::Clock rewrite — not
  # present in any 2.x release. Cheap and dependency-free to probe.
  probe.attach_function :sfClock_isRunning, [:pointer], :bool
rescue FFI::NotFoundError
  raise SFML::LoadError, <<~MSG.chomp

    ============================================================================
    ruby-sfml requires CSFML #{SFML::CSFML_VERSION} or compatible.

    The libcsfml-system on your system is older than 3.0 — it's missing
    'sfClock_isRunning', which was added in the SFML 3.0 / CSFML 3.0
    release (March 2025).

    Fix:
      Ubuntu 25.04+ / Debian:  sudo apt install libcsfml-dev
      Ubuntu 22.04 / 24.04:    repo is too old, build from source:
                                 https://github.com/SFML/CSFML/releases/tag/3.0.0
      macOS (brew):            brew upgrade csfml
      Arch Linux:              sudo pacman -S csfml
      Windows:                 https://www.sfml-dev.org/download/csfml/

    See also: https://github.com/SFML/CSFML/releases for the latest 3.x.
    ============================================================================
  MSG
end

require "sfml/c/system"
require "sfml/c/window"
require "sfml/c/graphics"
require "sfml/c/audio"
require "sfml/c/network"
