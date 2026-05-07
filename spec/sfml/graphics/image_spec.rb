RSpec.describe SFML::Image do
  describe ".new" do
    it "creates a blank image of given size" do
      img = described_class.new(8, 4)
      expect(img.size).to eq(SFML::Vector2[8, 4])
      expect(img.width).to eq(8)
      expect(img.height).to eq(4)
    end

    it "fills every pixel with `fill:` colour" do
      img = described_class.new(2, 2, fill: SFML::Color.cornflower_blue)
      expect(img[0, 0]).to eq(SFML::Color.cornflower_blue)
      expect(img[1, 1]).to eq(SFML::Color.cornflower_blue)
    end

    it "defaults to opaque black without `fill:` (matches sfImage_create)" do
      img = described_class.new(2, 2)
      expect(img[0, 0]).to eq(SFML::Color.black)
    end
  end

  describe ".from_pixels" do
    it "round-trips RGBA bytes" do
      bytes = "\xFF\x00\x00\xFF" + "\x00\xFF\x00\xFF" + "\x00\x00\xFF\xFF" + "\xFF\xFF\x00\xFF"
      img = described_class.from_pixels(2, 2, bytes)
      expect(img[0, 0]).to eq(SFML::Color.new(255, 0, 0))
      expect(img[1, 0]).to eq(SFML::Color.new(0, 255, 0))
      expect(img[0, 1]).to eq(SFML::Color.new(0, 0, 255))
      expect(img[1, 1]).to eq(SFML::Color.new(255, 255, 0))
    end

    it "rejects mismatched buffer sizes" do
      expect { described_class.from_pixels(2, 2, "abcd") }
        .to raise_error(ArgumentError, /expected 16 bytes/)
    end
  end

  describe "#[] and #[]=" do
    let(:img) { described_class.new(4, 4, fill: SFML::Color.transparent) }

    it "writes and reads a single pixel" do
      img[2, 1] = SFML::Color.red
      expect(img[2, 1]).to eq(SFML::Color.red)
      expect(img[0, 0]).to eq(SFML::Color.transparent)
    end
  end

  describe "#pixels" do
    it "returns width*height*4 RGBA bytes" do
      img = described_class.new(3, 2, fill: SFML::Color.new(10, 20, 30, 40))
      bytes = img.pixels
      expect(bytes.bytesize).to eq(3 * 2 * 4)
      expect(bytes.bytes.first(4)).to eq([10, 20, 30, 40])
    end
  end

  describe "#flip_horizontally" do
    it "mirrors columns" do
      img = described_class.new(3, 1)
      img[0, 0] = SFML::Color.red
      img[2, 0] = SFML::Color.green
      img.flip_horizontally
      expect(img[0, 0]).to eq(SFML::Color.green)
      expect(img[2, 0]).to eq(SFML::Color.red)
    end
  end

  describe "#save and load round-trip" do
    it "saves to PNG and loads back into a matching image" do
      img = described_class.new(2, 2)
      img[0, 0] = SFML::Color.red
      img[1, 0] = SFML::Color.green
      img[0, 1] = SFML::Color.blue
      img[1, 1] = SFML::Color.white

      path = File.join(Dir.tmpdir, "ruby-sfml-test-#{$$}-#{rand(1000)}.png")
      begin
        img.save(path)
        loaded = described_class.load(path)
        expect(loaded.size).to eq(img.size)
        expect(loaded[0, 0]).to eq(SFML::Color.red)
        expect(loaded[1, 1]).to eq(SFML::Color.white)
      ensure
        File.delete(path) if File.exist?(path)
      end
    end
  end

  describe "#save_to_memory" do
    let(:img) { described_class.new(4, 4, fill: SFML::Color.new(200, 50, 50)) }

    it "encodes PNG with the correct magic number" do
      bytes = img.save_to_memory("png")
      expect(bytes.bytesize).to be > 0
      # PNG signature: 89 50 4E 47 0D 0A 1A 0A
      expect(bytes.bytes.first(4)).to eq([0x89, 0x50, 0x4E, 0x47])
    end

    it "encodes BMP with the correct magic number" do
      bytes = img.save_to_memory("bmp")
      # BMP signature: "BM"
      expect(bytes.bytes.first(2)).to eq([0x42, 0x4D])
    end

    it "round-trips through load — encode then load gives back the same pixels" do
      png = img.save_to_memory("png")
      path = File.join(Dir.tmpdir, "ruby-sfml-stm-#{$$}-#{rand(1000)}.png")
      begin
        File.binwrite(path, png)
        loaded = described_class.load(path)
        expect(loaded.size).to eq(img.size)
        expect(loaded[2, 2]).to eq(SFML::Color.new(200, 50, 50))
      ensure
        File.delete(path) if File.exist?(path)
      end
    end

    it "raises on unsupported format" do
      expect { img.save_to_memory("xyz") }
        .to raise_error(SFML::Error, /Could not encode/)
    end
  end

  describe "#mask_color!" do
    it "makes matching pixels transparent" do
      img = described_class.new(2, 1, fill: SFML::Color.magenta)
      img[1, 0] = SFML::Color.red
      img.mask_color!(SFML::Color.magenta, alpha: 0)
      expect(img[0, 0].a).to eq(0)
      expect(img[1, 0]).to eq(SFML::Color.red) # untouched
    end
  end

  describe "Texture <-> Image bridge" do
    it "uploads with Texture.from_image and reads back via #to_image" do
      img = described_class.new(4, 4, fill: SFML::Color.cornflower_blue)
      img[2, 2] = SFML::Color.red

      tex   = SFML::Texture.from_image(img)
      back  = tex.to_image

      expect(back.size).to eq(img.size)
      expect(back[2, 2]).to eq(SFML::Color.red)
      expect(back[0, 0]).to eq(SFML::Color.cornflower_blue)
    end

    it "Texture#update re-uploads pixels in place" do
      img = described_class.new(2, 2, fill: SFML::Color.transparent)
      tex = SFML::Texture.from_image(img)

      img[1, 1] = SFML::Color.red
      tex.update(img)

      expect(tex.to_image[1, 1]).to eq(SFML::Color.red)
    end

    it "Texture#update rejects non-Image" do
      tex = SFML::Texture.from_image(described_class.new(2, 2))
      expect { tex.update("nope") }.to raise_error(ArgumentError, /SFML::Image/)
    end
  end
end
