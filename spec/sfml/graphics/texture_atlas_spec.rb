require "json"
require "tempfile"

RSpec.describe SFML::TextureAtlas do
  # Build a tiny atlas image + json descriptor in a tmpdir.
  around do |example|
    Dir.mktmpdir do |dir|
      pixels = "\xff\x00\x00\xff" * 16
      img    = SFML::Image.from_pixels(8, 2, pixels)
      img.save(File.join(dir, "atlas.png"))

      File.write(File.join(dir, "atlas.json"), JSON.generate({
        "frames" => {
          "walk-0.png" => { "frame" => { "x" => 0, "y" => 0, "w" => 2, "h" => 2 }, "duration" => 100 },
          "walk-1.png" => { "frame" => { "x" => 2, "y" => 0, "w" => 2, "h" => 2 }, "duration" => 100 },
          "walk-2.png" => { "frame" => { "x" => 4, "y" => 0, "w" => 2, "h" => 2 }, "duration" => 100 },
          "walk-3.png" => { "frame" => { "x" => 6, "y" => 0, "w" => 2, "h" => 2 }, "duration" => 100 },
        },
        "meta" => { "image" => "atlas.png" },
      }))

      @dir = dir
      example.run
    end
  end

  it "loads frame names and rects from JSON" do
    atlas = described_class.load(File.join(@dir, "atlas.json"))
    expect(atlas.frame_names).to eq(%w[walk-0 walk-1 walk-2 walk-3])
    expect(atlas.region("walk-0")).to eq(SFML::Rect.new([0, 0], [2, 2]))
    expect(atlas.region("walk-3")).to eq(SFML::Rect.new([6, 0], [2, 2]))
  end

  it "accepts frame names with or without the .png extension" do
    atlas = described_class.load(File.join(@dir, "atlas.json"))
    expect(atlas.region("walk-0")).to     eq(atlas.region("walk-0.png"))
  end

  it "exposes per-frame durations when the JSON has them" do
    atlas = described_class.load(File.join(@dir, "atlas.json"))
    expect(atlas.duration("walk-0")).to eq(100)
  end

  it "raises LoadError for unknown frame names" do
    atlas = described_class.load(File.join(@dir, "atlas.json"))
    expect { atlas.region("no-such-frame") }
      .to raise_error(SFML::LoadError, /no frame named/)
  end

  it "raises LoadError when the image file is missing" do
    File.write(File.join(@dir, "broken.json"), JSON.generate({
      "frames" => {}, "meta" => { "image" => "does-not-exist.png" },
    }))
    expect { described_class.load(File.join(@dir, "broken.json")) }
      .to raise_error(SFML::LoadError, /image not found/)
  end

  it "parses Aseprite's json-array format" do
    File.write(File.join(@dir, "array.json"), JSON.generate({
      "frames" => [
        { "filename" => "a.png", "frame" => { "x" => 0, "y" => 0, "w" => 2, "h" => 2 } },
        { "filename" => "b.png", "frame" => { "x" => 2, "y" => 0, "w" => 2, "h" => 2 } },
      ],
      "meta" => { "image" => "atlas.png" },
    }))
    atlas = described_class.load(File.join(@dir, "array.json"))
    expect(atlas.frame_names).to eq(%w[a b])
  end

  it "#sprite returns a Sprite with the frame's texture_rect" do
    atlas  = described_class.load(File.join(@dir, "atlas.json"))
    sprite = atlas.sprite("walk-2")
    expect(sprite.texture_rect).to eq(SFML::Rect.new([4, 0], [2, 2]))
  end

  it "#animation builds an Animation from a frame list" do
    atlas = described_class.load(File.join(@dir, "atlas.json"))
    anim  = atlas.animation(%w[walk-0 walk-1 walk-2 walk-3])
    expect(anim).to be_a(SFML::Animation)
    # With per-frame Aseprite durations of 100ms each, fps should
    # be 10 → 4 frames × 0.1s = 0.4s.
    expect(anim.duration).to be_within(1e-6).of(0.4)
  end

  it "#animation respects an explicit fps:" do
    atlas = described_class.load(File.join(@dir, "atlas.json"))
    anim  = atlas.animation(%w[walk-0 walk-1], fps: 2)
    expect(anim.duration).to eq(1.0)
  end
end
