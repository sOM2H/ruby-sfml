RSpec.describe SFML::Font do
  describe ".find" do
    it "locates DejaVuSans on this system" do
      font = described_class.find("DejaVuSans")
      expect(font).to be_a(described_class)
    end

    it "returns nil when no match exists" do
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
      font = described_class.find("DejaVuSans")
      font.smooth = false
      expect(font.smooth?).to be false
      font.smooth = true
      expect(font.smooth?).to be true
    end
  end
end
