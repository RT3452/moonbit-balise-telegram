///|
test "bit diff reports ranges" {
  let left = BitVector::from_string("000011110000").unwrap()
  let right = BitVector::from_string("001111010010").unwrap()
  let diff = diff_bits(left, right, 20)
  inspect(diff.same_length, content="true")
  inspect(diff.hamming_distance, content="4")
  inspect(diff.first_difference, content="2")
  let ranges = changed_ranges(diff)
  inspect(format_bit_ranges(ranges), content="2-3,6-6,10-10")
}

///|
test "telegram diff is semantic" {
  let header = telegram_header(1, 0, 1, 0, 1, 2, 0)
  let first_packet = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    0,
    [gradient_section(40, false, 2)],
  )
  let second_packet = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    0,
    [gradient_section(50, false, 2)],
  )
  let first = try! parse_telegram(
    try! encode_telegram(short_form(), header, [first_packet]),
    short_form(),
  )
  let second = try! parse_telegram(
    try! encode_telegram(short_form(), header, [second_packet]),
    short_form(),
  )
  let differences = telegram_diff(first, second)
  inspect(differences.length(), content="1")
  match differences[0] {
    TelegramDifference::PayloadBits => ()
    _ => fail("expected payload bit difference")
  }
}

///|
test "text reports stay compact" {
  let metrics = packet_metrics([])
  inspect(metrics.summary(), content="total=0 unknown=0 payload_bits=0")
  let report = new_validation_report()
  inspect(report.summary(), content="valid=true errors=0 warnings=0")
  let bits = BitVector::from_string("1010").unwrap()
  inspect(frame_digest(bits), content="bits=4 ones=2 hex=A")
}

///|
test "bit diff handles length mismatch and limits" {
  let left = BitVector::from_string("10").unwrap()
  let right = BitVector::from_string("1011").unwrap()
  let diff = diff_bits(left, right, 1)
  inspect(diff.same_length, content="false")
  inspect(diff.hamming_distance, content="2")
  inspect(diff.first_difference, content="-1")
  inspect(diff.changed_positions.length(), content="0")
}
