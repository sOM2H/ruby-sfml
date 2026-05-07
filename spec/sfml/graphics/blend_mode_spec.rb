RSpec.describe SFML::BlendMode do
  describe "factor / equation tables" do
    it "FACTORS matches CSFML order" do
      expect(described_class::FACTORS.first(3)).to eq(%i[zero one src_color])
      expect(described_class::FACTORS.length).to eq(10)
    end

    it "EQUATIONS matches CSFML order" do
      expect(described_class::EQUATIONS).to eq(%i[add subtract reverse_subtract min max])
    end
  end

  describe ".new" do
    it "round-trips its six fields" do
      bm = described_class.new(
        color_src: :src_alpha, color_dst: :one, color_eq: :add,
        alpha_src: :one,       alpha_dst: :zero, alpha_eq: :subtract,
      )
      expect(bm.color_src).to eq(:src_alpha)
      expect(bm.color_eq).to eq(:add)
      expect(bm.alpha_dst).to eq(:zero)
      expect(bm.alpha_eq).to eq(:subtract)
    end

    it "rejects unknown factors" do
      expect {
        described_class.new(color_src: :nope, color_dst: :one, color_eq: :add,
                            alpha_src: :one,  alpha_dst: :one, alpha_eq: :add)
      }.to raise_error(ArgumentError, /Unknown blend factor/)
    end

    it "rejects unknown equations" do
      expect {
        described_class.new(color_src: :one, color_dst: :one, color_eq: :nope,
                            alpha_src: :one, alpha_dst: :one, alpha_eq: :add)
      }.to raise_error(ArgumentError, /Unknown blend equation/)
    end

    it "is frozen" do
      expect(described_class::ADD).to be_frozen
    end
  end

  describe "built-in constants (read from CSFML globals)" do
    it "ADD: src_alpha + one with add equation" do
      bm = described_class::ADD
      expect(bm.color_src).to eq(:src_alpha)
      expect(bm.color_dst).to eq(:one)
      expect(bm.color_eq).to  eq(:add)
    end

    it "ALPHA: standard alpha blend" do
      bm = described_class::ALPHA
      expect(bm.color_src).to eq(:src_alpha)
      expect(bm.color_dst).to eq(:one_minus_src_alpha)
    end

    it "NONE: opaque overwrite (one over zero)" do
      bm = described_class::NONE
      expect(bm.color_src).to eq(:one)
      expect(bm.color_dst).to eq(:zero)
    end

    it "MIN / MAX use min / max equations" do
      expect(described_class::MIN.color_eq).to eq(:min)
      expect(described_class::MAX.color_eq).to eq(:max)
    end
  end

  describe "equality" do
    it "compares by value" do
      a = described_class.new(color_src: :one, color_dst: :one, color_eq: :add,
                              alpha_src: :one, alpha_dst: :one, alpha_eq: :add)
      b = described_class.new(color_src: :one, color_dst: :one, color_eq: :add,
                              alpha_src: :one, alpha_dst: :one, alpha_eq: :add)
      expect(a).to eq(b)
      expect(a.hash).to eq(b.hash)
    end
  end
end
