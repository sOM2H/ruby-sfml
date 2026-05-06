RSpec.describe SFML::Vector2 do
  describe "construction" do
    it "defaults to (0, 0)" do
      v = described_class.new
      expect(v.x).to eq(0)
      expect(v.y).to eq(0)
    end

    it "accepts the [] shorthand" do
      v = described_class[3, 4]
      expect(v.to_a).to eq([3, 4])
    end

    it "is frozen / immutable" do
      expect(described_class.new(1, 2)).to be_frozen
    end
  end

  describe "arithmetic" do
    let(:a) { described_class[3, 4] }
    let(:b) { described_class[1, 2] }

    it "adds component-wise"      do expect((a + b).to_a).to eq([4, 6]) end
    it "subtracts component-wise" do expect((a - b).to_a).to eq([2, 2]) end
    it "multiplies by a scalar"   do expect((a * 2).to_a).to eq([6, 8]) end
    it "divides by a scalar"      do expect((a / 2).to_a).to eq([1.5, 2.0]) end
    it "negates"                  do expect((-a).to_a).to eq([-3, -4]) end
  end

  describe "scalar arithmetic with number on the left" do
    it "supports `2 * v` via #coerce" do
      expect((2 * described_class[3, 4])).to eq(described_class[6, 8])
    end

    it "supports `0.5 * v` (float coercion)" do
      expect((0.5 * described_class[3, 4])).to eq(described_class[1.5, 2.0])
    end

    it "rejects coercion from non-numerics" do
      expect { described_class[1, 2].coerce("foo") }.to raise_error(TypeError)
    end
  end

  describe "geometry" do
    it "computes length"     do expect(described_class[3, 4].length).to eq(5.0) end
    it "computes length_sq"  do expect(described_class[3, 4].length_sq).to eq(25) end
    it "computes dot"        do expect(described_class[1, 2].dot(described_class[3, 4])).to eq(11) end
    it "computes 2D cross"   do expect(described_class[1, 0].cross(described_class[0, 1])).to eq(1) end

    it "normalizes to unit length" do
      n = described_class[3, 4].normalize
      expect(n.length).to be_within(1e-9).of(1.0)
    end

    it "normalizes the zero vector to zero" do
      expect(described_class.zero.normalize).to eq(described_class.zero)
    end
  end

  describe "equality and hashing" do
    it "is equal by value" do
      expect(described_class[1, 2]).to eq(described_class[1, 2])
    end

    it "is usable as a Hash key" do
      h = { described_class[1, 2] => :a }
      expect(h[described_class[1, 2]]).to eq(:a)
    end
  end

  describe "deconstruction" do
    it "destructures positionally via splat or to_a" do
      x, y = *described_class[7, 9]
      expect([x, y]).to eq([7, 9])

      x2, y2 = described_class[7, 9].to_a
      expect([x2, y2]).to eq([7, 9])
    end

    it "matches in case/in" do
      result = case described_class[1, 2]
               in {x: 1, y: 2} then :ok
               end
      expect(result).to eq(:ok)
    end
  end
end
