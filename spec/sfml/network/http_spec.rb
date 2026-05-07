require "socket"

RSpec.describe SFML::Network::Http do
  # Spin up a one-shot HTTP/1.0 server on a free localhost port,
  # capture the request lines, and respond with whatever the block
  # returns. Tests that need the request payload also get the lines.
  def with_http_server
    server = TCPServer.new("127.0.0.1", 0)
    port   = server.addr[1]
    captured = { lines: [], body: "" }

    server_thread = Thread.new do
      client = server.accept
      while (line = client.gets) && line != "\r\n"
        captured[:lines] << line.chomp
      end
      content_length = captured[:lines].find { |l| l.downcase.start_with?("content-length:") }
                                       &.split(":", 2)&.last&.strip&.to_i
      captured[:body] = client.read(content_length) if content_length && content_length > 0

      response = yield(captured)
      client.write(response)
      client.close
    end

    [port, captured, server_thread]
  ensure
    # Caller is expected to .join the thread and close the server via
    # the after-block in each spec so this method doesn't have to
    # know when the test is done.
  end

  it "GETs a body and reports 200 ok" do
    port, _captured, thread = with_http_server do |_|
      body = "hello sfml\n"
      "HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\nContent-Length: #{body.bytesize}\r\n\r\n#{body}"
    end

    http = described_class.new("127.0.0.1", port: port)
    resp = http.send_request(method: :get, uri: "/")

    expect(resp.status).to eq(200)
    expect(resp.status_symbol).to eq(:ok)
    expect(resp.body.strip).to eq("hello sfml")
    expect(resp.field("Content-Type")).to eq("text/plain")

    thread.join(1)
  end

  it "POSTs a body and the server sees it on the wire" do
    port, captured, thread = with_http_server do |_|
      "HTTP/1.0 201 Created\r\nContent-Length: 0\r\n\r\n"
    end

    http = described_class.new("127.0.0.1", port: port)
    resp = http.send_request(method: :post, uri: "/submit", body: "ping=1")

    expect(resp.status).to eq(201)
    expect(resp.status_symbol).to eq(:created)
    expect(captured[:lines].first).to match(%r{POST /submit HTTP/1\.})
    expect(captured[:body]).to eq("ping=1")

    thread.join(1)
  end

  it "passes custom request fields through" do
    port, captured, thread = with_http_server do |_|
      "HTTP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n"
    end

    http = described_class.new("127.0.0.1", port: port)
    http.send_request(method: :get, uri: "/", fields: {"X-Test" => "yep"})

    expect(captured[:lines]).to include(match(/^x-test: yep/i))
    thread.join(1)
  end

  it "rejects unknown HTTP methods" do
    http = described_class.new("127.0.0.1", port: 1)
    expect { http.send_request(method: :patch) }
      .to raise_error(ArgumentError, /Unknown HTTP method/)
  end

  it "returns connection_failed against an unreachable port" do
    # Port 1 (tcpmux) is almost never open on a normal box.
    http = described_class.new("127.0.0.1", port: 1)
    resp = http.send_request(method: :get, uri: "/", timeout: 0.5)
    expect(resp.status).to be >= 1000
    expect([:connection_failed, :invalid_response]).to include(resp.status_symbol)
  end
end
