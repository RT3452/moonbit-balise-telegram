///|
test "unknown packet is queryable and preserved" {
  let header = packet_header(77, nominal_direction())
  let unknown = unknown_packet(
    header,
    BitVector::from_string("10101010").unwrap(),
  )
  inspect(packet_id(unknown), content="77")
  inspect(packet_name(unknown), content="Unknown(77)")
  let report = validate_packet(unknown)
  inspect(report.is_valid(), content="false")
  inspect(report.warning_count(), content="0")
}
