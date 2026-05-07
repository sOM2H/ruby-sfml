RSpec.describe SFML::SoundStream do
  # A trivial subclass that returns a fixed pulse pattern. Counts how
  # many times the audio thread asked for data so we can assert the
  # callback actually fires.
  class PulseStream < SFML::SoundStream
    attr_reader :get_data_calls, :seek_calls

    def initialize
      super(channel_count: 1, sample_rate: 22_050)
      @get_data_calls = 0
      @seek_calls     = 0
    end

    def on_get_data
      @get_data_calls += 1
      Array.new(2205) { |i| (i.even? ? 8000 : -8000) }
    end

    def on_seek(_time)
      @seek_calls += 1
    end
  end

  describe ".new" do
    it "constructs without raising and reports channel_count + sample_rate" do
      stream = PulseStream.new
      expect(stream.channel_count).to eq(1)
      expect(stream.sample_rate).to eq(22_050)
      expect(stream.status).to eq(:stopped)
    end

    it "rejects zero channels" do
      expect {
        Class.new(described_class) do
          def on_get_data; nil; end
        end.new(channel_count: 0, sample_rate: 22_050)
      }.to raise_error(ArgumentError, /channel_count/)
    end
  end

  describe "subclass contract" do
    it "raises if #on_get_data isn't overridden" do
      bad = Class.new(described_class).new(channel_count: 1, sample_rate: 22_050)
      expect { bad.send(:on_get_data) }.to raise_error(NoMethodError, /must override/)
    end
  end

  describe "playback" do
    # Whether the audio thread actually pulls samples is up to the
    # OpenAL backend — the headless null sink on Linux CI doesn't,
    # so we can only assert that play/stop don't crash.
    it "play and stop don't raise" do
      stream = PulseStream.new
      stream.volume = 0
      stream.play
      sleep 0.05
      stream.stop
    end
  end

  describe "#playing_offset=" do
    it "doesn't raise" do
      stream = PulseStream.new
      expect { stream.playing_offset = SFML::Time.milliseconds(50) }.not_to raise_error
    end
  end

  describe "scalar getters / setters" do
    let(:stream) { PulseStream.new }

    it "round-trips volume" do
      stream.volume = 25.0
      expect(stream.volume).to eq(25.0)
    end

    it "round-trips pitch" do
      stream.pitch = 1.5
      expect(stream.pitch).to eq(1.5)
    end

    it "round-trips looping" do
      expect(stream.looping?).to be false
      stream.looping = true
      expect(stream.looping?).to be true
    end

    it "round-trips position as Vector3" do
      stream.position = [1.5, -2.0, 3.25]
      expect(stream.position).to eq(SFML::Vector3[1.5, -2.0, 3.25])
    end
  end
end
