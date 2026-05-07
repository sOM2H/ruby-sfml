RSpec.describe SFML::Network::SocketSelector do
  it "constructs without raising" do
    expect { described_class.new }.not_to raise_error
  end

  describe "#wait timeout" do
    it "returns false when timeout elapses with no activity" do
      sel = described_class.new
      listener = SFML::Network::TcpListener.new
      listener.blocking = false
      raise "couldn't bind" unless listener.listen(port: 0) == :done
      sel.add(listener)

      expect(sel.wait(timeout: 0.05)).to be false
    end
  end

  describe "#wait + #ready? on a TCP handshake" do
    it "lights up the listener when a client connects" do
      listener = SFML::Network::TcpListener.new
      listener.blocking = false
      raise "couldn't bind" unless listener.listen(port: 0) == :done

      port = listener.local_port

      sel = described_class.new
      sel.add(listener)

      # Spin up a client that connects to our listener.
      thread = Thread.new do
        sleep 0.05
        client = SFML::Network::TcpSocket.new
        client.blocking = false
        client.connect(SFML::Network::IpAddress::LOCALHOST, port: port)
        client
      end

      ready = sel.wait(timeout: 1.0)
      expect(ready).to be true
      expect(sel.ready?(listener)).to be true

      thread.join(1)
    end
  end

  describe "input validation" do
    it "rejects non-socket arguments to #add" do
      sel = described_class.new
      expect { sel.add("not a socket") }
        .to raise_error(ArgumentError, /TcpListener, TcpSocket, or UdpSocket/)
    end

    it "rejects bogus timeout types on #wait" do
      sel = described_class.new
      expect { sel.wait(timeout: "soon") }
        .to raise_error(ArgumentError, /SFML::Time, Numeric, or nil/)
    end
  end

  describe "#clear / #remove" do
    it "doesn't raise on add → remove → clear sequence" do
      sel = described_class.new
      udp = SFML::Network::UdpSocket.new
      sel.add(udp)
      sel.remove(udp)
      sel.clear
    end
  end
end
