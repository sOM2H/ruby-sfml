RSpec.describe SFML::ParticleSystem do
  it "spawns particles up to the configured max" do
    ps = described_class.new(max: 3)
    5.times { ps.spawn(position: [0, 0], lifetime: 1.0) }
    expect(ps.size).to eq(3)
    expect(ps.full?).to be true
  end

  it "applies gravity over time" do
    ps = described_class.new(max: 10, gravity: [0, 100])
    ps.spawn(position: [0, 0], velocity: [0, 0], lifetime: 5.0)
    ps.update(1.0)
    expect(ps.particles[0].vy).to be_within(1e-6).of(100)
  end

  it "removes dead particles on update" do
    ps = described_class.new(max: 10)
    ps.spawn(position: [0, 0], lifetime: 0.5)
    ps.update(0.6)
    expect(ps.size).to eq(0)
  end

  it "advances position from velocity" do
    ps = described_class.new(max: 10, gravity: [0, 0])
    ps.spawn(position: [0, 0], velocity: [10, 0], lifetime: 5.0)
    ps.update(0.5)
    expect(ps.particles[0].x).to be_within(1e-6).of(5)
  end

  it "#clear drops every live particle" do
    ps = described_class.new(max: 10)
    3.times { ps.spawn(position: [0, 0], lifetime: 1.0) }
    ps.clear
    expect(ps.size).to eq(0)
  end

  it "subclass #update_particle hook fires per particle" do
    klass = Class.new(described_class) do
      attr_reader :hook_calls
      def initialize(**)
        super
        @hook_calls = 0
      end
      def update_particle(_, _); @hook_calls += 1; end
    end
    ps = klass.new(max: 10)
    2.times { ps.spawn(position: [0, 0], lifetime: 1.0) }
    ps.update(0.1)
    expect(ps.hook_calls).to eq(2)
  end

  it "responds to draw_on (Drawable interface)" do
    ps = described_class.new(max: 5)
    ps.spawn(position: [0, 0], lifetime: 1.0)
    expect(ps).to respond_to(:draw_on)
  end
end
