RSpec.describe SFML::SpriteSheet do
  # 8×2 pixel image = 4 cells of 2×2 in a 1×4 grid
  let(:texture) do
    pixels = "\xff\x00\x00\xff" * 16
    img    = SFML::Image.from_pixels(8, 2, pixels)
    SFML::Texture.from_image(img)
  end

  describe ".new" do
    it "slices a uniformly-gridded texture into frames" do
      sheet = described_class.new(texture: texture, frame_size: [2, 2])
      expect(sheet.frame_count).to eq(4)
      expect(sheet.cols).to eq(4)
      expect(sheet.rows).to eq(1)
    end

    it "honors a single Integer frame_size as a square" do
      sheet = described_class.new(texture: texture, frame_size: 2)
      expect(sheet.frame_w).to eq(2)
      expect(sheet.frame_h).to eq(2)
    end

    it "accepts Vector2 for frame_size" do
      sheet = described_class.new(texture: texture, frame_size: SFML::Vector2[2, 2])
      expect(sheet.frame_count).to eq(4)
    end
  end

  describe "#region" do
    let(:sheet) { described_class.new(texture: texture, frame_size: [2, 2]) }

    it "returns Rect for an index" do
      expect(sheet.region(0)).to eq(SFML::Rect.new([0, 0], [2, 2]))
      expect(sheet.region(2)).to eq(SFML::Rect.new([4, 0], [2, 2]))
    end

    it "wraps negative indexes (e.g. -1 → last)" do
      expect(sheet.region(-1)).to eq(SFML::Rect.new([6, 0], [2, 2]))
    end
  end

  describe "#region_at" do
    let(:sheet) { described_class.new(texture: texture, frame_size: [2, 2]) }

    it "looks up by [col, row]" do
      expect(sheet.region_at(2, 0)).to eq(SFML::Rect.new([4, 0], [2, 2]))
    end

    it "raises on out-of-range coords" do
      expect { sheet.region_at(99, 0) }.to raise_error(IndexError)
      expect { sheet.region_at(0, 99) }.to raise_error(IndexError)
    end
  end

  describe "#animation" do
    let(:sheet) { described_class.new(texture: texture, frame_size: [2, 2]) }

    it "produces a default Animation cycling all frames" do
      anim = sheet.animation(fps: 4)
      expect(anim).to be_a(SFML::Animation)
      expect(anim.duration).to eq(1.0)
    end

    it "honors frame_indexes:" do
      anim = sheet.animation(frame_indexes: [0, 2], fps: 4)
      expect(anim.duration).to eq(0.5)
    end
  end
end
