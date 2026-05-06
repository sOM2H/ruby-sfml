RSpec.describe SFML::CircleShape do
  it "creates with a radius and reads it back from CSFML" do
    shape = described_class.new(radius: 42.5)
    expect(shape.radius).to eq(42.5)
  end

  it "applies position, fill color, and outline from kwargs" do
    shape = described_class.new(
      radius:            10,
      position:          [100, 200],
      fill_color:        SFML::Color.red,
      outline_color:     SFML::Color.white,
      outline_thickness: 3,
    )
    expect(shape.position).to eq(SFML::Vector2[100, 200])
    expect(shape.fill_color).to eq(SFML::Color.red)
    expect(shape.outline_color).to eq(SFML::Color.white)
    expect(shape.outline_thickness).to eq(3.0)
  end

  it "supports the Transformable mixin" do
    shape = described_class.new(radius: 5, position: [0, 0])
    shape.move(SFML::Vector2[3, 4])
    expect(shape.position).to eq(SFML::Vector2[3, 4])

    shape.rotation = 45
    expect(shape.rotation).to be_within(1e-3).of(45.0)
  end

  it "accepts plain [x, y] arrays for vector setters" do
    shape = described_class.new(radius: 5)
    shape.position = [10, 20]
    expect(shape.position).to eq(SFML::Vector2[10, 20])
  end

  it "responds to draw_on (drawable interface)" do
    expect(described_class.new(radius: 5)).to respond_to(:draw_on)
  end
end
