module SFML
  # Mobile-platform inertial / environment sensors. SFML treats every
  # device the same way: identify the sensor by symbol, ask if it's
  # available, enable it before reading, then poll a Vector3 value
  # whose components depend on the sensor type (e.g. acceleration in
  # m/s² for `:accelerometer`, angular velocity in deg/s for
  # `:gyroscope`, magnetic field in µT for `:magnetometer`).
  #
  #   if SFML::Sensor.available?(:accelerometer)
  #     SFML::Sensor.enable(:accelerometer)
  #     gravity = SFML::Sensor.value(:accelerometer)
  #   end
  #
  # On desktop platforms without sensor hardware, `available?` returns
  # `false` and `value` returns the zero vector — calls don't raise.
  #
  # Sensor data also surfaces through the event loop as
  # `{type: :sensor_changed, sensor: :accelerometer, value: Vector3}`.
  module Sensor
    TYPES       = C::Window::SENSOR_TYPES
    TYPE_INDEX  = TYPES.each_with_index.to_h.freeze

    module_function

    def available?(type)
      C::Window.sfSensor_isAvailable(_index(type))
    end

    def enable(type)
      C::Window.sfSensor_setEnabled(_index(type), true)
    end

    def disable(type)
      C::Window.sfSensor_setEnabled(_index(type), false)
    end

    def value(type)
      v = C::Window.sfSensor_getValue(_index(type))
      Vector3.new(v[:x], v[:y], v[:z])
    end

    # @!visibility private
    def _index(type)
      TYPE_INDEX.fetch(type) do
        raise ArgumentError, "Unknown sensor type: #{type.inspect} " \
                             "(expected one of #{TYPES.inspect})"
      end
    end
  end
end
