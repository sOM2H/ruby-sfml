RSpec.describe SFML::Vector3 do
  it "defaults to (0, 0, 0)" do
    expect(described_class.new.to_a).to eq([0, 0, 0])
  end

  it "adds, subtracts, scales" do
    a = described_class[1, 2, 3]
    b = described_class[4, 5, 6]
    expect((a + b).to_a).to eq([5, 7, 9])
    expect((b - a).to_a).to eq([3, 3, 3])
    expect((a * 2).to_a).to eq([2, 4, 6])
  end

  it "computes 3D cross product" do
    x = described_class[1, 0, 0]
    y = described_class[0, 1, 0]
    expect(x.cross(y).to_a).to eq([0, 0, 1])
  end

  it "computes length" do
    expect(described_class[1, 2, 2].length).to eq(3.0)
  end

  it "deconstructs in case/in" do
    matched = case described_class[1, 2, 3]
              in [1, 2, 3] then true
              end
    expect(matched).to be true
  end

  describe "math helpers" do
    it "#distance computes Euclidean distance" do
      expect(described_class[1, 0, 0].distance([4, 0, 0])).to eq(3.0)
    end

    it "#lerp interpolates linearly" do
      expect(described_class[0, 0, 0].lerp([10, 20, 30], 0.5)).to eq(described_class[5, 10, 15])
    end

    it "#angle_between returns the angle between two directions" do
      a = described_class[1, 0, 0]
      b = described_class[0, 1, 0]
      expect(a.angle_between(b)).to be_within(1e-9).of(Math::PI / 2)
    end

    it "#angle_between returns 0 when either side is zero" do
      expect(described_class.zero.angle_between([1, 0, 0])).to eq(0.0)
    end

    it "#project_on works in 3D" do
      expect(described_class[3, 4, 5].project_on([1, 0, 0])).to eq(described_class[3, 0, 0])
    end

    it "#reflect bounces across a unit normal" do
      v = described_class[1, -1, 0].reflect([0, 1, 0])
      expect(v.to_a).to eq([1, 1, 0])
    end

    it "#clamp_length caps the magnitude" do
      v = described_class[3, 4, 12].clamp_length(2)
      expect(v.length).to be_within(1e-9).of(2.0)
    end

    it "#zero? recognises the zero vector" do
      expect(described_class.zero.zero?).to be true
      expect(described_class[1, 0, 0].zero?).to be false
    end

    it "#to_v2 drops z" do
      expect(described_class[1, 2, 3].to_v2).to eq(SFML::Vector2[1, 2])
    end

    it "supports `2 * v` via #coerce" do
      expect(2 * described_class[1, 2, 3]).to eq(described_class[2, 4, 6])
    end
  end
end
