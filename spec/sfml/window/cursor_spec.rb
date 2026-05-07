RSpec.describe SFML::Cursor do
  describe "TYPES" do
    it "matches CSFML 3 sfCursorType length" do
      expect(described_class::TYPES.length).to eq(21)
    end

    it "starts with :arrow" do
      expect(described_class::TYPE_INDEX[:arrow]).to eq(0)
    end

    it "indexes :hand at 4 (after arrow, arrow_wait, wait, text)" do
      expect(described_class::TYPE_INDEX[:hand]).to eq(4)
    end
  end

  describe ".system" do
    it "creates a cursor for a known type (or skips if the WM rejects it)" do
      # Some cursor types are unsupported on certain X11 setups —
      # the wrapper raises SFML::Error in that case, which is the
      # documented behaviour. :hand is supported essentially everywhere.
      expect(described_class.system(:hand)).to be_a(described_class)
    end

    it "raises ArgumentError for unknown types" do
      expect { described_class.system(:teleport) }
        .to raise_error(ArgumentError, /Unknown cursor type/)
    end
  end

  describe ".from_pixels" do
    it "builds a cursor from a 16×16 RGBA buffer" do
      pixels = "\xFF\x80\x40\xFF" * (16 * 16)
      expect(described_class.from_pixels(16, 16, pixels)).to be_a(described_class)
    end

    it "rejects mismatched buffer sizes" do
      expect { described_class.from_pixels(8, 8, "abc") }
        .to raise_error(ArgumentError, /must be 256 bytes/)
    end
  end
end
