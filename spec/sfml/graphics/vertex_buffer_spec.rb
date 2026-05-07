RSpec.describe SFML::VertexBuffer do
  before { skip "VBOs unavailable on this runner" unless described_class.available? }

  let(:triangle) do
    [
      SFML::Vertex.new([0,   0],   color: SFML::Color.red),
      SFML::Vertex.new([100, 0],   color: SFML::Color.green),
      SFML::Vertex.new([50,  86],  color: SFML::Color.blue),
    ]
  end

  describe ".new" do
    it "creates a buffer from an array of vertices" do
      buf = described_class.new(triangle, primitive_type: :triangles, usage: :static)
      expect(buf.count).to eq(3)
      expect(buf.primitive_type).to eq(:triangles)
      expect(buf.usage).to eq(:static)
    end

    it "creates an empty buffer with `count:`" do
      buf = described_class.new(count: 16, primitive_type: :points, usage: :dynamic)
      expect(buf.count).to eq(16)
    end

    it "rejects unknown primitive types" do
      expect { described_class.new(triangle, primitive_type: :nope) }
        .to raise_error(ArgumentError, /Unknown primitive type/)
    end

    it "rejects unknown usages" do
      expect { described_class.new(triangle, usage: :nope) }
        .to raise_error(ArgumentError, /Unknown VertexBuffer usage/)
    end
  end

  describe "#update" do
    it "patches a region without raising" do
      buf  = described_class.new(count: 4, primitive_type: :points, usage: :dynamic)
      pair = [
        SFML::Vertex.new([1, 1], color: SFML::Color.white),
        SFML::Vertex.new([2, 2], color: SFML::Color.white),
      ]
      expect { buf.update(pair, offset: 1) }.not_to raise_error
    end
  end

  describe "primitive_type= and usage=" do
    it "round-trips primitive_type" do
      buf = described_class.new(triangle, primitive_type: :triangles, usage: :static)
      buf.primitive_type = :line_strip
      expect(buf.primitive_type).to eq(:line_strip)
    end

    it "round-trips usage" do
      buf = described_class.new(triangle, primitive_type: :triangles, usage: :static)
      buf.usage = :stream
      expect(buf.usage).to eq(:stream)
    end
  end

  describe "rendering integration" do
    it "draws on a RenderTexture without raising" do
      buf = described_class.new(triangle, primitive_type: :triangles, usage: :static)
      rt  = SFML::RenderTexture.new(128, 128)
      rt.clear(SFML::Color.black)
      expect { rt.draw(buf) }.not_to raise_error
      rt.display
    end

    it "draw_range_on draws a slice without raising" do
      buf = described_class.new(triangle, primitive_type: :triangles, usage: :static)
      rt  = SFML::RenderTexture.new(128, 128)
      rt.clear(SFML::Color.black)
      expect { buf.draw_range_on(rt, 0, 3) }.not_to raise_error
      rt.display
    end
  end

  describe "#native_handle" do
    it "returns an integer GL name" do
      buf = described_class.new(triangle, primitive_type: :triangles, usage: :static)
      expect(buf.native_handle).to be_a(Integer)
    end
  end
end
