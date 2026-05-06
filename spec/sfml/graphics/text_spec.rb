RSpec.describe SFML::Text do
  let(:font) { SFML::Font.find("DejaVuSans") || skip("no DejaVuSans on this system") }

  it "round-trips its string through CSFML" do
    text = described_class.new(font, "hello")
    expect(text.string).to eq("hello")
    text.string = "hi"
    expect(text.string).to eq("hi")
  end

  it "applies kwargs at construction" do
    text = described_class.new(font, "x",
      character_size: 32,
      fill_color:     SFML::Color.red,
      outline_color:  SFML::Color.white,
      outline_thickness: 2,
      style:          %i[bold italic],
      position:       [50, 60],
    )
    expect(text.character_size).to eq(32)
    expect(text.fill_color).to eq(SFML::Color.red)
    expect(text.outline_color).to eq(SFML::Color.white)
    expect(text.outline_thickness).to eq(2.0)
    expect(text.style).to contain_exactly(:bold, :italic)
    expect(text.position).to eq(SFML::Vector2[50, 60])
  end

  describe "style accessor" do
    let(:text) { described_class.new(font, "x") }

    it "accepts a single Symbol" do
      text.style = :italic
      expect(text.style).to eq([:italic])
    end

    it "accepts an Array of Symbols" do
      text.style = %i[bold underlined]
      expect(text.style).to contain_exactly(:bold, :underlined)
    end

    it "accepts a raw integer bitmask" do
      text.style = SFML::Text::STYLES[:bold] | SFML::Text::STYLES[:strike_through]
      expect(text.style).to contain_exactly(:bold, :strike_through)
    end

    it "rejects garbage" do
      expect { text.style = "bold" }.to raise_error(ArgumentError)
    end
  end

  it "shares the Transformable mixin" do
    text = described_class.new(font, "x", position: [0, 0])
    text.move([10, 20])
    expect(text.position).to eq(SFML::Vector2[10, 20])
  end

  describe "bounds (live CSFML)" do
    it "local_bounds widens with longer text" do
      short = described_class.new(font, "i", character_size: 32)
      long  = described_class.new(font, "Wide text", character_size: 32)
      expect(long.local_bounds.width).to be > short.local_bounds.width
    end

    it "global_bounds shifts with the position" do
      text = described_class.new(font, "abc", character_size: 24, position: [100, 50])
      gb = text.global_bounds
      expect(gb.x).to be >= 100
      expect(gb.y).to be >= 50
    end
  end
end
