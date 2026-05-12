module SFML
  # Represents a time value. Stored internally as microseconds (int64),
  # same as `sfTime` in CSFML. Immutable and Comparable, so two Times
  # can be `==` / `<` / `>` / sorted.
  #
  #   SFML::Time.seconds(1.5)        #=> 1_500_000 µs
  #   SFML::Time.milliseconds(500)
  #   SFML::Time.microseconds(42)
  #   SFML::Time.zero
  #
  #   t1 + t2                        # sum of two Times
  #   t.as_seconds                   # Float seconds
  class Time
    include Comparable

    # The microseconds.
    attr_reader :microseconds

    # Build a Time from a Float of seconds.
    def self.seconds(value)      = new((value * 1_000_000).to_i)
    # Build a Time from an Integer of milliseconds.
    def self.milliseconds(value) = new(Integer(value) * 1_000)
    # Build a Time directly from microseconds.
    def self.microseconds(value) = new(Integer(value))
    # The zero Time.
    def self.zero                = new(0)

    def initialize(microseconds)
      @microseconds = Integer(microseconds)
      freeze
    end

    # As Float seconds.
    def as_seconds      = @microseconds / 1_000_000.0
    # As Integer milliseconds (truncated).
    def as_milliseconds = @microseconds / 1_000
    # As Integer microseconds — the raw stored value.
    def as_microseconds = @microseconds

    # Sum of two Times — returns a fresh Time.
    def +(other) = Time.new(@microseconds + other.microseconds)
    # Difference between two Times.
    def -(other) = Time.new(@microseconds - other.microseconds)
    # Negate (useful when computing a "ago" offset).
    def -@       = Time.new(-@microseconds)

    # Compare two Times — implements `Comparable`, so `<`, `<=`, `>=`,
    # `>`, `clamp`, and `Array#sort` all work.
    def <=>(other) = @microseconds <=> other.microseconds

    # Hash key support — Times can be Hash keys / Set members.
    def hash = @microseconds.hash
    # Value equality.
    def eql?(other) = other.is_a?(Time) && @microseconds == other.microseconds
    alias == eql?

    # String representation for debugging.
    def to_s = "#<SFML::Time #{as_seconds}s>"
    alias inspect to_s

    # Returns the self.
    def self.from_native(struct) # :nodoc:
      new(struct[:microseconds])
    end

    # Returns the to native.
    def to_native # :nodoc:
      C::System::Time.new.tap { |t| t[:microseconds] = @microseconds }
    end
  end
end
