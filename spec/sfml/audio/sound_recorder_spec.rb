RSpec.describe SFML::SoundRecorder do
  describe ".available?" do
    it "returns a boolean" do
      expect([true, false]).to include(described_class.available?)
    end
  end

  describe ".devices + .default_device" do
    before { skip "no input device on this host" unless described_class.available? }

    it "lists at least one input device when one is available" do
      expect(described_class.devices).not_to be_empty
      expect(described_class.devices).to all(be_a(String))
    end

    it "default_device is one of the listed devices" do
      expect(described_class.devices).to include(described_class.default_device)
    end
  end
end

RSpec.describe SFML::SoundBufferRecorder do
  before { skip "no input device on this host" unless SFML::SoundRecorder.available? }

  it "creates without raising" do
    expect(described_class.new).to be_a(described_class)
  end

  it "exposes default sample rate before start" do
    rec = described_class.new
    expect(rec.sample_rate).to be_a(Integer)
  end

  describe "#start / #stop / #buffer round-trip" do
    it "captures into a SoundBuffer that's non-zero duration after stop" do
      rec = described_class.new
      ok  = rec.start(sample_rate: 44_100)
      next unless ok # the runner may not allow real device access

      sleep 0.2
      rec.stop

      buf = rec.buffer
      expect(buf).to be_a(SFML::SoundBuffer)
      # Even a couple hundred ms should produce non-empty audio.
      expect(buf.duration.as_milliseconds).to be > 0
      expect(buf.sample_rate).to eq(44_100)
    end
  end

  it "reports the same sample_rate it was started with" do
    rec = described_class.new
    next unless rec.start(sample_rate: 22_050)
    sleep 0.05
    rec.stop
    expect(rec.sample_rate).to eq(22_050)
  end
end
