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

  describe "array uniforms" do
    let(:array_fragment) do
      <<~GLSL
        uniform float weights[4];
        uniform vec2  positions[3];
        uniform vec3  colors[2];
        uniform vec4  rects[2];
        void main() {
          float w = weights[0] + weights[3];
          vec2  p = positions[0] + positions[2];
          vec3  c = colors[0] + colors[1];
          vec4  r = rects[0] + rects[1];
          gl_FragColor = vec4(w + p.x, c.y, r.z, 1.0);
        }
      GLSL
    end

    let(:shader) { described_class.from_source(fragment: array_fragment) }

    before { skip "no GLSL on this runner" unless described_class.available? }

    it "sets a vec2 array via [[x, y], ...]" do
      expect { shader[:positions] = [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]] }.not_to raise_error
    end

    it "sets a vec3 array via [[x, y, z], ...]" do
      expect { shader[:colors] = [[0.1, 0.2, 0.3], [0.4, 0.5, 0.6]] }.not_to raise_error
    end

    it "sets a vec4 array via [[x, y, z, w], ...]" do
      expect { shader[:rects] = [[0.0, 0.0, 1.0, 1.0], [0.5, 0.5, 0.7, 0.7]] }.not_to raise_error
    end

    it "accepts Vector2 elements interchangeably with [x, y]" do
      expect {
        shader[:positions] = [SFML::Vector2[1.0, 2.0], SFML::Vector2[3.0, 4.0], SFML::Vector2[5.0, 6.0]]
      }.not_to raise_error
    end

    it "accepts Vector3 elements interchangeably with [x, y, z]" do
      expect {
        shader[:colors] = [SFML::Vector3[0.1, 0.2, 0.3], SFML::Vector3[0.4, 0.5, 0.6]]
      }.not_to raise_error
    end

    it "rejects empty array" do
      expect { shader[:positions] = [] }
        .to raise_error(ArgumentError, /must not be empty/)
    end

    it "rejects mixed-length elements" do
      expect { shader[:positions] = [[1.0, 2.0], [3.0, 4.0, 5.0]] }
        .to raise_error(ArgumentError, /same length/)
    end

    it "#set_float_array writes a uniform float[]" do
      expect { shader.set_float_array(:weights, [0.1, 0.2, 0.3, 0.4]) }.not_to raise_error
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

  describe "#bind / .unbind / #native_handle" do
    it "bind / unbind don't raise; native_handle is a positive Integer" do
      next unless described_class.available?

      shader = described_class.from_source(fragment: <<~GLSL)
        uniform float t;
        void main() { gl_FragColor = vec4(t, 0.0, 0.0, 1.0); }
      GLSL

      expect { shader.bind }.not_to raise_error
      expect { described_class.unbind }.not_to raise_error
      expect(shader.native_handle).to be_a(Integer)
      expect(shader.native_handle).to be > 0
    end
  end

  describe "#set_int_color" do
    it "uploads an SFML::Color as a vec4 uniform" do
      next unless described_class.available?

      shader = described_class.from_source(fragment: <<~GLSL)
        uniform vec4 tint;
        void main() { gl_FragColor = tint; }
      GLSL
      expect { shader.set_int_color("tint", SFML::Color.new(255, 128, 0, 200)) }
        .not_to raise_error
    end

    it "rejects non-Color values" do
      next unless described_class.available?

      shader = described_class.from_source(fragment: <<~GLSL)
        uniform vec4 tint;
        void main() { gl_FragColor = tint; }
      GLSL
      expect { shader.set_int_color("tint", "red") }.to raise_error(ArgumentError, /Color/)
    end
  end
end
