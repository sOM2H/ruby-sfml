RSpec.describe SFML::InputStream do
  it "wraps a Ruby File so Font.from_stream can load from it" do
    File.open(File.expand_path("../../fixtures/DejaVuSans.ttf", __dir__), "rb") do |io|
      expect(SFML::Font.from_stream(io)).to be_a(SFML::Font)
    end
  end

  it "wraps a StringIO" do
    bytes = File.binread(File.expand_path("../../fixtures/blip.wav", __dir__))
    sio   = StringIO.new(bytes)
    expect(SFML::SoundBuffer.from_stream(sio)).to be_a(SFML::SoundBuffer)
  end

  it "raises through CSFML on garbage bytes" do
    expect { SFML::Image.from_stream(StringIO.new("not an image")) }
      .to raise_error(SFML::Error)
  end

  it "Music.from_stream keeps the IO and stream pinned" do
    File.open(File.expand_path("../../fixtures/blip.wav", __dir__), "rb") do |io|
      m = SFML::Music.from_stream(io)
      GC.start
      expect(m.sample_rate).to be > 0
    end
  end
end
