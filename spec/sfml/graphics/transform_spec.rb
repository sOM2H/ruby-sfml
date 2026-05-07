RSpec.describe SFML::Transform do
  describe ".identity" do
    it "returns the 3×3 identity matrix" do
      t = described_class.identity
      expect(t.matrix).to eq([1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0])
    end
  end

  describe "#translate" do
    it "shifts a point by the given offset" do
      t = described_class.identity.translate([100, 50])
      expect(t.transform_point([10, 20])).to eq(SFML::Vector2[110.0, 70.0])
    end

    it "is chainable (mutates and returns self)" do
      t = described_class.identity
      expect(t.translate([1, 2])).to be(t)
    end
  end

  describe "#rotate" do
    it "90° rotation maps (1, 0) → (0, 1)" do
      t = described_class.identity.rotate(90)
      result = t.transform_point([1, 0])
      expect(result.x).to be_within(1e-5).of(0.0)
      expect(result.y).to be_within(1e-5).of(1.0)
    end

    it "rotates around an explicit center" do
      t = described_class.identity.rotate(180, center: [10, 0])
      # 180° around (10, 0) maps (20, 0) to (0, 0)
      result = t.transform_point([20, 0])
      expect(result.x).to be_within(1e-5).of(0.0)
      expect(result.y).to be_within(1e-5).of(0.0)
    end
  end

  describe "#scale" do
    it "doubles a point" do
      t = described_class.identity.scale([2, 2])
      expect(t.transform_point([3, 4])).to eq(SFML::Vector2[6.0, 8.0])
    end
  end

  describe "#combine" do
    it "applies the right operand first, then the left" do
      # Translate by (10,0), then scale by 2 → (10*2, 0) = (20, 0)
      tr = described_class.identity.translate([10, 0])
      sc = described_class.identity.scale([2, 2])
      combined = sc.dup.combine(tr)
      expect(combined.transform_point([0, 0])).to eq(SFML::Vector2[20.0, 0.0])
    end
  end

  describe "#inverse" do
    it "produces a transform that undoes the original" do
      t   = described_class.identity.translate([100, 50]).scale([2, 2])
      inv = t.inverse
      result = inv.transform_point(t.transform_point([3, 4]))
      expect(result.x).to be_within(1e-3).of(3.0)
      expect(result.y).to be_within(1e-3).of(4.0)
    end
  end

  describe "#transform_rect" do
    it "scales a rectangle in place" do
      t = described_class.identity.scale([2, 2])
      r = t.transform_rect(SFML::Rect.new([10, 20], [30, 40]))
      expect(r.x).to eq(20.0)
      expect(r.y).to eq(40.0)
      expect(r.width).to eq(60.0)
      expect(r.height).to eq(80.0)
    end
  end

  describe "#dup" do
    it "creates an independent copy" do
      a = described_class.identity.translate([5, 0])
      b = a.dup.translate([3, 0])
      expect(a.transform_point([0, 0])).to eq(SFML::Vector2[5.0, 0.0])
      expect(b.transform_point([0, 0])).to eq(SFML::Vector2[8.0, 0.0])
    end
  end

  describe ".from_matrix" do
    it "round-trips through #matrix" do
      m = [2.0, 0.0, 100.0, 0.0, 3.0, 50.0, 0.0, 0.0, 1.0]
      t = described_class.from_matrix(m)
      expect(t.matrix).to eq(m)
    end

    it "rejects wrong-length input" do
      expect { described_class.from_matrix([1, 2, 3]) }.to raise_error(ArgumentError, /9-element/)
    end
  end

  describe "equality" do
    it "compares by matrix value" do
      a = described_class.identity.translate([3, 0])
      b = described_class.identity.translate([3, 0])
      expect(a).to eq(b)
    end
  end
end
