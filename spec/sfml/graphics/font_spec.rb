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
end
