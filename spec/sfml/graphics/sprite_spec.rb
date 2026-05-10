RSpec.describe SFML::Sprite do
  let(:texture) { SFML::Texture.create(8, 8) }

  describe ".new" do
    it "constructs from a Texture" do
      sprite = described_class.new(texture)
      expect(sprite).to be_a(described_class)
    end
  end

  describe "#texture" do
    it "returns the bound (borrowed) Texture" do
      sprite = described_class.new(texture)
      expect(sprite.texture).to be_a(SFML::Texture)
    end
  end

  describe "#transform / #inverse_transform" do
    it "return SFML transform structs" do
      sprite = described_class.new(texture)
      expect(sprite.transform).to be_a(SFML::C::Graphics::Transform)
      expect(sprite.inverse_transform).to be_a(SFML::C::Graphics::Transform)
    end
  end

  describe "#dup" do
    it "produces an independent Sprite handle" do
      a = described_class.new(texture)
      b = a.dup
      expect(b).to be_a(described_class)
      expect(b.handle).not_to eq(a.handle)
    end
  end
end
