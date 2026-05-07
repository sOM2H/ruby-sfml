RSpec.describe SFML::Network::UdpSocket do
  it "constructs without raising" do
    expect(described_class.new).to be_a(described_class)
  end

  describe "loopback round-trip" do
    it "send + receive moves bytes between two sockets on this host" do
      receiver = described_class.new
      receiver.blocking = false
      expect(receiver.bind(port: 0)).to eq(:done)
      expect(receiver.local_port).to be > 0

      sender = described_class.new
      expect(sender.send("hello UDP",
                         to: SFML::Network::IpAddress::LOCALHOST,
                         port: receiver.local_port)).to eq(:done)

      # Datagrams may not arrive instantly — poll briefly.
      bytes = nil; sip = nil
      20.times do
        status, b, ip, _port = receiver.receive(max: 64)
        if status == :done
          bytes = b; sip = ip
          break
        end
        sleep 0.01
      end

      expect(bytes).to eq("hello UDP")
      expect(sip).to eq(SFML::Network::IpAddress::LOCALHOST)
    end
  end

  describe "non-blocking receive on an empty socket" do
    it "returns :not_ready instead of hanging" do
      sock = described_class.new
      sock.blocking = false
      sock.bind(port: 0)
      status, _bytes, _ip, _port = sock.receive(max: 64)
      expect(status).to eq(:not_ready)
    end
  end

  describe "blocking?" do
    it "defaults to true and toggles" do
      sock = described_class.new
      expect(sock.blocking?).to be true
      sock.blocking = false
      expect(sock.blocking?).to be false
    end
  end
end
