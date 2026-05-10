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

  describe "cursor + threshold setters" do
    let(:win) { described_class.new(200, 200, "cursor+threshold") }
    after     { win.close if win.open? }

    it "cursor_visible= / cursor_grabbed= don't raise" do
      expect { win.cursor_visible = false }.not_to raise_error
      expect { win.cursor_grabbed = false }.not_to raise_error
    end

    it "joystick_threshold= accepts a float" do
      expect { win.joystick_threshold = 0.1 }.not_to raise_error
    end

    it "rejects a non-Cursor cursor=" do
      expect { win.cursor = :not_a_cursor }
        .to raise_error(ArgumentError, /SFML::Cursor/)
    end
  end

  describe "context_settings" do
    let(:win) { described_class.new(200, 200, "ctx") }
    after     { win.close if win.open? }

    it "returns a SFML::ContextSettings — what the driver actually gave us" do
      expect(win.context_settings).to be_a(SFML::ContextSettings)
    end
  end

  describe "#wait_event" do
    let(:win) { described_class.new(200, 200, "wait") }
    after     { win.close if win.open? }

    it "returns nil when no event arrives within the timeout" do
      win.each_event.to_a   # drain creation events
      expect(win.wait_event(timeout: SFML::Time.milliseconds(1))).to be_nil
    end
  end
end
