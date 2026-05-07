RSpec.describe SFML::StencilMode do
  describe ".new" do
    it "defaults to a pass-through mode" do
      m = described_class.new
      expect(m.comparison).to eq(:always)
      expect(m.update_operation).to eq(:keep)
      expect(m.reference).to eq(0)
      expect(m.mask).to eq(0xFFFFFFFF)
      expect(m.only_write_mask).to be false
    end

    it "accepts every comparison and update_operation value" do
      SFML::StencilMode::COMPARISONS.each do |c|
        SFML::StencilMode::OPERATIONS.each do |op|
          expect { described_class.new(comparison: c, update_operation: op) }
            .not_to raise_error
        end
      end
    end

    it "rejects unknown comparison" do
      expect { described_class.new(comparison: :nonsense) }
        .to raise_error(ArgumentError, /comparison/)
    end

    it "rejects unknown update_operation" do
      expect { described_class.new(update_operation: :nope) }
        .to raise_error(ArgumentError, /update_operation/)
    end
  end

  describe "round-trip through populate / from_native" do
    it "preserves all six fields" do
      m = described_class.new(
        comparison: :equal, update_operation: :replace,
        reference: 7, mask: 0x0F0F0F0F, only_write_mask: true,
      )
      buf = SFML::C::Graphics::StencilMode.new
      m.populate(buf)
      back = described_class.from_native(buf)
      expect(back).to eq(m)
    end
  end

  describe "RenderStates integration" do
    it "carries stencil_mode through to_native_pointer without raising" do
      mode = described_class.new(comparison: :equal, reference: 1)
      states = SFML::RenderStates.new(stencil_mode: mode)
      expect { states.to_native_pointer }.not_to raise_error
    end
  end

  describe "RenderTarget#clear with stencil:" do
    it "clears with colour + stencil on a RenderTexture (no display required)" do
      rt = SFML::RenderTexture.new(8, 8)
      expect { rt.clear(SFML::Color.black, stencil: 0) }.not_to raise_error
      expect { rt.clear(stencil: 1) }.not_to raise_error
    end
  end
end
