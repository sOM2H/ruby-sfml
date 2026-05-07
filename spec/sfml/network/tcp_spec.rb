RSpec.describe "TCP listener + socket" do
  it "completes a non-blocking accept + connect handshake on localhost" do
    listener = SFML::Network::TcpListener.new
    listener.blocking = false
    expect(listener.listen(port: 0, address: SFML::Network::IpAddress::LOCALHOST)).to eq(:done)
    port = listener.local_port
    expect(port).to be > 0

    client = SFML::Network::TcpSocket.new
    client.blocking = false
    # First connect attempt typically returns :not_ready (handshake in flight).
    initial = client.connect(SFML::Network::IpAddress::LOCALHOST, port: port)
    expect(%i[done not_ready]).to include(initial)

    # Poll the listener until it sees the connection.
    peer = nil
    50.times do
      status, sock = listener.accept
      if status == :done
        peer = sock
        break
      end
      sleep 0.01
    end
    expect(peer).to be_a(SFML::Network::TcpSocket)

    # Round-trip a payload.
    50.times do
      break if client.send("hi from client") == :done
      sleep 0.01
    end

    received = nil
    50.times do
      status, bytes = peer.receive(max: 64)
      if status == :done
        received = bytes
        break
      end
      sleep 0.01
    end
    expect(received).to eq("hi from client")
  end

  it "TcpSocket and TcpListener default to blocking" do
    expect(SFML::Network::TcpSocket.new.blocking?).to be true
    expect(SFML::Network::TcpListener.new.blocking?).to be true
  end
end
