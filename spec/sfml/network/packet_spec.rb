RSpec.describe SFML::Network::Packet do
  it "round-trips every typed primitive" do
    p = described_class.new
    p.write_int8(-1).write_uint8(200)
      .write_int16(-1000).write_uint16(60000)
      .write_int32(-100_000).write_uint32(4_000_000_000)
      .write_int64(-10_000_000_000).write_uint64(18_000_000_000_000_000_000)
      .write_float(0.5).write_double(0.123456789)
      .write_bool(true).write_string("hello")

    q = p.dup
    expect(q.read_int8).to    eq(-1)
    expect(q.read_uint8).to   eq(200)
    expect(q.read_int16).to   eq(-1000)
    expect(q.read_uint16).to  eq(60000)
    expect(q.read_int32).to   eq(-100_000)
    expect(q.read_uint32).to  eq(4_000_000_000)
    expect(q.read_int64).to   eq(-10_000_000_000)
    expect(q.read_uint64).to  eq(18_000_000_000_000_000_000)
    expect(q.read_float).to   be_within(1e-6).of(0.5)
    expect(q.read_double).to  be_within(1e-9).of(0.123456789)
    expect(q.read_bool).to    be true
    expect(q.read_string).to  eq("hello")
    expect(q.end_of_packet?).to be true
  end

  it "tracks ok? across reads" do
    p = described_class.new.write_int32(42)
    expect(p.ok?).to be true
    p.read_int32
    expect(p.ok?).to be true
    p.read_int32  # overrun
    expect(p.ok?).to be false
  end

  it "exposes raw data as a binary String" do
    p = described_class.new.write_int32(1)
    expect(p.data.encoding).to eq(Encoding::ASCII_8BIT)
    expect(p.data.bytesize).to eq(4)
  end

  it "clear() drops all bytes" do
    p = described_class.new.write_int32(1).clear
    expect(p.size).to eq(0)
    expect(p.data).to eq("".b)
  end
end
