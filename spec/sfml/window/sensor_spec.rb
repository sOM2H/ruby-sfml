RSpec.describe SFML::Sensor do
  describe "TYPES" do
    it "lists all six sensor types in CSFML order" do
      expect(described_class::TYPES).to eq(
        %i[accelerometer gyroscope magnetometer gravity user_acceleration orientation],
      )
    end
  end

  describe ".available?" do
    it "returns a boolean for every known sensor type without raising" do
      described_class::TYPES.each do |type|
        expect([true, false]).to include(described_class.available?(type))
      end
    end

    it "raises on unknown sensor symbol" do
      expect { described_class.available?(:nope) }
        .to raise_error(ArgumentError, /Unknown sensor type/)
    end
  end

  describe ".value" do
    it "returns a Vector3 even on hardware without the sensor" do
      expect(described_class.value(:accelerometer)).to be_a(SFML::Vector3)
    end
  end

  describe ".enable / .disable" do
    it "doesn't raise when toggling an unavailable sensor" do
      expect { described_class.enable(:accelerometer) }.not_to raise_error
      expect { described_class.disable(:accelerometer) }.not_to raise_error
    end
  end
end
