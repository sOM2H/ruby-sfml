RSpec.describe SFML::Sound do
  let(:buffer) { SFML::SoundBuffer.load(File.expand_path("../../../../examples/assets/blip.wav", __FILE__)) }

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
