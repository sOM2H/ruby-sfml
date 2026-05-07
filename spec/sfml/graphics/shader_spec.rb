RSpec.describe SFML::Shader do
  let(:trivial_fragment) do
    <<~GLSL
      uniform float t;
      uniform vec2  v2;
      uniform vec3  v3;
      uniform vec4  v4;
      uniform vec4  tint;
      uniform sampler2D tex;
      uniform bool  flag;
      void main() {
        gl_FragColor = vec4(t, v2.x, v3.y, v4.w) * tint * (flag ? 1.0 : 0.5)
                       + texture2D(tex, gl_TexCoord[0].xy) * 0.0;
      }
    GLSL
  end

  describe ".available?" do
    it "returns a boolean (true on hardware that supports GLSL)" do
      expect([true, false]).to include(described_class.available?)
    end
  end

  describe ".from_source" do
    it "compiles a fragment-only shader" do
      skip "no GLSL on this runner" unless described_class.available?
      shader = described_class.from_source(fragment: trivial_fragment)
      expect(shader).to be_a(described_class)
    end

    it "raises when neither vertex nor fragment is given" do
      expect { described_class.from_source }
        .to raise_error(ArgumentError, /at least one/)
    end

    it "raises with a clear message on invalid GLSL" do
      skip "no GLSL on this runner" unless described_class.available?
      expect { described_class.from_source(fragment: "this is not GLSL!") }
        .to raise_error(SFML::Error, /createFromMemory failed/)
    end
  end

  describe ".from_file" do
    it "raises on a missing file" do
      skip "no GLSL on this runner" unless described_class.available?
      expect { described_class.from_file(fragment: "/nope/missing.frag") }
        .to raise_error(SFML::Error, /createFromFile failed/)
    end

    it "raises when no kwargs given" do
      expect { described_class.from_file }
        .to raise_error(ArgumentError, /at least one/)
    end
  end

  describe "uniform dispatch via #[]=" do
    let(:shader) { described_class.from_source(fragment: trivial_fragment) }

    before { skip "no GLSL on this runner" unless described_class.available? }

    it "accepts Float / Integer / Numeric for float uniforms" do
      expect { shader[:t] = 1.5 }.not_to raise_error
      expect { shader[:t] = 2   }.not_to raise_error
    end

    it "accepts Vector2 for vec2" do
      expect { shader[:v2] = SFML::Vector2[1.0, 2.0] }.not_to raise_error
    end

    it "accepts Vector3 for vec3" do
      expect { shader[:v3] = SFML::Vector3[1, 2, 3] }.not_to raise_error
    end

    it "accepts Color for vec4 (via setColorUniform)" do
      expect { shader[:tint] = SFML::Color.cornflower_blue }.not_to raise_error
    end

    it "accepts a 4-element Array for vec4" do
      expect { shader[:v4] = [0.1, 0.2, 0.3, 0.4] }.not_to raise_error
    end

    it "accepts a 2-element Array for vec2" do
      expect { shader[:v2] = [1.0, 2.0] }.not_to raise_error
    end

    it "accepts true/false for bool" do
      expect { shader[:flag] = true  }.not_to raise_error
      expect { shader[:flag] = false }.not_to raise_error
    end

    it "accepts a Texture for sampler2D" do
      img = SFML::Image.new(4, 4, fill: SFML::Color.red)
      tex = SFML::Texture.from_image(img)
      expect { shader[:tex] = tex }.not_to raise_error
    end

    it "accepts :current_texture symbol" do
      expect { shader[:tex] = :current_texture }.not_to raise_error
    end

    it "rejects strings or other unsupported types" do
      expect { shader[:t] = "foo" }
        .to raise_error(ArgumentError, /must be Numeric/)
    end

    it "rejects arrays of weird length" do
      expect { shader[:v4] = [1.0, 2.0, 3.0, 4.0, 5.0] }
        .to raise_error(ArgumentError, /length 2, 3, or 4/)
    end
  end

  describe "#set_int" do
    it "writes an integer uniform" do
      skip "no GLSL on this runner" unless described_class.available?
      src = "uniform int n; void main() { gl_FragColor = vec4(float(n) / 10.0); }"
      shader = described_class.from_source(fragment: src)
      expect { shader.set_int("n", 5) }.not_to raise_error
    end
  end

  describe "RenderStates integration" do
    it "draws through RenderStates with shader: kwarg" do
      skip "no GLSL on this runner" unless described_class.available?
      shader = described_class.from_source(fragment: trivial_fragment)
      shader[:t]    = 1.0
      shader[:v2]   = [0.0, 0.0]
      shader[:v3]   = [0.0, 0.0, 0.0]
      shader[:v4]   = [0.0, 0.0, 0.0, 0.0]
      shader[:tint] = SFML::Color.white
      shader[:flag] = true

      rt = SFML::RenderTexture.new(16, 16)
      shape = SFML::CircleShape.new(radius: 5, fill_color: SFML::Color.red)
      rt.clear(SFML::Color.black)
      expect { rt.draw(shape, shader: shader) }.not_to raise_error
      rt.display
    end
  end
end
