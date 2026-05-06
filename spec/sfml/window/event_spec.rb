RSpec.describe SFML::Event do
  it "stores type and immutable data" do
    e = described_class.new(:closed)
    expect(e.type).to eq(:closed)
    expect(e).to be_frozen
    expect(e.data).to be_frozen
  end

  describe "pattern matching" do
    it "matches on type alone" do
      result = case described_class.new(:closed)
               in {type: :closed} then :ok
               end
      expect(result).to eq(:ok)
    end

    it "matches on type plus payload fields" do
      e = described_class.new(:key_pressed, code: :escape, shift: false)
      result = case e
               in {type: :key_pressed, code: :escape} then :ok
               end
      expect(result).to eq(:ok)
    end
  end

  describe "method-style payload access" do
    it "exposes payload keys as methods" do
      e = described_class.new(:resized, size: SFML::Vector2[1024, 768])
      expect(e.size).to eq(SFML::Vector2[1024, 768])
    end

    it "respond_to? agrees with method_missing" do
      e = described_class.new(:resized, size: SFML::Vector2[1024, 768])
      expect(e.respond_to?(:size)).to be true
      expect(e.respond_to?(:not_there)).to be false
    end
  end

  describe ".from_native" do
    it "decodes a :closed event from a fresh buffer" do
      buf = SFML::C::Window::Event.new
      buf[:type] = SFML::C::Window::EVENT_TYPES.index(:closed)
      e = described_class.from_native(buf)
      expect(e.type).to eq(:closed)
      expect(e.data).to eq({})
    end

    it "decodes a :key_pressed event with payload" do
      buf = SFML::C::Window::Event.new
      key = SFML::C::Window::KeyEvent.new(buf.to_ptr)
      key[:type]    = SFML::C::Window::EVENT_TYPES.index(:key_pressed)
      key[:code]    = SFML::Keyboard.symbol_to_code(:escape)
      key[:shift]   = true
      key[:control] = false

      e = described_class.from_native(buf)
      expect(e.type).to eq(:key_pressed)
      expect(e.code).to eq(:escape)
      expect(e.shift).to be true
      expect(e.control).to be false
    end
  end
end
