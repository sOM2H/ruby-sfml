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

  describe "arithmetic" do
    let(:c1) { described_class.new(100, 50, 25, 200) }
    let(:c2) { described_class.new(50,  50, 50, 50)  }

    it "+ saturates per channel" do
      expect(c1 + c2).to eq(described_class.new(150, 100, 75, 250))
    end

    it "+ clamps at 255" do
      expect(described_class.new(200, 200, 200) + described_class.new(100, 100, 100))
        .to eq(described_class.new(255, 255, 255))
    end

    it "- saturates at 0" do
      expect(c1 - c2).to eq(described_class.new(50, 0, 0, 150))
    end

    it "* modulates (a * b) / 255" do
      expect(c1 * described_class.white).to eq(c1)
      expect(c1 * described_class.new(0, 0, 0, 255)).to eq(described_class.new(0, 0, 0, 200))
    end

    it "+ raises on non-Color rhs" do
      expect { c1 + 5 }.to raise_error(ArgumentError)
    end
  end

  describe "integer packing" do
    it "round-trips through to_integer / from_integer" do
      c = described_class.new(100, 50, 25, 200)
      expect(described_class.from_integer(c.to_integer)).to eq(c)
    end
  end
end
