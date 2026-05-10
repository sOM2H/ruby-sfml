RSpec.describe SFML::RenderTexture do
  describe ".new" do
    it "constructs with the given size" do
      rt = described_class.new(120, 80)
      expect(rt.size).to eq(SFML::Vector2[120, 80])
    end

    it "defaults to smooth: false, repeated: false" do
      rt = described_class.new(64, 64)
      expect(rt.smooth?).to be false
      expect(rt.repeated?).to be false
    end

    it "honors smooth + repeated kwargs" do
      rt = described_class.new(64, 64, smooth: true, repeated: true)
      expect(rt.smooth?).to be true
      expect(rt.repeated?).to be true
    end
  end

  describe "#texture" do
    it "returns a SFML::Texture matching the RT's size" do
      rt = described_class.new(80, 50)
      tex = rt.texture
      expect(tex).to be_a(SFML::Texture)
      expect(tex.size).to eq(SFML::Vector2[80, 50])
    end

    it "is memoised — repeated calls return the same wrapper" do
      rt = described_class.new(32, 32)
      expect(rt.texture).to be(rt.texture)
    end
  end

  describe "drawing" do
    let(:rt) { described_class.new(32, 32) }

    it "clears + draws + reads back via to_image" do
      rt.clear(SFML::Color.cornflower_blue)
      shape = SFML::RectangleShape.new(size: [10, 10], position: [5, 5],
                                       fill_color: SFML::Color.red)
      rt.draw(shape)
      rt.display

      img = rt.texture.to_image
      # Pixel inside the painted rectangle should be red.
      expect(img[10, 10]).to eq(SFML::Color.red)
      # Pixel outside the rectangle should be the cornflower-blue clear.
      expect(img[25, 25]).to eq(SFML::Color.cornflower_blue)
    end

    it "supports CircleShape, ConvexShape, Text, VertexArray polymorphically" do
      rt.clear(SFML::Color.black)

      rt.draw(SFML::CircleShape.new(radius: 5, position: [10, 10],
                                    fill_color: SFML::Color.green))
      rt.draw(SFML::ConvexShape.new(points: [[0, 0], [10, 0], [5, 8]],
                                    fill_color: SFML::Color.yellow))
      rt.draw(SFML::Text.new(SFML::Font.default, "x", character_size: 8,
                             fill_color: SFML::Color.white))

      va = SFML::VertexArray.new(:triangles)
      va << SFML::Vertex.new([20, 20], color: SFML::Color.magenta)
      va << SFML::Vertex.new([30, 20], color: SFML::Color.magenta)
      va << SFML::Vertex.new([25, 30], color: SFML::Color.magenta)
      rt.draw(va)

      rt.display
      # If any of the polymorphic dispatch paths broke, we'd have crashed
      # by now. Just confirm the texture is still usable.
      expect(rt.texture).to be_a(SFML::Texture)
    end
  end

  describe "view delegation (via RenderTarget mixin)" do
    it "exposes default_view" do
      rt = described_class.new(64, 64)
      expect(rt.default_view).to be_a(SFML::View)
    end

    it "accepts a custom view via view=" do
      rt = described_class.new(64, 64)
      v = SFML::View.new(center: [16, 16], size: [32, 32])
      rt.view = v
      # We can't compare references because View.from_borrowed copies,
      # but the contents should round-trip.
      expect(rt.view.center).to eq(SFML::Vector2[16, 16])
    end
  end

  describe "metadata" do
    it ".maximum_anti_aliasing_level is non-negative" do
      expect(described_class.maximum_anti_aliasing_level).to be >= 0
    end

    it "#srgb? returns a boolean" do
      rt = described_class.new(64, 64)
      expect([true, false]).to include(rt.srgb?)
    end

    it "#generate_mipmap returns a boolean" do
      rt = described_class.new(64, 64)
      expect([true, false]).to include(rt.generate_mipmap)
    end
  end

  describe "GL interop" do
    it "active=, push/pop/reset GL states don't raise" do
      rt = described_class.new(64, 64)
      expect { rt.active = true; rt.active = false }.not_to raise_error
      expect { rt.push_gl_states; rt.pop_gl_states; rt.reset_gl_states }.not_to raise_error
    end
  end
end
