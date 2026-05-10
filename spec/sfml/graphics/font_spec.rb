RSpec.describe SFML::Font do
  describe ".default" do
    it "loads the bundled DejaVu Sans" do
      expect(described_class.default).to be_a(described_class)
    end

    it "memoizes the same instance across calls" do
      expect(described_class.default).to be(described_class.default)
    end
  end

  describe ".find" do
    # Point SEARCH_PATHS at our self-contained fixtures directory so the
    # test isn't influenced by what fonts the host happens to have.
    let(:fixtures_dir) { File.expand_path("../../fixtures", __dir__) }

    it "finds a font by basename in a configured directory" do
      stub_const("#{described_class}::SEARCH_PATHS", [fixtures_dir])
      expect(described_class.find("DejaVuSans")).to be_a(described_class)
    end

    it "returns nil when no match exists" do
      stub_const("#{described_class}::SEARCH_PATHS", [fixtures_dir])
      expect(described_class.find("definitely-not-a-real-font-12345")).to be_nil
    end
  end

  describe ".load" do
    it "raises on a non-existent path" do
      expect { described_class.load("/nope/missing.ttf") }
        .to raise_error(SFML::Error, /Could not load font/)
    end
  end

  describe "smooth flag" do
    it "is settable" do
      font = described_class.default
      font.smooth = false
      expect(font.smooth?).to be false
      font.smooth = true
      expect(font.smooth?).to be true
    end
  end

  describe ".from_memory" do
    it "round-trips with file-loaded bytes" do
      bytes = File.binread(SFML::Font::DEFAULT_PATH)
      font = described_class.from_memory(bytes)
      expect(font.family).to eq(described_class.default.family)
    end

    it "raises on garbage bytes" do
      expect { described_class.from_memory("not a font") }.to raise_error(SFML::Error)
    end
  end

  describe "#family" do
    it "returns the human-readable family name" do
      expect(described_class.default.family).to be_a(String)
      expect(described_class.default.family).not_to be_empty
    end
  end

  describe "#has_glyph?" do
    it "returns true for ASCII letters" do
      expect(described_class.default.has_glyph?("A")).to be true
    end

    it "accepts an Integer codepoint" do
      expect(described_class.default.has_glyph?(0x41)).to be true
    end
  end

  describe "metrics" do
    let(:font) { described_class.default }

    it "#kerning returns a Float" do
      expect(font.kerning("A", "V", character_size: 32)).to be_a(Float)
    end

    it "#kerning(bold:) uses the bold-weight kerning table" do
      expect(font.kerning("A", "V", character_size: 32, bold: true)).to be_a(Float)
    end

    it "#line_spacing scales with character size" do
      expect(font.line_spacing(64)).to be > font.line_spacing(16)
    end

    it "#underline_position / #underline_thickness are positive floats" do
      expect(font.underline_position(32)).to be_a(Float)
      expect(font.underline_thickness(32)).to be > 0
    end
  end

  describe "#texture" do
    it "returns a (borrowed) SFML::Texture for the requested size" do
      tex = described_class.default.texture(32)
      expect(tex).to be_a(SFML::Texture)
      expect(tex.size.x).to be > 0
    end
  end

  describe "#dup" do
    it "produces an independent Font handle" do
      a = described_class.default
      b = a.dup
      expect(b).to be_a(described_class)
      expect(b.handle).not_to eq(a.handle)
    end
  end
end
