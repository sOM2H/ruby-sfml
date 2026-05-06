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
end
