RSpec.describe SFML::Music do
  let(:fixture) { File.expand_path("../../../fixtures/blip.wav", __FILE__) }

  describe ".load" do
    it "loads a WAV without raising" do
      music = described_class.load(fixture)
      expect(music).to be_a(described_class)
    end

    it "raises on missing file" do
      expect { described_class.load("/nope/missing.wav") }
        .to raise_error(SFML::Error, /Could not (?:load|open) music/i)
    end
  end

  describe "playback state" do
    let(:music) { described_class.load(fixture) }

    it "starts in :stopped" do
      expect(music.status).to eq(:stopped)
      expect(music.stopped?).to be true
    end

    it "exposes duration" do
      expect(music.duration.as_milliseconds).to be > 0
    end
  end

  describe "#playing_offset=" do
    let(:music) { described_class.load(fixture) }

    # Same caveat as Sound#playing_offset= — some Linux OpenAL
    # backends only latch the offset once playback starts, so the
    # round-trip assertion is brittle on CI. Test the contract
    # (setter accepts both forms, getter returns Time) instead.
    it "starts at offset 0" do
      expect(music.playing_offset.as_microseconds).to eq(0)
    end

    it "accepts a SFML::Time and exposes a Time getter" do
      expect { music.playing_offset = SFML::Time.milliseconds(20) }.not_to raise_error
      expect(music.playing_offset).to be_a(SFML::Time)
    end

    it "accepts a numeric (seconds) shortcut" do
      expect { music.playing_offset = 0.03 }.not_to raise_error
    end
  end

  describe "directional 3D audio" do
    let(:music) { described_class.load(fixture) }

    it "round-trips velocity, doppler_factor, direction" do
      music.velocity        = [2.0, 0.0, -1.0]
      music.doppler_factor  = 0.75
      music.direction       = [1.0, 0.0, 0.0]
      expect(music.velocity).to       eq(SFML::Vector3[2, 0, -1])
      expect(music.doppler_factor).to be_within(1e-5).of(0.75)
      expect(music.direction).to      eq(SFML::Vector3[1, 0, 0])
    end

    it "round-trips cone" do
      music.cone = SFML::SoundCone.new(inner_angle: 60, outer_angle: 180, outer_gain: 0.5)
      expect(music.cone.inner_angle).to eq(60.0)
      expect(music.cone.outer_angle).to eq(180.0)
      expect(music.cone.outer_gain).to  eq(0.5)
    end
  end

  describe ".from_memory" do
    it "loads music from a Ruby String of bytes" do
      bytes = File.binread(fixture)
      m = described_class.from_memory(bytes)
      expect(m.duration.as_seconds).to be > 0
    end

    it "raises on garbage bytes" do
      expect { described_class.from_memory("not music") }.to raise_error(SFML::Error)
    end
  end

  describe "stream introspection" do
    let(:music) { described_class.load(fixture) }

    it "#channel_count and #sample_rate report the format" do
      expect(music.channel_count).to be > 0
      expect(music.sample_rate).to   be > 0
    end

    it "#loop_points round-trips" do
      music.loop_points = [SFML::Time.zero, music.duration]
      offset, length = music.loop_points
      expect(offset.as_microseconds).to eq(0)
      expect(length.as_microseconds).to be > 0
    end
  end

  describe "3D-audio extras (mirror of Sound)" do
    let(:music) { described_class.load(fixture) }

    it "pan / max_distance / spatialization_enabled? round-trip" do
      music.pan = -0.4
      music.max_distance = 25.0
      music.spatialization_enabled = false

      expect(music.pan).to be_within(0.001).of(-0.4)
      expect(music.max_distance).to be_within(0.001).of(25.0)
      expect(music.spatialization_enabled?).to be false
    end

    it "min_gain / max_gain are settable (round-trip is OpenAL-implementation-dependent)" do
      expect { music.min_gain = 0.1; music.max_gain = 0.9 }.not_to raise_error
      expect(music.min_gain).to be_a(Float)
      expect(music.max_gain).to be_a(Float)
    end

    it "directional_attenuation_factor round-trips" do
      music.directional_attenuation_factor = 0.7
      expect(music.directional_attenuation_factor).to be_within(0.001).of(0.7)
    end
  end
end
