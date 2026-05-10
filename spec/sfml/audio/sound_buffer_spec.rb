RSpec.describe SFML::SoundBuffer do
  let(:fixture) { File.expand_path("../../../fixtures/blip.wav", __FILE__) }

  describe ".load + introspection" do
    it "round-trips duration / sample_rate / channel_count from a WAV" do
      buffer = described_class.load(fixture)
      expect(buffer.duration.as_microseconds).to be > 0
      expect(buffer.sample_rate).to eq(44100)
      expect(buffer.channel_count).to eq(1)
    end
  end

  describe ".from_memory" do
    it "decodes a WAV from a Ruby String of bytes" do
      bytes = File.binread(fixture)
      buffer = described_class.from_memory(bytes)
      expect(buffer.duration.as_microseconds).to be > 0
    end

    it "raises on garbage bytes" do
      expect { described_class.from_memory("not audio") }.to raise_error(SFML::Error)
    end
  end

  describe ".from_samples" do
    it "builds a mono buffer from raw int16 samples" do
      samples = (0...44100).map { |i| (Math.sin(i * 0.1) * 10_000).to_i }
      buffer  = described_class.from_samples(samples, sample_rate: 44100, channel_count: 1)
      expect(buffer.sample_rate).to   eq(44100)
      expect(buffer.channel_count).to eq(1)
      expect(buffer.sample_count).to  eq(44100)
    end

    it "builds a stereo buffer from raw int16 samples" do
      samples = ([0] * 88_200)   # 1s of stereo silence
      buffer  = described_class.from_samples(samples, sample_rate: 44100, channel_count: 2)
      expect(buffer.channel_count).to eq(2)
    end

    it "raises if no default channel-map exists for the channel count" do
      samples = ([0] * 1000)
      expect {
        described_class.from_samples(samples, sample_rate: 44100, channel_count: 5)
      }.to raise_error(ArgumentError, /no default channel_map/)
    end
  end

  describe "#sample_count + #samples" do
    it "round-trips raw samples through dup" do
      original = described_class.from_samples([100, -200, 300, -400],
                                              sample_rate: 8000, channel_count: 1)
      expect(original.sample_count).to eq(4)
      expect(original.samples).to eq([100, -200, 300, -400])
    end
  end

  describe "#dup" do
    it "produces an independent buffer with the same waveform" do
      a = described_class.load(fixture)
      b = a.dup
      expect(b).to be_a(described_class)
      expect(b.handle).not_to eq(a.handle)
      expect(b.sample_count).to eq(a.sample_count)
    end
  end
end
