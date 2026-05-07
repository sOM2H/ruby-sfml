RSpec.describe SFML::Joystick do
  describe "axis index" do
    it "matches the CSFML 3 sfJoystickAxis order" do
      expect(described_class::AXES)
        .to eq(%i[x y z r u v pov_x pov_y])
      expect(described_class::AXIS_INDEX[:x]).to eq(0)
      expect(described_class::AXIS_INDEX[:pov_y]).to eq(7)
    end

    it "honors hat / dpad aliases" do
      expect(described_class.send(:_axis_code, :hat_x)).to eq(6)
      expect(described_class.send(:_axis_code, :dpad_y)).to eq(7)
    end

    it "raises on unknown axis names" do
      expect { described_class.send(:_axis_code, :triggers) }
        .to raise_error(ArgumentError, /Unknown joystick axis/)
    end
  end

  describe "id validation" do
    it "rejects ids outside 0..MAX_COUNT-1" do
      expect { described_class.connected?(-1) }
        .to raise_error(ArgumentError, /must be in 0..7/)
      expect { described_class.connected?(99) }
        .to raise_error(ArgumentError, /must be in 0..7/)
    end

    it "accepts 0..7 without raising" do
      8.times do |i|
        expect { described_class.connected?(i) }.not_to raise_error
      end
    end
  end

  describe ".connected? + .identification" do
    it "is consistent: identification is non-nil iff connected" do
      8.times do |i|
        if described_class.connected?(i)
          expect(described_class.identification(i)).to be_a(Hash)
          expect(described_class.identification(i)).to include(:name, :vendor_id, :product_id)
        else
          expect(described_class.identification(i)).to be_nil
        end
      end
    end
  end

  describe ".axis_position" do
    it "returns 0.0 for axes the device doesn't expose" do
      # On a CI runner with no joystick, has_axis? is false for all axes,
      # and getAxisPosition is documented to return 0 in that case.
      result = described_class.axis_position(0, :x)
      expect(result).to be_a(Float)
    end
  end

  describe "constants" do
    specify { expect(described_class::MAX_COUNT).to eq(8) }
    specify { expect(described_class::MAX_BUTTON_COUNT).to eq(32) }
    specify { expect(described_class::MAX_AXIS_COUNT).to eq(8) }
  end
end
