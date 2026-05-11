RSpec.describe SFML::Context do
  it "constructs a headless GL context without raising" do
    ctx = described_class.new
    expect(ctx.handle).not_to be_nil
  end

  it "reports a non-zero active_context_id when made current" do
    ctx = described_class.new
    ctx.active = true
    expect(described_class.active_context_id).to be > 0
    ctx.active = false
  end

  it "exposes the granted ContextSettings" do
    ctx = described_class.new
    expect(ctx.settings).to be_a(SFML::ContextSettings)
  end

  it "looks up GL functions by name" do
    ctx = described_class.new
    ctx.active = true
    ptr = described_class.gl_function("glGetString")
    expect(ptr).not_to be_nil
    ctx.active = false
  end
end
