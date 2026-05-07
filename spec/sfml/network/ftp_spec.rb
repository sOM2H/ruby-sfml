RSpec.describe SFML::Network::Ftp do
  it "constructs without raising" do
    expect { described_class.new }.not_to raise_error
  end

  describe "#connect" do
    it "returns a Response with a connection-failed status against an unreachable port" do
      ftp = described_class.new
      # Port 1 is almost never an FTP server.
      response = ftp.connect("127.0.0.1", port: 1, timeout: 0.5)
      expect(response).to be_a(SFML::Network::Ftp::Response)
      expect(response.ok?).to be false
      expect(response.status).to be >= 1000
      expect([:connection_failed, :invalid_response]).to include(response.status_symbol)
    end
  end

  describe "transfer-mode validation" do
    let(:ftp) { described_class.new }

    it "rejects unknown transfer modes for #download" do
      expect { ftp.download("a", "b", mode: :nope) }
        .to raise_error(ArgumentError, /Unknown FTP transfer mode/)
    end

    it "rejects unknown transfer modes for #upload" do
      expect { ftp.upload("a", "b", mode: :weird) }
        .to raise_error(ArgumentError, /Unknown FTP transfer mode/)
    end
  end

  describe "Ftp::Response" do
    it "exposes ok?, status, status_symbol, message after a failed connect" do
      ftp = described_class.new
      r = ftp.connect("127.0.0.1", port: 1, timeout: 0.5)
      expect([true, false]).to include(r.ok?)
      expect(r.status).to be_a(Integer)
      expect(r.status_symbol).to be_a(Symbol).or be_a(Integer)
      expect(r.message).to be_a(String)
    end
  end
end
