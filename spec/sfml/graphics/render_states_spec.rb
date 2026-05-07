RSpec.describe SFML::RenderStates do
  describe "#to_native_pointer" do
    it "produces a pointer to a 104-byte sfRenderStates struct" do
      rs = described_class.new
      ptr = rs.to_native_pointer
      expect(ptr).to be_a(FFI::Pointer)
      expect(SFML::C::Graphics::RenderStates.size).to eq(104) # blend(24) + stencil(20) + transform(36) + coord(8) + tex(8) + shader(8)
    end

    it "writes blend_mode fields when given" do
      rs  = described_class.new(blend_mode: SFML::BlendMode::ADD)
      ptr = rs.to_native_pointer
      buf = SFML::C::Graphics::RenderStates.new(ptr)
      bm  = buf[:blend_mode]
      expect(bm[:color_src_factor]).to eq(SFML::BlendMode::FACTORS.index(:src_alpha))
      expect(bm[:color_dst_factor]).to eq(SFML::BlendMode::FACTORS.index(:one))
      expect(bm[:color_equation]).to   eq(SFML::BlendMode::EQUATIONS.index(:add))
    end

    it "writes texture pointer when given" do
      rt  = SFML::RenderTexture.new(16, 16)
      tex = rt.texture
      rs  = described_class.new(texture: tex)
      ptr = rs.to_native_pointer
      buf = SFML::C::Graphics::RenderStates.new(ptr)
      expect(buf[:texture].address).to eq(tex.handle.address)
    end

    it "leaves the CSFML default for fields not explicitly set" do
      rs    = described_class.new
      ptr   = rs.to_native_pointer
      buf   = SFML::C::Graphics::RenderStates.new(ptr)
      blend = buf[:blend_mode]
      # Default in CSFML is sfBlendAlpha — src=src_alpha, dst=one_minus_src_alpha
      expect(blend[:color_src_factor]).to eq(SFML::BlendMode::FACTORS.index(:src_alpha))
      expect(blend[:color_dst_factor]).to eq(SFML::BlendMode::FACTORS.index(:one_minus_src_alpha))
    end
  end

  describe "coordinate_type" do
    it "supports :pixels for pixel-space tex_coords (e.g. tilemaps)" do
      rs  = described_class.new(coordinate_type: :pixels)
      ptr = rs.to_native_pointer
      buf = SFML::C::Graphics::RenderStates.new(ptr)
      expect(buf[:coordinate_type]).to eq(described_class::COORDINATE_INDEX[:pixels])
    end

    it "rejects unknown coordinate_type" do
      expect { described_class.new(coordinate_type: :nope) }
        .to raise_error(ArgumentError, /unknown coordinate_type/)
    end
  end

  describe ".from_draw_opts" do
    it "returns nil for empty opts (lets the caller skip allocation)" do
      expect(described_class.from_draw_opts({})).to be_nil
    end

    it "builds a RenderStates from kwargs" do
      rs = described_class.from_draw_opts(blend_mode: SFML::BlendMode::ADD)
      expect(rs).to be_a(described_class)
      expect(rs.blend_mode).to eq(SFML::BlendMode::ADD)
    end
  end

  describe "RenderTarget#draw with shortcut kwargs" do
    let(:rt) { SFML::RenderTexture.new(16, 16) }

    it "draws with blend_mode kwarg without raising" do
      shape = SFML::CircleShape.new(radius: 4, fill_color: SFML::Color.red)
      rt.clear(SFML::Color.black)
      expect { rt.draw(shape, blend_mode: SFML::BlendMode::ADD) }.not_to raise_error
      rt.display
    end

    it "draws a textured VertexArray with texture: kwarg" do
      tileset_img = SFML::Image.new(8, 8, fill: SFML::Color.green)
      tileset     = SFML::Texture.from_image(tileset_img)

      va = SFML::VertexArray.new(:triangles)
      va << SFML::Vertex.new([0, 0],  tex_coords: [0, 0])
      va << SFML::Vertex.new([8, 0],  tex_coords: [8, 0])
      va << SFML::Vertex.new([8, 8],  tex_coords: [8, 8])

      rt.clear(SFML::Color.black)
      expect {
        rt.draw(va, texture: tileset, coordinate_type: :pixels)
      }.not_to raise_error
      rt.display
    end
  end
end
