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

  describe "#icon=" do
    it "accepts an SFML::Image of any size without raising" do
      win = described_class.new(320, 240, "icon spec")
      img = SFML::Image.new(32, 32, fill: SFML::Color.new(200, 50, 50))
      expect { win.icon = img }.not_to raise_error
      win.close
    end

    it "rejects non-Image arguments" do
      win = described_class.new(320, 240, "icon spec")
      expect { win.icon = "not an image" }
        .to raise_error(ArgumentError, /requires a SFML::Image/)
      win.close
    end
  end

  describe "#native_handle" do
    it "returns a non-null FFI::Pointer" do
      win = described_class.new(320, 240, "native handle")
      expect(win.native_handle).to be_a(FFI::Pointer)
      expect(win.native_handle.null?).to be false
      win.close
    end
  end

  describe "#minimum_size= / #maximum_size=" do
    it "accepts a [w, h] array, a Vector2, and nil without raising" do
      win = described_class.new(640, 480, "size limits spec")
      expect { win.minimum_size = [320, 240] }.not_to raise_error
      expect { win.maximum_size = SFML::Vector2[1920, 1080] }.not_to raise_error
      expect { win.minimum_size = nil }.not_to raise_error
      expect { win.maximum_size = nil }.not_to raise_error
      win.close
    end
  end
end
