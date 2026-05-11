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

  describe "introspection" do
    let(:shape) { described_class.new(radius: 30, position: [10, 20]) }

    it "exposes point(i), geometric_center, local/global_bounds" do
      expect(shape.point(0)).to be_a(SFML::Vector2)
      expect(shape.geometric_center).to eq(SFML::Vector2[30, 30])
      expect(shape.local_bounds.width).to  be > 0
      expect(shape.global_bounds.width).to be > 0
    end

    it "returns its current transform" do
      expect(shape.transform).to be_a(SFML::C::Graphics::Transform)
      expect(shape.inverse_transform).to be_a(SFML::C::Graphics::Transform)
    end

    it "deep-copies via #dup" do
      copy = shape.dup
      copy.radius = 100
      expect(shape.radius).to eq(30.0)
      expect(copy.radius).to eq(100.0)
    end
  end

  describe "texture binding" do
    let(:image) { SFML::Image.from_pixels(4, 4, "\xff" * 64) }
    let(:tex)   { SFML::Texture.from_image(image) }

    it "binds + unbinds a texture" do
      shape = described_class.new(radius: 10, texture: tex)
      expect(shape.texture).not_to be_nil
      shape.set_texture(nil)
      expect(shape.texture).to be_nil
    end

    it "round-trips texture_rect" do
      shape = described_class.new(radius: 10, texture: tex)
      shape.texture_rect = SFML::Rect.new([1, 1], [2, 2])
      expect(shape.texture_rect).to eq(SFML::Rect.new([1, 1], [2, 2]))
    end

    it "reset_rect: true snaps to full texture size" do
      shape = described_class.new(radius: 10)
      shape.set_texture(tex, reset_rect: true)
      expect(shape.texture_rect).to eq(SFML::Rect.new([0, 0], [4, 4]))
    end
  end
end
