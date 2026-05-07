RSpec.describe SFML::VertexArray do
  describe ".new" do
    it "starts empty with the specified primitive" do
      va = described_class.new(:lines)
      expect(va.size).to eq(0)
      expect(va).to be_empty
      expect(va.primitive_type).to eq(:lines)
    end

    it "accepts an initial enumerable of vertices" do
      va = described_class.new(:triangles, [
        SFML::Vertex.new([0, 0],   color: SFML::Color.red),
        SFML::Vertex.new([10, 0],  color: SFML::Color.green),
        SFML::Vertex.new([5, 10],  color: SFML::Color.blue),
      ])
      expect(va.size).to eq(3)
      expect(va.primitive_type).to eq(:triangles)
    end

    it "rejects an unknown primitive type" do
      expect { described_class.new(:donut) }
        .to raise_error(ArgumentError, /Unknown primitive type/)
    end
  end

  describe "primitive types match CSFML order" do
    specify { expect(described_class::PRIMITIVE_TYPES).to eq(%i[points lines line_strip triangles triangle_strip triangle_fan]) }
    specify { expect(described_class::PRIMITIVE_INDEX[:triangle_fan]).to eq(5) }
  end

  describe "#append / #<< / #[]" do
    let(:va) { described_class.new(:points) }

    it "appends and reads back vertices" do
      v = SFML::Vertex.new([10, 20], color: SFML::Color.red)
      va << v
      expect(va.size).to eq(1)
      expect(va[0].position).to eq(SFML::Vector2[10, 20])
      expect(va[0].color).to eq(SFML::Color.red)
    end

    it "[]= rewrites a vertex in place" do
      va << SFML::Vertex.new([0, 0])
      va[0] = SFML::Vertex.new([99, 99], color: SFML::Color.green)
      expect(va[0].position).to eq(SFML::Vector2[99, 99])
      expect(va[0].color).to eq(SFML::Color.green)
    end

    it "[]= raises on out-of-range indexes" do
      va << SFML::Vertex.new([0, 0])
      expect { va[5] = SFML::Vertex.new([0, 0]) }
        .to raise_error(IndexError, /out of range/)
    end
  end

  describe "#clear / #resize" do
    let(:va) { described_class.new(:points) }

    it "#clear empties the array" do
      3.times { va << SFML::Vertex.new([0, 0]) }
      va.clear
      expect(va.size).to eq(0)
    end

    it "#resize grows the array, filling new slots with default vertices" do
      va.resize(4)
      expect(va.size).to eq(4)
      expect(va[3].position).to eq(SFML::Vector2[0, 0])
    end
  end

  describe "#each + Enumerable" do
    it "iterates in insertion order" do
      va = described_class.new(:points, [
        SFML::Vertex.new([1, 0]),
        SFML::Vertex.new([2, 0]),
        SFML::Vertex.new([3, 0]),
      ])
      xs = va.map { |v| v.position.x }
      expect(xs).to eq([1, 2, 3])
    end

    it "is Enumerable" do
      expect(described_class.new(:points)).to be_a(Enumerable)
    end
  end

  describe "#bounds" do
    it "returns the axis-aligned bounding box of all positions" do
      va = described_class.new(:triangles, [
        SFML::Vertex.new([10, 20]),
        SFML::Vertex.new([110, 20]),
        SFML::Vertex.new([60, 100]),
      ])
      expect(va.bounds.x).to eq(10)
      expect(va.bounds.y).to eq(20)
      expect(va.bounds.width).to eq(100)
      expect(va.bounds.height).to eq(80)
    end
  end
end
