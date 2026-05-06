RSpec.describe SFML::Time do
  describe "factories" do
    it "from seconds"      do expect(described_class.seconds(1.5).as_microseconds).to eq(1_500_000) end
    it "from milliseconds" do expect(described_class.milliseconds(250).as_microseconds).to eq(250_000) end
    it "from microseconds" do expect(described_class.microseconds(42).as_microseconds).to eq(42) end
    it "zero"              do expect(described_class.zero.as_microseconds).to eq(0) end
  end

  describe "conversions" do
    let(:t) { described_class.milliseconds(1500) }
    it { expect(t.as_seconds).to eq(1.5) }
    it { expect(t.as_milliseconds).to eq(1500) }
    it { expect(t.as_microseconds).to eq(1_500_000) }
  end

  describe "arithmetic and comparison" do
    let(:a) { described_class.milliseconds(100) }
    let(:b) { described_class.milliseconds(50) }

    it { expect((a + b).as_milliseconds).to eq(150) }
    it { expect((a - b).as_milliseconds).to eq(50) }
    it { expect(-a).to eq(described_class.milliseconds(-100)) }
    it { expect(a > b).to be true }
    it { expect([b, a].min).to eq(b) }
  end

  it "is immutable" do
    expect(described_class.zero).to be_frozen
  end
end
