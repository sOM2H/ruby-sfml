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

  describe "introspection" do
    let(:rect) { described_class.new(size: [100, 50]) }

    it "exposes the 4 corner points" do
      expect(rect.point_count).to eq(4)
      expect(rect.point(0)).to eq(SFML::Vector2[0,   0])
      expect(rect.point(2)).to eq(SFML::Vector2[100, 50])
    end

    it "centroid + local_bounds match the rect dimensions" do
      expect(rect.geometric_center).to eq(SFML::Vector2[50, 25])
      expect(rect.local_bounds).to     eq(SFML::Rect.new([0, 0], [100, 50]))
    end

    it "#dup is independent" do
      copy = rect.dup
      copy.size = [10, 10]
      expect(rect.size).to eq(SFML::Vector2[100, 50])
      expect(copy.size).to eq(SFML::Vector2[10, 10])
    end
  end

  it "binds a texture" do
    img = SFML::Image.from_pixels(4, 4, "\xff" * 64)
    tex = SFML::Texture.from_image(img)
    rect = described_class.new(size: [10, 10], texture: tex)
    expect(rect.texture).not_to be_nil
  end
end
