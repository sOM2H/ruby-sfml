RSpec.describe SFML::VideoMode do
  it "constructs with width, height, default 32 bpp" do
    m = described_class.new(800, 600)
    expect([m.width, m.height, m.bits_per_pixel]).to eq([800, 600, 32])
  end

  it "exposes size as a Vector2" do
    m = described_class.new(1024, 768)
    expect(m.size).to eq(SFML::Vector2[1024, 768])
  end

  it "round-trips through native struct" do
    m = described_class.new(640, 480, 24)
    native = m.to_native
    round = described_class.from_native(native)
    expect([round.width, round.height, round.bits_per_pixel]).to eq([640, 480, 24])
  end

  it "fetches the desktop mode (live CSFML call)" do
    m = described_class.desktop_mode
    expect(m.width).to be > 0
    expect(m.height).to be > 0
  end

  describe ".fullscreen_modes" do
    it "returns at least one mode" do
      modes = described_class.fullscreen_modes
      expect(modes).not_to be_empty
      expect(modes.first).to be_a(described_class)
    end
  end

  describe "#valid?" do
    it "true for the current desktop mode" do
      expect(described_class.desktop_mode.valid?).to be true
    end

    it "false for nonsense modes" do
      expect(described_class.new(1, 1).valid?).to be false
    end
  end
end
