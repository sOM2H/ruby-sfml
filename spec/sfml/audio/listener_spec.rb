RSpec.describe SFML::Listener do
  # Listener is a global SFML singleton; restore default state after
  # each example so tests don't pollute each other.
  around do |ex|
    saved_pos    = described_class.position
    saved_vol    = described_class.global_volume
    saved_dir    = described_class.direction
    saved_up     = described_class.up_vector
    saved_vel    = described_class.velocity
    saved_cone   = described_class.cone
    ex.run
    described_class.position      = saved_pos
    described_class.global_volume = saved_vol
    described_class.direction     = saved_dir
    described_class.up_vector     = saved_up
    described_class.velocity      = saved_vel
    described_class.cone          = saved_cone
  end

  describe "global_volume" do
    it "defaults to 100" do
      described_class.global_volume = 100
      expect(described_class.global_volume).to eq(100.0)
    end

    it "round-trips a custom value" do
      described_class.global_volume = 65
      expect(described_class.global_volume).to eq(65.0)
    end
  end

  describe "position" do
    it "round-trips a Vector3 / array" do
      described_class.position = [400, 300, 0]
      expect(described_class.position).to eq(SFML::Vector3[400, 300, 0])
    end
  end

  describe "direction / up_vector" do
    it "match SFML defaults out of the box" do
      described_class.direction = [0, 0, -1]
      described_class.up_vector = [0,  1,  0]
      expect(described_class.direction).to eq(SFML::Vector3[0, 0, -1])
      expect(described_class.up_vector).to eq(SFML::Vector3[0, 1, 0])
    end
  end

  describe "velocity" do
    it "round-trips a Vector3 / array" do
      described_class.velocity = [1.5, -2, 0.5]
      expect(described_class.velocity).to eq(SFML::Vector3[1.5, -2, 0.5])
    end
  end

  describe "cone" do
    it "round-trips via SoundCone" do
      cone = SFML::SoundCone.new(inner_angle: 30.0, outer_angle: 90.0, outer_gain: 0.25)
      described_class.cone = cone
      expect(described_class.cone).to eq(cone)
    end

    it "accepts a Hash" do
      described_class.cone = {inner_angle: 60.0, outer_angle: 180.0, outer_gain: 0.5}
      expect(described_class.cone.inner_angle).to eq(60.0)
    end

    it "rejects junk values" do
      expect { described_class.cone = "nope" }
        .to raise_error(ArgumentError, /SoundCone or Hash/)
    end
  end
end
