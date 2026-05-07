require "mkmf"

# This is not a real native extension. We use the extconf.rb hook only as a
# pre-flight check: if CSFML 3.x is not on the system, fail `gem install` here
# with a clear message instead of letting the user discover the problem at
# runtime.

REQUIRED_LIBS = %w[csfml-system csfml-window csfml-graphics csfml-audio csfml-network]

missing = REQUIRED_LIBS.reject { |lib| have_library(lib) }

unless missing.empty?
  abort <<~MSG

    ============================================================================
    ruby-sfml requires CSFML 3.x to be installed on your system.

    Missing libraries: #{missing.join(', ')}

    Install CSFML, then re-run `gem install ruby-sfml`:

        Ubuntu / Debian:  sudo apt install libcsfml-dev
        macOS (brew):     brew install csfml
        Arch Linux:       sudo pacman -S csfml
        Windows:          https://www.sfml-dev.org/download/csfml/

    See https://github.com/m1kh41l/ruby-sfml#requirements for full instructions.
    ============================================================================

  MSG
end

# All libcsfml-* are present, but they might be 2.x (Ubuntu 22.04 / 24.04
# ship 2.5 in their repos). Probe a CSFML 3.0+ symbol — sfClock_isRunning
# is part of the SFML 3 sf::Clock rewrite and isn't in any 2.x release.
unless have_func("sfClock_isRunning")
  abort <<~MSG

    ============================================================================
    ruby-sfml requires CSFML 3.0 or newer.

    The libcsfml on your system is older than 3.0 — sfClock_isRunning,
    introduced in the SFML 3.0 / CSFML 3.0 release (March 2025), is not
    exported by the linked library.

    Upgrade options:

        Ubuntu 25.04+ / Debian:  sudo apt install libcsfml-dev
        Ubuntu 22.04 / 24.04:    repo is too old; build from source:
                                   https://github.com/SFML/CSFML/releases/tag/3.0.0
        macOS (brew):            brew upgrade csfml
        Arch Linux:              sudo pacman -S csfml

    Or grab a prebuilt 3.x release from
    https://github.com/SFML/CSFML/releases.
    ============================================================================

  MSG
end

# Emit a no-op Makefile so RubyGems considers the extension "built".
File.write("Makefile", <<~MAKE)
  all:
  \t@true
  install:
  \t@true
  clean:
  \t@true
MAKE
