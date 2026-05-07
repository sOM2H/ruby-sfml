RSpec.describe "RenderTarget#draw_primitives" do
  let(:rt) { SFML::RenderTexture.new(32, 32) }

  it "draws a coloured triangle and the colours land on the readback" do
    rt.clear(SFML::Color.black)
    rt.draw_primitives(
      [
        SFML::Vertex.new([0, 0],   color: SFML::Color.red),
        SFML::Vertex.new([30, 0],  color: SFML::Color.red),
        SFML::Vertex.new([15, 30], color: SFML::Color.red),
      ],
      :triangles,
    )
    rt.display

    img = rt.texture.to_image
    # Centre of the triangle should be solid red.
    centre = img[15, 10]
    expect(centre.r).to be > 200
    expect(centre.g).to be < 50
    expect(centre.b).to be < 50
  end

  it "rejects unknown primitive types" do
    expect {
      rt.draw_primitives([SFML::Vertex.new([0, 0])], :hexagons)
    }.to raise_error(ArgumentError, /Unknown primitive type/)
  end

  it "honors render-state shortcut kwargs" do
    rt.clear(SFML::Color.black)
    expect {
      rt.draw_primitives(
        [SFML::Vertex.new([0, 0]), SFML::Vertex.new([30, 30])],
        :lines,
        blend_mode: SFML::BlendMode::ADD,
      )
    }.not_to raise_error
    rt.display
  end

  it "accepts an empty vertex array (no-op)" do
    expect { rt.draw_primitives([], :points) }.not_to raise_error
  end
end
