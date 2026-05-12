RSpec.describe SFML::RenderWindow do
  before { skip "no display server" unless ENV["DISPLAY"] || ENV["WAYLAND_DISPLAY"] }

  describe "#icon=" do
    it "accepts an SFML::Image without raising" do
      win = described_class.new(320, 240, "icon spec")
      img = SFML::Image.new(32, 32, fill: SFML::Color.new(50, 100, 200))
      expect { win.icon = img }.not_to raise_error
      win.close
    end

    it "rejects non-Image arguments" do
      win = described_class.new(320, 240, "icon spec")
      expect { win.icon = :not_an_image }
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

  describe "focus + position" do
    let(:win) { described_class.new(200, 200, "focus+position") }
    after     { win.close if win.open? }

    it "#focused? returns a boolean" do
      expect([true, false]).to include(win.focused?)
    end

    it "#request_focus doesn't raise" do
      expect { win.request_focus }.not_to raise_error
    end

    it "#position returns a SFML::Vector2 in desktop coords" do
      expect(win.position).to be_a(SFML::Vector2)
    end

    it "#position= accepts an Array or a Vector2" do
      expect { win.position = [50, 50] }.not_to raise_error
      expect { win.position = SFML::Vector2[100, 100] }.not_to raise_error
    end
  end

  describe "OS-window state setters" do
    let(:win) { described_class.new(200, 200, "state") }
    after     { win.close if win.open? }

    it "visible= / key_repeat_enabled= / joystick_threshold= don't raise" do
      expect { win.visible = false }.not_to raise_error
      expect { win.key_repeat_enabled = false }.not_to raise_error
      expect { win.joystick_threshold = 5.0 }.not_to raise_error
    end

    it "#srgb? returns a boolean" do
      expect([true, false]).to include(win.srgb?)
    end
  end

  describe "GL interop" do
    let(:win) { described_class.new(200, 200, "gl") }
    after     { win.close if win.open? }

    it "active=, push/pop/reset GL states don't raise" do
      expect { win.active = true; win.active = false }.not_to raise_error
      expect { win.push_gl_states; win.pop_gl_states; win.reset_gl_states }.not_to raise_error
    end
  end

  describe "#wait_event" do
    let(:win) { described_class.new(200, 200, "wait") }
    after     { win.close if win.open? }

    it "returns nil when no event arrives within the timeout" do
      win.each_event.to_a   # drain anything the OS queued at creation
      # 1ms timeout — long enough that CSFML honours it, short
      # enough not to slow the suite.
      expect(win.wait_event(timeout: SFML::Time.milliseconds(1))).to be_nil
    end
  end

  describe "#viewport / #scissor" do
    let(:win) { described_class.new(200, 200, "vp+scissor") }
    after     { win.close if win.open? }

    it "#viewport returns a pixel-space SFML::Rect for the active view" do
      rect = win.viewport
      expect(rect).to be_a(SFML::Rect)
      expect(rect.width).to be > 0
    end

    it "#scissor returns a pixel-space SFML::Rect" do
      expect(win.scissor).to be_a(SFML::Rect)
    end

    it "rejects non-View arguments" do
      expect { win.scissor(:not_a_view) }.to raise_error(ArgumentError, /View/)
    end
  end

  describe "#screenshot / #capture_image" do
    let(:win) { described_class.new(64, 32, "screenshot spec") }
    after     { win.close if win.open? }

    it "#capture_image returns an SFML::Image of the back-buffer" do
      win.clear(SFML::Color.red)
      win.display
      img = win.capture_image
      expect(img).to be_a(SFML::Image)
      expect(img.size).to eq(SFML::Vector2[64, 32])
    end

    it "#screenshot writes a PNG to disk and returns the path" do
      Dir.mktmpdir do |dir|
        win.clear(SFML::Color.green)
        win.display
        path = File.join(dir, "shot.png")
        expect(win.screenshot(path)).to eq(path)
        expect(File.exist?(path)).to be true
        expect(File.size(path)).to be > 0
      end
    end
  end
end
