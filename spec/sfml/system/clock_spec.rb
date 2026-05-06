RSpec.describe SFML::Clock do
  it "returns a non-negative elapsed time" do
    clock = described_class.new
    expect(clock.elapsed_time.as_microseconds).to be >= 0
  end

  it "advances over time" do
    clock = described_class.new
    sleep 0.01
    expect(clock.elapsed_time.as_milliseconds).to be >= 5
  end

  it "restart returns the previous elapsed time and resets" do
    clock = described_class.new
    sleep 0.01
    previous = clock.restart
    expect(previous.as_milliseconds).to be >= 5
    expect(clock.elapsed_time.as_milliseconds).to be < previous.as_milliseconds
  end
end
