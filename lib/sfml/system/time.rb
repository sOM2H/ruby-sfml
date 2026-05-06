module SFML
  # Represents a time value. Stored internally as microseconds (int64), same
  # as sfTime in CSFML. Immutable and comparable.
  #
  #   SFML::Time.seconds(1.5)        #=> 1_500_000 µs
  #   SFML::Time.milliseconds(500)
  #   SFML::Time.microseconds(42)
  #   SFML::Time.zero
  class Time
    include Comparable

    attr_reader :microseconds

    def self.seconds(value)      = new((value * 1_000_000).to_i)
    def self.milliseconds(value) = new(Integer(value) * 1_000)
    def self.microseconds(value) = new(Integer(value))
    def self.zero                = new(0)

    def initialize(microseconds)
      @microseconds = Integer(microseconds)
      freeze
    end

    def as_seconds      = @microseconds / 1_000_000.0
    def as_milliseconds = @microseconds / 1_000
    def as_microseconds = @microseconds

    def +(other) = Time.new(@microseconds + other.microseconds)
    def -(other) = Time.new(@microseconds - other.microseconds)
    def -@       = Time.new(-@microseconds)
    def <=>(other) = @microseconds <=> other.microseconds

    def hash = @microseconds.hash
    def eql?(other) = other.is_a?(Time) && @microseconds == other.microseconds
    alias == eql?

    def to_s = "#<SFML::Time #{as_seconds}s>"
    alias inspect to_s

    def self.from_native(struct) # :nodoc:
      new(struct[:microseconds])
    end

    def to_native # :nodoc:
      C::System::Time.new.tap { |t| t[:microseconds] = @microseconds }
    end
  end
end
