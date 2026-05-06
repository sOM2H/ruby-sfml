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
end
