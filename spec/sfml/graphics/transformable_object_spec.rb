RSpec.describe SFML::TransformableObject do
  it "applies position / rotation / scale / origin from kwargs" do
    t = described_class.new(
      position: [10, 20], rotation: 45, scale: [2, 3], origin: [1, 1],
    )
    expect(t.position).to eq(SFML::Vector2[10, 20])
    expect(t.rotation).to be_within(1e-3).of(45.0)
    expect(t.scale).to    eq(SFML::Vector2[2, 3])
    expect(t.origin).to   eq(SFML::Vector2[1, 1])
  end

  it "exposes a transform that #dup doesn't alias" do
    t = described_class.new(position: [10, 20])
    t2 = t.dup
    t2.move([5, 5])
    expect(t.position).to  eq(SFML::Vector2[10, 20])
    expect(t2.position).to eq(SFML::Vector2[15, 25])
  end

  it "transform / inverse_transform return CSFML structs" do
    t = described_class.new(position: [10, 20])
    expect(t.transform).to         be_a(SFML::C::Graphics::Transform)
    expect(t.inverse_transform).to be_a(SFML::C::Graphics::Transform)
  end
end
