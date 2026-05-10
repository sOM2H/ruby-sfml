RSpec.describe SFML::View do
  describe ".new" do
    it "applies center and size kwargs at construction" do
      v = described_class.new(center: [400, 300], size: [800, 600])
      expect(v.center).to eq(SFML::Vector2[400, 300])
      expect(v.size).to eq(SFML::Vector2[800, 600])
    end

    it "defaults rotation to 0" do
      expect(described_class.new.rotation).to eq(0.0)
    end
  end

  describe ".from_rect" do
    it "centres on the middle of the given rectangle" do
      v = described_class.from_rect(SFML::Rect.new([0, 0], [1600, 1200]))
      expect(v.center).to eq(SFML::Vector2[800, 600])
      expect(v.size).to   eq(SFML::Vector2[1600, 1200])
    end

    it "raises if argument is not a Rect" do
      expect { described_class.from_rect([0, 0, 100, 100]) }
        .to raise_error(ArgumentError, /SFML::Rect/)
    end
  end

  describe "transforms" do
    let(:v) { described_class.new(center: [0, 0], size: [200, 100]) }

    it "#move shifts the centre" do
      v.move([10, 20])
      expect(v.center).to eq(SFML::Vector2[10, 20])
    end

    it "#zoom scales the visible size" do
      v.zoom(0.5)
      expect(v.size).to eq(SFML::Vector2[100, 50])
    end

    it "#rotate accumulates rotation" do
      v.rotate(30); v.rotate(15)
      expect(v.rotation).to be_within(1e-3).of(45.0)
    end

    it "accepts plain [x, y] arrays for vector setters" do
      v.center = [50, 60]
      expect(v.center).to eq(SFML::Vector2[50, 60])
    end
  end

  describe "viewport" do
    it "round-trips a normalised rect" do
      v = described_class.new
      v.viewport = SFML::Rect.new([0.5, 0.0], [0.5, 1.0])
      vp = v.viewport
      expect(vp.x).to     be_within(1e-6).of(0.5)
      expect(vp.width).to be_within(1e-6).of(0.5)
    end
  end

  describe ".from_borrowed" do
    it "deep-copies so the wrapper owns its own pointer" do
      v1 = described_class.new(center: [10, 20], size: [40, 50])
      v2 = described_class.from_borrowed(v1.handle)
      expect(v2.center).to eq(v1.center)
      v2.center = [99, 99]
      # mutating the copy must not touch the original
      expect(v1.center).to eq(SFML::Vector2[10, 20])
    end
  end

  describe "#scissor / #scissor=" do
    it "defaults to a full-window rect" do
      view = described_class.new
      expect(view.scissor.width).to  eq(1.0)
      expect(view.scissor.height).to eq(1.0)
    end

    it "round-trips through #scissor=" do
      view = described_class.new
      view.scissor = SFML::Rect.new([0.25, 0.0], [0.5, 1.0])
      expect(view.scissor.x).to     be_within(0.001).of(0.25)
      expect(view.scissor.width).to be_within(0.001).of(0.5)
    end

    it "rejects non-Rect arguments" do
      view = described_class.new
      expect { view.scissor = [0, 0, 1, 1] }.to raise_error(ArgumentError, /SFML::Rect/)
    end
  end
end
