RSpec.describe SFML::ContextSettings do
  describe ".new defaults" do
    it "everything is zero / default" do
      s = described_class.new
      expect(s.depth_bits).to eq(0)
      expect(s.stencil_bits).to eq(0)
      expect(s.antialiasing).to eq(0)
      expect(s.major_version).to eq(1)
      expect(s.minor_version).to eq(1)
      expect(s.attribute_flags).to eq(0)   # :default
      expect(s.srgb_capable).to be false
    end

    it "accepts antialiasing as the most common knob" do
      s = described_class.new(antialiasing: 4)
      expect(s.antialiasing).to eq(4)
    end

    it "supports custom depth/stencil + GL version" do
      s = described_class.new(depth_bits: 24, stencil_bits: 8,
                              major_version: 3, minor_version: 3)
      expect(s.depth_bits).to eq(24)
      expect(s.stencil_bits).to eq(8)
      expect(s.major_version).to eq(3)
      expect(s.minor_version).to eq(3)
    end

    it "accepts attributes as a Symbol or Array" do
      core  = described_class.new(attributes: :core)
      both  = described_class.new(attributes: [:core, :debug])
      expect(core.attribute_flags).to eq(SFML::C::Window::ContextAttribute::CORE)
      expect(both.attribute_flags).to eq(
        SFML::C::Window::ContextAttribute::CORE | SFML::C::Window::ContextAttribute::DEBUG
      )
    end

    it "rejects unknown attribute names" do
      expect { described_class.new(attributes: :nope) }
        .to raise_error(ArgumentError, /unknown attribute/)
    end
  end

  describe "#to_native + .from_native" do
    it "round-trips through the FFI struct without losing fields" do
      s = described_class.new(antialiasing: 8, depth_bits: 24, stencil_bits: 8,
                              major_version: 3, minor_version: 3,
                              attributes: :core, srgb_capable: true)
      back = described_class.from_native(s.to_native)
      expect(back).to eq(s)
    end

    it "writes the right fields into the CSFML struct" do
      native = described_class.new(antialiasing: 4, depth_bits: 24).to_native
      expect(native[:anti_aliasing_level]).to eq(4)
      expect(native[:depth_bits]).to          eq(24)
      expect(native[:major_version]).to       eq(1)
    end
  end

  describe "value semantics" do
    it "two settings with the same fields are == and hash equal" do
      a = described_class.new(antialiasing: 4)
      b = described_class.new(antialiasing: 4)
      expect(a).to eq(b)
      expect(a.hash).to eq(b.hash)
    end

    it "different fields → not equal" do
      a = described_class.new(antialiasing: 4)
      b = described_class.new(antialiasing: 8)
      expect(a).not_to eq(b)
    end

    it "is frozen — kwargs can't be mutated post-construction" do
      expect(described_class.new).to be_frozen
    end
  end
end
