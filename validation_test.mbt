///|
test "validation reports clean and damaged frames" {
  let header = telegram_header(1, 0, 1, 0, 1, 2, 0)
  let packet = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    0,
    [gradient_section(40, false, 2)],
  )
  let frame = (try! encode_telegram_channel(short_form(), header, [packet])).unwrap()
  let clean_report = validate_channel(frame.raw(), short_form())
  inspect(clean_report.is_valid(), content="true")
  let damaged = frame.raw()
  damaged.bits[200] = !damaged.bits[200]
  let damaged_report = validate_channel(damaged, short_form())
  inspect(damaged_report.is_valid(), content="false")
  inspect(damaged_report.error_count(), content="1")
}

///|
test "semantic packet validation catches field ranges" {
  let packet = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    0,
    [gradient_section(40000, true, 300)],
  )
  let report = validate_packet(packet)
  inspect(report.is_valid(), content="false")
  inspect(report.error_count(), content="2")
}

///|
test "telegram summary and packet ids" {
  let header = telegram_header(1, 0, 1, 0, 86, 1200, 0)
  let packet = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    1,
    [gradient_section(120, true, 8)],
  )
  let payload = try! encode_telegram(long_form(), header, [packet])
  let telegram = try! parse_telegram(payload, long_form())
  let report = validate_telegram(telegram)
  inspect(report.is_valid(), content="true")
  inspect(packet_ids(telegram)[0], content="21")
  inspect(
    telegram_summary(telegram),
    content="balise=86:1200 packets=1 bits=830",
  )
}
