RSpec.describe SFML::Keyboard do
  describe ".symbol_to_code / .code_to_symbol" do
    it "round-trips :a (which is sfKeyA = 0)" do
      code = described_class.symbol_to_code(:a)
      expect(code).to eq(0)
      expect(described_class.code_to_symbol(code)).to eq(:a)
    end

    it "round-trips :escape" do
      code = described_class.symbol_to_code(:escape)
      expect(described_class.code_to_symbol(code)).to eq(:escape)
    end

    it "honors aliases" do
      expect(described_class.symbol_to_code(:esc)).to eq(described_class.symbol_to_code(:escape))
    end

    it "raises on unknown symbol" do
      expect { described_class.symbol_to_code(:not_a_key) }.to raise_error(ArgumentError)
    end

    it "returns :unknown for out-of-range codes" do
      expect(described_class.code_to_symbol(-1)).to eq(:unknown)
      expect(described_class.code_to_symbol(9999)).to eq(:unknown)
    end
  end

  describe "scancode" do
    it "round-trips :scan_a (which is sfScanA = 0)" do
      code = described_class.symbol_to_scancode(:scan_a)
      expect(code).to eq(0)
      expect(described_class.scancode_to_symbol(code)).to eq(:scan_a)
    end

    it "returns :scan_unknown for negative / out-of-range codes" do
      expect(described_class.scancode_to_symbol(-1)).to   eq(:scan_unknown)
      expect(described_class.scancode_to_symbol(9999)).to eq(:scan_unknown)
    end

    it "raises on unknown scancode symbol" do
      expect { described_class.symbol_to_scancode(:not_a_scan) }.to raise_error(ArgumentError)
    end

    it "scancode_pressed? returns a Boolean without raising" do
      expect([true, false]).to include(described_class.scancode_pressed?(:scan_escape))
    end
  end

  describe ".localize / .delocalize / .description" do
    it "localize(scancode) → logical key symbol" do
      expect(described_class.localize(:scan_w)).to be_a(Symbol)
    end

    it "delocalize(key) → physical scancode symbol" do
      expect(described_class.delocalize(:w)).to be_a(Symbol)
    end

    it "description returns a non-empty String" do
      expect(described_class.description(:scan_enter)).not_to be_empty
    end
  end
end
