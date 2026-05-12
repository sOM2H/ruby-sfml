module SFML
  # Directional-attenuation cone for a 3D sound source. Inside the
  # `inner_angle` cone the sound plays at full volume; outside the
  # `outer_angle` cone it's attenuated by `outer_gain`; between the
  # two it's smoothly interpolated.
  #
  # Angles are in degrees, measured from the source's `direction`
  # axis. `outer_gain` is a scalar in [0, 1] (0 = silent outside).
  #
  #   sound.direction = [0, 0, -1]
  #   sound.cone = SFML::SoundCone.new(
  #     inner_angle: 30, outer_angle: 90, outer_gain: 0.2,
  #   )
  class SoundCone
    attr_reader :inner_angle, :outer_angle, :outer_gain

    def initialize(inner_angle:, outer_angle:, outer_gain:)
      @inner_angle = inner_angle.to_f
      @outer_angle = outer_angle.to_f
      @outer_gain  = outer_gain.to_f
      freeze
    end

    def ==(other)
      other.is_a?(SoundCone) &&
        inner_angle == other.inner_angle &&
        outer_angle == other.outer_angle &&
        outer_gain  == other.outer_gain
    end
    alias eql? ==
    # Returns the hash.
    def hash = [inner_angle, outer_angle, outer_gain].hash

    def to_s
      "SoundCone(inner=#{inner_angle}°, outer=#{outer_angle}°, outer_gain=#{outer_gain})"
    end
    alias inspect to_s

    # @!visibility private
    def to_native
      s = C::Audio::SoundSourceCone.new
      s[:inner_angle] = @inner_angle
      s[:outer_angle] = @outer_angle
      s[:outer_gain]  = @outer_gain
      s
    end

    # @!visibility private
    def self.from_native(struct)
      new(
        inner_angle: struct[:inner_angle],
        outer_angle: struct[:outer_angle],
        outer_gain:  struct[:outer_gain],
      )
    end
  end
end
