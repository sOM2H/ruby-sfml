RSpec.describe SFML::ConvexShape do
  let(:tri) { [[0, 0], [100, 0], [50, 80]] }

  it "applies points and styling at construction" do
    shape = described_class.new(
      points:            tri,
      fill_color:        SFML::Color.cornflower_blue,
      outline_color:     SFML::Color.white,
      outline_thickness: 2,
    )
    expect(shape.point_count).to eq(3)
    expect(shape.points).to eq([SFML::Vector2[0, 0], SFML::Vector2[100, 0], SFML::Vector2[50, 80]])
    expect(shape.fill_color).to eq(SFML::Color.cornflower_blue)
    expect(shape.outline_thickness).to eq(2.0)
  end

  it "rewrites all points via points=" do
    shape = described_class.new(points: tri)
    shape.points = [[0, 0], [10, 0], [10, 10], [0, 10]]
    expect(shape.point_count).to eq(4)
    expect(shape.points.last).to eq(SFML::Vector2[0, 10])
  end

  it "mutates a single point via set_point" do
    shape = described_class.new(points: tri)
    shape.set_point(1, [200, 5])
    expect(shape.points[1]).to eq(SFML::Vector2[200, 5])
  end

  it "shares the Transformable mixin" do
    shape = described_class.new(points: tri, position: [10, 20])
    shape.move([5, 5])
    expect(shape.position).to eq(SFML::Vector2[15, 25])
  end

  it "responds to draw_on" do
    expect(described_class.new(points: tri)).to respond_to(:draw_on)
  end

  describe "introspection" do
    let(:shape) { described_class.new(points: [[0, 0], [10, 0], [10, 10], [0, 10]]) }

    it "exposes geometric_center + bounds" do
      expect(shape.geometric_center).to eq(SFML::Vector2[5, 5])
      expect(shape.local_bounds).to     eq(SFML::Rect.new([0, 0], [10, 10]))
    end

    it "#dup is independent" do
      copy = shape.dup
      copy.set_point(0, [-5, -5])
      expect(shape.points.first).to eq(SFML::Vector2[0, 0])
      expect(copy.points.first).to  eq(SFML::Vector2[-5, -5])
    end
  end
end
