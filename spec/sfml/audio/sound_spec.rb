RSpec.describe SFML::Sound do
  let(:buffer) { SFML::SoundBuffer.load(File.expand_path("../../../fixtures/blip.wav", __FILE__)) }

  it "starts in :stopped state" do
    sound = described_class.new(buffer, volume: 0)
    expect(sound.status).to eq(:stopped)
    expect(sound).to be_stopped
  end

  it "transitions through states with play/stop" do
    sound = described_class.new(buffer, volume: 0)
    sound.play
    expect(sound).to be_playing
    sound.stop
    expect(sound).to be_stopped
  end

  it "applies volume / pitch / looping at construction" do
    sound = described_class.new(buffer, volume: 50, pitch: 1.5, looping: true)
    expect(sound.volume).to eq(50.0)
    expect(sound.pitch).to eq(1.5)
    expect(sound.looping?).to be true
  end

  describe "3D positional audio" do
    let(:sound) { described_class.new(buffer, volume: 0) }

    it "round-trips position as Vector3 (Array form)" do
      sound.position = [10, 20, 30]
      expect(sound.position).to eq(SFML::Vector3[10, 20, 30])
    end

    it "round-trips position as Vector3 instance" do
      sound.position = SFML::Vector3[1.5, 2.5, -3.0]
      expect(sound.position).to eq(SFML::Vector3[1.5, 2.5, -3.0])
    end

    it "exposes attenuation + min_distance" do
      sound.attenuation = 1.5
      sound.min_distance = 25
      expect(sound.attenuation).to eq(1.5)
      expect(sound.min_distance).to eq(25.0)
    end

    it "toggles relative_to_listener" do
      expect(sound.relative_to_listener?).to be false
      sound.relative_to_listener = true
      expect(sound.relative_to_listener?).to be true
    end
  end

  describe "#playing_offset=" do
    let(:sound) { described_class.new(buffer, volume: 0) }

    it "accepts a SFML::Time and reads back the same value" do
      sound.playing_offset = SFML::Time.milliseconds(40)
      expect(sound.playing_offset.as_milliseconds).to be_within(2).of(40)
    end

    it "accepts a numeric (seconds) shortcut" do
      sound.playing_offset = 0.05
      expect(sound.playing_offset.as_milliseconds).to be_within(2).of(50)
    end

    it "starts at offset 0 on a fresh Sound" do
      expect(sound.playing_offset.as_microseconds).to eq(0)
    end
  end

  describe SFML::SoundBuffer do
    it "exposes duration / sample_rate / channel_count" do
      expect(buffer.duration.as_milliseconds).to eq(80)
      expect(buffer.sample_rate).to eq(44100)
      expect(buffer.channel_count).to eq(1)
    end

    it "raises on missing file" do
      expect { SFML::SoundBuffer.load("/nope/missing.wav") }
        .to raise_error(SFML::Error, /Could not load sound buffer/)
    end
  end
end
