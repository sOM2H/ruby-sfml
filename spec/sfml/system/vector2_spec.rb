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

  describe "math helpers" do
    let(:v) { described_class[3, 4] }

    it "#distance and #distance_sq accept Vector2 or [x, y]" do
      expect(v.distance(described_class.zero)).to eq(5.0)
      expect(v.distance([0, 0])).to eq(5.0)
      expect(v.distance_sq(described_class.zero)).to eq(25)
    end

    it "#angle returns the +X axis-relative angle in radians" do
      expect(described_class[1, 0].angle).to eq(0.0)
      expect(described_class[0, 1].angle).to be_within(1e-9).of(Math::PI / 2)
    end

    it "#angle_to gives the direction from self to other" do
      expect(described_class[0, 0].angle_to([1, 0])).to eq(0.0)
      expect(described_class[0, 0].angle_to([0, 1])).to be_within(1e-9).of(Math::PI / 2)
    end

    it "#rotated rotates CCW by degrees" do
      r = described_class[1, 0].rotated(90)
      expect(r.x).to be_within(1e-9).of(0.0)
      expect(r.y).to be_within(1e-9).of(1.0)
    end

    it "#perpendicular returns a 90° CCW vector" do
      expect(described_class[3, 4].perpendicular).to eq(described_class[-4, 3])
    end

    it "#lerp interpolates linearly" do
      expect(described_class[0, 0].lerp([10, 20], 0.25)).to eq(described_class[2.5, 5.0])
    end

    it "#project_on projects onto another vector" do
      expect(described_class[3, 4].project_on([1, 0])).to eq(described_class[3, 0])
    end

    it "#project_on a zero vector returns zero" do
      expect(described_class[1, 2].project_on([0, 0])).to eq(described_class.zero)
    end

    it "#reflect bounces across a unit normal" do
      expect(described_class[3, -4].reflect([0, 1])).to eq(described_class[3, 4])
    end

    it "#clamp_length caps the magnitude" do
      v = described_class[3, 4].clamp_length(2)
      expect(v.length).to be_within(1e-9).of(2.0)
    end

    it "#clamp_length raises the magnitude up to min" do
      v = described_class[0.5, 0].clamp_length(1, nil)
      expect(v.length).to be_within(1e-9).of(1.0)
    end

    it "#zero? recognises the zero vector" do
      expect(described_class.zero.zero?).to be true
      expect(described_class[1, 0].zero?).to be false
    end

    it "#abs returns per-component absolute values" do
      expect(described_class[-3, 4].abs).to eq(described_class[3, 4])
    end

    it "#to_v3 promotes with optional z" do
      expect(described_class[1, 2].to_v3).to eq(SFML::Vector3[1, 2, 0])
      expect(described_class[1, 2].to_v3(5)).to eq(SFML::Vector3[1, 2, 5])
    end
  end
end
