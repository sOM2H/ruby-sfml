module SFML
  # Monotonic high-resolution timer. Wraps sfClock from CSFML.
  #
  #   clock = SFML::Clock.new
  #   # ... do work ...
  #   puts clock.elapsed_time.as_seconds
  #   clock.restart  # returns the elapsed time and resets to zero
  class Clock
    # Create a fresh clock — starts running at zero.
    def initialize
      ptr = C::System.sfClock_create
      raise Error, "sfClock_create returned NULL" if ptr.null?
      @handle = FFI::AutoPointer.new(ptr, C::System.method(:sfClock_destroy))
    end

    # Time elapsed since the clock was last started / restarted, as a
    # `SFML::Time`. Aliased as `#elapsed`.
    def elapsed_time
      Time.from_native(C::System.sfClock_getElapsedTime(@handle))
    end
    alias elapsed elapsed_time

    # `true` if the clock is currently ticking (not paused via `#stop`).
    def running?
      C::System.sfClock_isRunning(@handle)
    end

    # Resume after `#stop`. No-op if already running.
    def start
      C::System.sfClock_start(@handle)
      self
    end

    # Pause the clock — `#elapsed_time` freezes until `#start`.
    def stop
      C::System.sfClock_stop(@handle)
      self
    end

    # Atomic "read elapsed + reset to zero". Standard pattern for
    # per-frame dt: `dt = clock.restart`.
    def restart
      Time.from_native(C::System.sfClock_restart(@handle))
    end

    # Reset to zero without affecting the running state. Returns the
    # elapsed time before the reset.
    def reset
      Time.from_native(C::System.sfClock_reset(@handle))
    end

    attr_reader :handle # :nodoc:
  end
end
