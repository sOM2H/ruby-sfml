RSpec.describe SFML::Texture do
  describe ".create" do
    it "allocates a blank texture of the requested size" do
      tex = described_class.create(64, 32)
      expect(tex).to be_a(described_class)
      expect(tex.size).to eq(SFML::Vector2.new(64, 32))
    end

    it "raises on absurd sizes" do
      expect { described_class.create(0, 0) }.to raise_error(SFML::Error)
    end
  end

  describe ".maximum_size" do
    it "is a positive integer" do
      expect(described_class.maximum_size).to be_a(Integer).and(be > 0)
    end
  end

  describe "#bind / .unbind" do
    it "accepts :normalized and :pixels coord hints without raising" do
      tex = described_class.create(8, 8)
      expect { tex.bind }.not_to raise_error
      expect { tex.bind(coord: :pixels) }.not_to raise_error
      expect { described_class.unbind }.not_to raise_error
    end

    it "rejects unknown coord values" do
      tex = described_class.create(8, 8)
      expect { tex.bind(coord: :nope) }.to raise_error(ArgumentError)
    end
  end

  describe "#dup" do
    it "produces an independent GPU texture with the same dimensions" do
      a = described_class.create(8, 8)
      b = a.dup
      expect(b).to be_a(described_class)
      expect(b.handle).not_to eq(a.handle)
      expect(b.size).to eq(a.size)
    end
  end

  describe "#srgb? / #generate_mipmap" do
    it "default-created textures aren't sRGB" do
      expect(described_class.create(8, 8).srgb?).to be false
    end

    it "#generate_mipmap returns a boolean" do
      expect([true, false]).to include(described_class.create(8, 8).generate_mipmap)
    end
  end

  describe ".from_memory" do
    it "decodes PNG bytes into a Texture" do
      img   = SFML::Image.from_pixels(2, 2, "\xff\x00\x00\xff" * 4)
      bytes = img.save_to_memory("png")
      tex   = described_class.from_memory(bytes)
      expect(tex.size).to eq(SFML::Vector2.new(2, 2))
    end

    it "raises on garbage bytes" do
      expect { described_class.from_memory("not an image") }.to raise_error(SFML::Error)
    end
  end

  describe "#resize / #swap / #native_handle / #update_from_texture" do
    it "#resize reallocates GPU memory" do
      tex = described_class.create(8, 8)
      expect(tex.resize(64, 32)).to be true
      expect(tex.size).to eq(SFML::Vector2.new(64, 32))
    end

    it "#swap exchanges GPU memory between two textures" do
      a = described_class.create(8, 8)
      b = described_class.create(16, 16)
      a.swap(b)
      expect(a.size).to eq(SFML::Vector2.new(16, 16))
      expect(b.size).to eq(SFML::Vector2.new(8, 8))
    end

    it "#native_handle is a positive Integer (a glGenTextures id)" do
      tex = described_class.create(8, 8)
      expect(tex.native_handle).to be_a(Integer).and(be > 0)
    end

    it "#update_from_texture copies one texture's pixels into another" do
      src = described_class.from_image(SFML::Image.from_pixels(8, 8,
        "\xff\x00\x00\xff" * 64))
      dst = described_class.create(8, 8)
      expect { dst.update_from_texture(src) }.not_to raise_error
    end

    it "rejects non-Texture sources" do
      tex = described_class.create(8, 8)
      expect { tex.update_from_texture(:nope) }.to raise_error(ArgumentError, /Texture/)
    end
  end
end
