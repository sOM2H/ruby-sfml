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

    it "default_device, if exposed, is one of the listed devices" do
      # Some CI / headless configurations expose only an OpenAL "null"
      # sink and report no default device. Skip rather than fail there.
      default = described_class.default_device
      skip "no default device on this host" if default.nil? || default.empty?
      expect(described_class.devices).to include(default)
    end
  end

  describe "callback-based subclassing" do
    before { skip "no input device on this host" unless described_class.available? }

    let(:level_meter_class) do
      Class.new(described_class) do
        attr_reader :peak

        def on_start
          @peak = 0
          true
        end

        def on_process_samples(samples, _channels)
          @peak = [@peak, *samples.map(&:abs)].max
          true
        end
      end
    end

    it "channel_count defaults to 1 and is settable before start" do
      rec = level_meter_class.new
      expect(rec.channel_count).to eq(1)
      rec.channel_count = 2
      expect(rec.channel_count).to eq(2)
    end

    it "fires on_start / on_process_samples once started" do
      rec = level_meter_class.new
      rec.start(sample_rate: 44_100)
      sleep 0.05
      rec.stop
      # peak may be 0 on a silent input — just confirm callback ran
      expect(rec.peak).to be_a(Integer)
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
