require "mkmf"

# This is not a real native extension. We use the extconf.rb hook only as a
# pre-flight check: if CSFML 3.x is not on the system, fail `gem install` here
# with a clear message instead of letting the user discover the problem at
# runtime.

REQUIRED_LIBS = %w[csfml-system csfml-window csfml-graphics csfml-audio]

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

# Emit a no-op Makefile so RubyGems considers the extension "built".
File.write("Makefile", <<~MAKE)
  all:
  \t@true
  install:
  \t@true
  clean:
  \t@true
MAKE
