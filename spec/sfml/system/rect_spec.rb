RSpec.describe SFML::Rect do
  it "constructs from arrays or Vector2s" do
    r = described_class.new([10, 20], [100, 50])
    expect(r.x).to eq(10)
    expect(r.y).to eq(20)
    expect(r.width).to eq(100)
    expect(r.height).to eq(50)

    r2 = described_class.new(SFML::Vector2[10, 20], SFML::Vector2[100, 50])
    expect(r2).to eq(r)
  end

  it "exposes left/top/right/bottom" do
    r = described_class.new([10, 20], [100, 50])
    expect(r.left).to eq(10)
    expect(r.top).to eq(20)
    expect(r.right).to eq(110)
    expect(r.bottom).to eq(70)
  end

  describe "#contains?" do
    let(:r) { described_class.new([10, 10], [100, 100]) }

    it "is true for inside points"      do expect(r.contains?([50, 50])).to be true end
    it "is false for outside points"    do expect(r.contains?([200, 50])).to be false end
    it "is true on the top-left edge"   do expect(r.contains?([10, 10])).to be true end
    it "is false on the bottom-right"   do expect(r.contains?([110, 110])).to be false end
    it "accepts a Vector2"              do expect(r.contains?(SFML::Vector2[50, 50])).to be true end
  end

  describe "#intersects?" do
    let(:a) { described_class.new([0, 0], [100, 100]) }
    it { expect(a.intersects?(described_class.new([50, 50], [100, 100]))).to be true }
    it { expect(a.intersects?(described_class.new([200, 200], [10, 10]))).to be false }
    it { expect(a.intersects?(described_class.new([100, 100], [10, 10]))).to be false } # touching, not overlapping
  end

  it "deconstructs in case/in" do
    r = described_class.new([10, 20], [100, 50])
    matched = case r
              in {position: {x: 10, y: 20}, size: {x: 100, y: 50}} then :ok
              end
    expect(matched).to eq(:ok)
  end

  it "is frozen" do
    expect(described_class.new([0, 0], [1, 1])).to be_frozen
  end
end
