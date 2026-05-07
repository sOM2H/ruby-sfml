RSpec.describe SFML::SoundCone do
  describe ".new" do
    it "stores the three angles / gain as floats" do
      c = described_class.new(inner_angle: 30, outer_angle: 90, outer_gain: 0.25)
      expect(c.inner_angle).to eq(30.0)
      expect(c.outer_angle).to eq(90.0)
      expect(c.outer_gain).to  eq(0.25)
    end

    it "is frozen — value semantics" do
      c = described_class.new(inner_angle: 30, outer_angle: 90, outer_gain: 0.25)
      expect(c).to be_frozen
    end

    it "compares by value" do
      a = described_class.new(inner_angle: 30, outer_angle: 90, outer_gain: 0.25)
      b = described_class.new(inner_angle: 30, outer_angle: 90, outer_gain: 0.25)
      c = described_class.new(inner_angle: 45, outer_angle: 90, outer_gain: 0.25)
      expect(a).to eq(b)
      expect(a).not_to eq(c)
      expect(a.hash).to eq(b.hash)
    end
  end

  describe "round-trip through populate / from_native" do
    it "preserves all three fields (within float32 precision)" do
      original = described_class.new(inner_angle: 22.5, outer_angle: 90.0, outer_gain: 0.5)
      back     = described_class.from_native(original.to_native)
      expect(back).to eq(original)
    end
  end
end
