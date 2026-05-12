RSpec.describe SFML::Animation do
  let(:texture) do
    img = SFML::Image.from_pixels(4, 2, "\xff\x00\x00\xff" * 8)
    SFML::Texture.from_image(img)
  end

  let(:frames) do
    [
      SFML::Rect.new([0, 0], [2, 2]),
      SFML::Rect.new([2, 0], [2, 2]),
    ]
  end

  it "constructs from a Texture + frame list" do
    anim = described_class.new(texture, frames: frames, fps: 2)
    expect(anim).to be_a(described_class)
    expect(anim.duration).to eq(1.0)
    expect(anim.frame_index).to eq(0)
  end

  it "accepts SFML::Time or seconds for #update" do
    anim = described_class.new(texture, frames: frames, fps: 2)
    expect { anim.update(SFML::Time.milliseconds(100)) }.not_to raise_error
    expect { anim.update(0.1) }.not_to raise_error
  end

  it "advances frame_index over time" do
    anim = described_class.new(texture, frames: frames, fps: 2)
    anim.update(0.6)
    expect(anim.frame_index).to eq(1)
    anim.update(0.6)   # wraps because loop: true (default)
    expect(anim.frame_index).to eq(0)
    expect(anim.done?).to be false
  end

  it "stops at the last frame when loop: false" do
    anim = described_class.new(texture, frames: frames, fps: 2, loop: false)
    anim.update(2.0)   # well past the end
    expect(anim.done?).to be true
    expect(anim.frame_index).to eq(1)
  end

  it "#reset rewinds to the first frame" do
    anim = described_class.new(texture, frames: frames, fps: 2)
    anim.update(0.6)
    anim.reset
    expect(anim.frame_index).to eq(0)
    expect(anim.done?).to be false
  end

  it "exposes Sprite-style transform setters" do
    anim = described_class.new(texture, frames: frames, fps: 2)
    anim.position = [50, 100]
    expect(anim.position).to eq(SFML::Vector2[50, 100])
    anim.rotation = 45
    expect(anim.rotation).to be_within(1e-3).of(45.0)
  end

  it "responds to draw_on for the drawable interface" do
    anim = described_class.new(texture, frames: frames, fps: 2)
    expect(anim).to respond_to(:draw_on)
  end

  it "raises if frames is empty" do
    expect { described_class.new(texture, frames: [], fps: 1) }
      .to raise_error(ArgumentError, /at least one frame/)
  end

  it "rejects non-Texture/SpriteSheet/TextureAtlas sources" do
    expect { described_class.new(:not_a_source, frames: frames, fps: 1) }
      .to raise_error(ArgumentError, /must be Texture/)
  end
end
