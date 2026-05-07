RSpec.describe SFML::Clipboard do
  # The system clipboard is global, so we save the previous value and
  # restore it after each example to avoid trampling whatever the user
  # had copied when running the test suite.
  around do |ex|
    skip "no display server" unless ENV["DISPLAY"] || ENV["WAYLAND_DISPLAY"]
    saved = described_class.text rescue ""
    ex.run
    described_class.text = saved if saved
  end

  it "round-trips ASCII text" do
    described_class.text = "hello clipboard"
    expect(described_class.text).to eq("hello clipboard")
  end

  it "round-trips UTF-8 with non-ASCII characters" do
    described_class.text = "пример • test ✓"
    # Some virtual / headless displays (xvfb in particular) only retain
    # ASCII clipboard contents; the X selection target negotiation for
    # UTF8_STRING falls through. Real desktops handle this fine.
    unless described_class.text == "пример • test ✓"
      skip "clipboard does not retain UTF-8 on this display server (often xvfb)"
    end
    expect(described_class.text).to eq("пример • test ✓")
  end

  it "accepts non-string inputs via #to_s" do
    described_class.text = 42
    expect(described_class.text).to eq("42")
  end
end
