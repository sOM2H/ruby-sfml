module SFML
  # The "ear" — a global, single-instance object that defines from
  # where the player hears the world. Sounds positioned via Sound#position=
  # attenuate based on their distance from this point.
  #
  #   SFML::Listener.position = [400, 300, 0]   # follow your camera
  #   SFML::Listener.global_volume = 80         # 0..100, master gain
  #
  # For 2D games keep z = 0 and treat x, y as world coords. For
  # first-person stuff also set Listener.direction to point along the
  # camera forward.
  module Listener
    module_function

    # Master volume in the range [0, 100]. Affects all sounds, music, etc.
    def global_volume
      C::Audio.sfListener_getGlobalVolume
    end

    def global_volume=(value)
      C::Audio.sfListener_setGlobalVolume(value.to_f)
    end

    def position
      Vector3.from_native(C::Audio.sfListener_getPosition)
    end

    def position=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      C::Audio.sfListener_setPosition(vec.to_native_f)
    end

    # The forward direction of the listener (unit-length, doesn't have to be).
    # Default: (0, 0, -1) — looking into the screen.
    def direction
      Vector3.from_native(C::Audio.sfListener_getDirection)
    end

    def direction=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      C::Audio.sfListener_setDirection(vec.to_native_f)
    end

    # The "up" direction. Default: (0, 1, 0). Together with `direction`
    # it determines listener orientation for stereo panning.
    def up_vector
      Vector3.from_native(C::Audio.sfListener_getUpVector)
    end

    def up_vector=(value)
      vec = value.is_a?(Vector3) ? value : Vector3.new(*value)
      C::Audio.sfListener_setUpVector(vec.to_native_f)
    end
  end
end
