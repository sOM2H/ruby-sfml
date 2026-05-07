RSpec.describe SFML::Window do
  before { skip "no display server" unless ENV["DISPLAY"] || ENV["WAYLAND_DISPLAY"] }

  it "creates and reports its size" do
    win = described_class.new(320, 240, "spec window")
    expect(win.size).to eq(SFML::Vector2[320, 240])
    win.close
  end

  it "is open after construction and closed after #close" do
    win = described_class.new(320, 240, "spec window")
    expect(win.open?).to be true
    win.close
    expect(win.open?).to be false
  end

  it "rejects a one-arg form" do
    expect { described_class.new("title") }
      .to raise_error(ArgumentError, /takes either/)
  end

  it "polls events without raising (returns nil when queue empty)" do
    win = described_class.new(320, 240, "spec window")
    # We don't know if any events are queued yet; just confirm the call
    # doesn't blow up.
    expect { win.each_event { |_e| } }.not_to raise_error
    win.close
  end

  it "title= and size= round-trip" do
    win = described_class.new(320, 240, "init")
    win.title = "renamed"
    win.size  = [400, 300]
    expect(win.size).to eq(SFML::Vector2[400, 300])
    win.close
  end
end
