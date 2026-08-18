///|
test "hex and byte adapters" {
  let bits = BitVector::from_hex("A5:0F").unwrap()
  inspect(bits.length(), content="16")
  inspect(bits.to_hex(), content="A50F")
  let bytes = bits.to_bytes()
  inspect(bytes.length(), content="2")
  inspect(bytes[0], content="165")
  inspect(bytes[1], content="15")
  inspect(bits.count_ones(), content="8")
  inspect(bits.hamming_distance(bits.invert()), content="16")
}

///|
test "reader seek and crc adapter" {
  let bits = BitVector::from_string("10110101011").unwrap()
  let reader = BitReader::new(bits)
  inspect(reader.read_uint_at(1, 4).unwrap(), content="6")
  inspect(reader.position(), content="0")
  inspect(crc16_ccitt(bits, 65535), content="33811")
}
