RSpec.describe SFML::Color do
  it "constructs from r, g, b with default alpha 255" do
    c = described_class.new(10, 20, 30)
    expect([c.r, c.g, c.b, c.a]).to eq([10, 20, 30, 255])
  end

  it "is immutable" do
    expect(described_class.new(0, 0, 0)).to be_frozen
  end

  describe "hex parsing" do
    it "#RGB"      do expect(described_class["#abc"]).to    eq(described_class.new(170, 187, 204)) end
    it "#RRGGBB"   do expect(described_class["#ff0080"]).to eq(described_class.new(255, 0, 128)) end
    it "#RRGGBBAA" do expect(described_class["#ff008080"]).to eq(described_class.new(255, 0, 128, 128)) end
    it "raises on bad length" do
      expect { described_class["#1234"] }.to raise_error(ArgumentError)
    end
  end

  describe "named colors" do
    it { expect(described_class.cornflower_blue).to eq(described_class.new(100, 149, 237)) }
    it { expect(described_class.transparent.a).to eq(0) }
    it "named singletons are frozen and identical" do
      expect(described_class.red).to be(described_class::RED)
    end
  end

  describe "pattern matching" do
    it "deconstructs to [r, g, b, a]" do
      result = case described_class.new(1, 2, 3, 4)
               in [1, 2, 3, 4] then :ok
               end
      expect(result).to eq(:ok)
    end

    it "matches on hash keys" do
      result = case described_class.new(1, 2, 3)
               in {r: 1, a: 255} then :ok
               end
      expect(result).to eq(:ok)
    end
  end

  it "round-trips through native struct" do
    color = described_class.new(10, 20, 30, 40)
    native = color.to_native
    expect(described_class.from_native(native)).to eq(color)
  end
end
