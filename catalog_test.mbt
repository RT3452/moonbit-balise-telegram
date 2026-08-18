///|
test "packet catalog and cursor" {
  let catalog = packet_catalog()
  inspect(catalog.length(), content="5")
  inspect(packet_descriptor(packet_gradient_id()).name, content="Gradient")
  let packet = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    0,
    [gradient_section(50, true, 3)],
  )
  inspect(packet_name(packet), content="Gradient")
  let bits = try! encode_packet(packet)
  bits.append(encode_packet(end_packet()))
  let packets = try! packet_sequence(bits)
  inspect(packets.length(), content="2")
  inspect(has_packet(packets, packet_gradient_id()), content="true")
  let cursor = packet_cursor(packets)
  inspect(cursor.remaining(), content="2")
  ignore(cursor.next())
  inspect(cursor.remaining(), content="1")
  cursor.rewind()
  inspect(cursor.remaining(), content="2")
}
