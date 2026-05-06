RSpec.describe SFML::RectangleShape do
  it "round-trips its size through CSFML" do
    rect = described_class.new(size: [120, 80])
    expect(rect.size).to eq(SFML::Vector2[120, 80])
  end

  it "honors fill / outline kwargs" do
    rect = described_class.new(
      size:              [50, 50],
      fill_color:        SFML::Color["#336699"],
      outline_color:     SFML::Color.white,
      outline_thickness: 2,
    )
    expect(rect.fill_color).to eq(SFML::Color["#336699"])
    expect(rect.outline_color).to eq(SFML::Color.white)
    expect(rect.outline_thickness).to eq(2.0)
  end

  it "shares the Transformable mixin" do
    rect = described_class.new(size: [10, 10], position: [0, 0])
    rect.move([7, 8])
    expect(rect.position).to eq(SFML::Vector2[7, 8])
  end
end
