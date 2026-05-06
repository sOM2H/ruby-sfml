RSpec.describe SFML::Assets do
  let(:assets_dir)        { File.expand_path("../../examples/assets",       __dir__) }
  let(:bundled_fonts_dir) { File.expand_path("../../lib/sfml/assets/fonts", __dir__) }

  before do
    # Include both the example asset dir (for blip.wav) and our bundled
    # fonts dir (for DejaVuSans.ttf) so these specs don't depend on what
    # the host system happens to have installed.
    described_class.search_paths = [assets_dir, bundled_fonts_dir]
    described_class.clear
  end

  describe ".sound" do
    it "loads blip.wav and caches the buffer" do
      a = described_class.sound("blip")
      b = described_class.sound("blip")
      expect(a).to be_a(SFML::SoundBuffer)
      expect(a).to be(b) # cached: same object identity
    end

    it "raises NotFound when the file is missing" do
      expect { described_class.sound("nope") }
        .to raise_error(SFML::Assets::NotFound, /Sound "nope" not found/)
    end
  end

  describe ".font" do
    it "loads a font from a configured search path" do
      font = described_class.font("DejaVuSans")
      expect(font).to be_a(SFML::Font)
    end

    it "caches font results across calls" do
      a = described_class.font("DejaVuSans")
      b = described_class.font("DejaVuSans")
      expect(a).to be(b)
    end

    it "falls back to system fonts via Font.find when not in search paths" do
      described_class.search_paths = ["/tmp/definitely-not-a-real-asset-dir"]
      described_class.clear
      # Stub Font.find so the system layout doesn't matter.
      stub = SFML::Font.default
      allow(SFML::Font).to receive(:find).with("DejaVuSans").and_return(stub)
      expect(described_class.font("DejaVuSans")).to be(stub)
    end
  end

  describe ".texture" do
    it "raises NotFound for non-existent textures" do
      expect { described_class.texture("nope") }
        .to raise_error(SFML::Assets::NotFound, /Texture "nope" not found/)
    end
  end

  describe ".clear" do
    it "evicts cached entries so the next load reads from disk again" do
      a = described_class.sound("blip")
      described_class.clear
      b = described_class.sound("blip")
      expect(a).not_to be(b)
    end
  end

  describe ".add_search_path" do
    it "appends without duplicates" do
      described_class.search_paths = ["/tmp"]
      described_class.add_search_path("/tmp")
      described_class.add_search_path("/var")
      expect(described_class.search_paths).to eq(["/tmp", "/var"])
    end
  end
end
