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

    it "starts at offset 0" do
      expect(music.playing_offset.as_microseconds).to eq(0)
    end

    it "accepts a SFML::Time and reads back the same value" do
      music.playing_offset = SFML::Time.milliseconds(20)
      expect(music.playing_offset.as_milliseconds).to be_within(2).of(20)
    end

    it "accepts a numeric (seconds) shortcut" do
      music.playing_offset = 0.03
      expect(music.playing_offset.as_milliseconds).to be_within(2).of(30)
    end
  end
end
