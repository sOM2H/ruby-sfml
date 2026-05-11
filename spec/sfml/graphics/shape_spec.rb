RSpec.describe SFML::Shape do
  let(:pentagon_class) do
    Class.new(described_class) do
      def point_count = 5
      def point(i)
        angle = i * 2 * Math::PI / 5 - Math::PI / 2
        [Math.cos(angle) * 50, Math.sin(angle) * 50]
      end
    end
  end

  it "drives geometry from subclass callbacks" do
    p = pentagon_class.new
    p.update
    expect(p.point_count).to eq(5)
    # The subclass's #point returns whatever it likes (here [x, y]).
    # Once #update has sampled it, #local_bounds reflects the geometry.
    expect(p.local_bounds.width).to be > 0
    expect(p.local_bounds.height).to be > 0
  end

  it "honors fill / outline / position kwargs" do
    p = pentagon_class.new(
      fill_color:        SFML::Color.red,
      outline_color:     SFML::Color.white,
      outline_thickness: 2,
      position:          [400, 300],
    )
    expect(p.fill_color).to        eq(SFML::Color.red)
    expect(p.outline_color).to     eq(SFML::Color.white)
    expect(p.outline_thickness).to eq(2.0)
    expect(p.position).to          eq(SFML::Vector2[400, 300])
  end

  it "uses ShapeInspectable for texture binding" do
    img = SFML::Image.from_pixels(2, 2, "\xff" * 16)
    tex = SFML::Texture.from_image(img)
    p   = pentagon_class.new(texture: tex)
    expect(p.texture).not_to be_nil
  end

  it "abstract Shape doesn't define #dup (no sfShape_copy in CSFML)" do
    expect { pentagon_class.new.dup }.to raise_error(NoMethodError)
  end

  it "raises if a subclass doesn't override the callbacks" do
    bare = described_class.new
    expect { bare.point_count }.to raise_error(NoMethodError)
    expect { bare.point(0) }.to    raise_error(NoMethodError)
  end
end
