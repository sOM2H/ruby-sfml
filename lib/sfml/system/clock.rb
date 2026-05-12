module SFML
  # Monotonic high-resolution timer. Wraps sfClock from CSFML.
  #
  #   clock = SFML::Clock.new
  #   # ... do work ...
  #   puts clock.elapsed_time.as_seconds
  #   clock.restart  # returns the elapsed time and resets to zero
  class Clock
    def initialize
      ptr = C::System.sfClock_create
      raise Error, "sfClock_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::System.method(:sfClock_destroy))
    end

    def elapsed_time
      Time.from_native(C::System.sfClock_getElapsedTime(@handle))
    end
    alias elapsed elapsed_time

    # `true` if running.
    def running?
      C::System.sfClock_isRunning(@handle)
    end

    def start
      C::System.sfClock_start(@handle)
      self
    end

    def stop
      C::System.sfClock_stop(@handle)
      self
    end

    def restart
      Time.from_native(C::System.sfClock_restart(@handle))
    end

    def reset
      Time.from_native(C::System.sfClock_reset(@handle))
    end

    attr_reader :handle # :nodoc:
  end
end
