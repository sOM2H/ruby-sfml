RSpec.describe "SFML error hierarchy" do
  it "every domain-specific error inherits from SFML::Error" do
    [
      SFML::LoadError,
      SFML::AudioError,
      SFML::NetworkError,
      SFML::ShaderError,
      SFML::GraphicsError,
      SFML::WindowError,
    ].each do |klass|
      expect(klass.ancestors).to include(SFML::Error)
    end
  end

  it "Texture.load raises LoadError for missing files" do
    expect { SFML::Texture.load("/nope/missing.png") }
      .to raise_error(SFML::LoadError, /Could not load/)
  end

  it "Font.load raises LoadError for missing files" do
    expect { SFML::Font.load("/nope/missing.ttf") }
      .to raise_error(SFML::LoadError, /Could not load font/)
  end

  it "SoundBuffer.load raises LoadError for missing files" do
    expect { SFML::SoundBuffer.load("/nope/missing.wav") }
      .to raise_error(SFML::LoadError, /Could not load sound buffer/)
  end

  it "Music.load raises LoadError for missing files" do
    expect { SFML::Music.load("/nope/missing.ogg") }
      .to raise_error(SFML::LoadError, /Could not load music/)
  end

  it "old-style `rescue SFML::Error` still catches subclasses" do
    expect { SFML::Texture.load("/nope/missing.png") }
      .to raise_error(SFML::Error)
  end
end
