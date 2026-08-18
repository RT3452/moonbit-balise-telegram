///|
test "packet 21 gradient round trip" {
  let header = packet_header(packet_gradient_id(), nominal_direction())
  let packet = make_gradient_packet(header, 1, [gradient_section(120, true, 8)])
  let encoded = try! encode_packet(packet)
  let parsed = try! parse_packet(encoded)
  match parsed {
    Packet::Gradient(value) => {
      inspect(value.sections.length(), content="1")
      inspect(value.sections[0].distance, content="120")
    }
    _ => fail("expected packet 21")
  }
}

///|
test "packet 12 and packet 27 ids" {
  let authority = make_movement_authority_packet(
    packet_header(packet_movement_authority_id(), both_direction()),
    0,
    [authority_section(500, 80, 20)],
  )
  let speed = make_static_speed_packet(
    packet_header(packet_static_speed_id(), reverse_direction()),
    1,
    0,
    [speed_section(250, 60, 1)],
  )
  let authority_bits = try! encode_packet(authority)
  let authority_packet = try! parse_packet(authority_bits)
  let authority_id = match authority_packet {
    Packet::MovementAuthority(value) => value.header.id
    _ => -1
  }
  let speed_bits = try! encode_packet(speed)
  let speed_packet = try! parse_packet(speed_bits)
  let speed_id = match speed_packet {
    Packet::StaticSpeed(value) => value.header.id
    _ => -1
  }
  inspect(authority_id, content="12")
  inspect(speed_id, content="27")
}
