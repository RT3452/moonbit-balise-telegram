///|
test "logical telegram with packet sequence" {
  let header = telegram_header(1, 0, 1, 0, 123, 4567, 2)
  let gradient = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    1,
    [gradient_section(120, true, 8)],
  )
  let speed = make_static_speed_packet(
    packet_header(packet_static_speed_id(), nominal_direction()),
    1,
    0,
    [speed_section(250, 60, 1)],
  )
  let payload = try! encode_telegram(long_form(), header, [gradient, speed])
  inspect(payload.length(), content="830")
  let parsed = try! parse_telegram(payload, long_form())
  inspect(parsed.packets.length(), content="2")
}

///|
test "short raw telegram checks its channel" {
  let header = telegram_header(1, 0, 1, 0, 1, 2, 0)
  let packet = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    0,
    [gradient_section(40, false, 2)],
  )
  let frame_result = try! encode_telegram_channel(short_form(), header, [packet])
  let frame = frame_result.unwrap()
  let raw = frame.raw()
  inspect(raw.length(), content="341")
  let decoded = decode_channel(raw, short_form()).unwrap()
  let parsed = try! parse_telegram(decoded.logical_data, short_form())
  inspect(parsed.packets.length(), content="1")
}
