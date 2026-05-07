RSpec.describe SFML::Network::IpAddress do
  describe "constants" do
    it "LOCALHOST is 127.0.0.1" do
      expect(described_class::LOCALHOST.to_s).to eq("127.0.0.1")
    end

    it "ANY is 0.0.0.0" do
      expect(described_class::ANY.to_s).to eq("0.0.0.0")
    end

    it "BROADCAST is 255.255.255.255" do
      expect(described_class::BROADCAST.to_s).to eq("255.255.255.255")
    end
  end

  describe ".from_string" do
    it "round-trips a dotted-decimal address" do
      addr = described_class.from_string("192.168.1.42")
      expect(addr.to_s).to eq("192.168.1.42")
    end
  end

  describe ".from_bytes" do
    it "is equivalent to .from_string of the same address" do
      a = described_class.from_bytes(192, 168, 1, 42)
      b = described_class.from_string("192.168.1.42")
      expect(a).to eq(b)
      expect(a.to_s).to eq("192.168.1.42")
    end
  end

  describe "#to_i" do
    it "returns the host-byte-order integer form" do
      addr = described_class.from_string("192.168.1.42")
      expect(addr.to_i).to eq((192 << 24) | (168 << 16) | (1 << 8) | 42)
    end

    it "round-trips through .from_integer" do
      orig = described_class.from_string("10.0.0.1")
      expect(described_class.from_integer(orig.to_i)).to eq(orig)
    end
  end

  describe ".local" do
    it "returns a parseable address" do
      expect(described_class.local.to_s).to match(/\A\d+\.\d+\.\d+\.\d+\z/)
    end
  end

  describe "equality" do
    it "compares by string form" do
      expect(described_class.from_string("1.2.3.4")).to eq(described_class.from_bytes(1, 2, 3, 4))
    end

    it "is hashable" do
      h = { described_class::LOCALHOST => :loopback }
      expect(h[described_class.from_string("127.0.0.1")]).to eq(:loopback)
    end
  end
end
