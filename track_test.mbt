///|
test "track braking envelope" {
  inspect(braking_distance(80, 40, 4), content="600")
  inspect(braking_distance(40, 80, 4), content="0")
  let samples = evaluate_track(demo_track(), train_profile(120, 2, 4), 80)
  inspect(samples.length(), content="4")
  let counts = track_status_counts(samples)
  inspect(counts.0, content="1")
  inspect(counts.1, content="2")
  inspect(counts.2, content="1")
}

///|
test "telegram track evaluation integrates packet 27" {
  let header = telegram_header(1, 0, 1, 0, 1, 2, 0)
  let packet = make_static_speed_packet(
    packet_header(packet_static_speed_id(), nominal_direction()),
    0,
    0,
    [speed_section(200, 30, 0)],
  )
  let payload = try! encode_telegram(short_form(), header, [packet])
  let telegram = try! parse_telegram(payload, short_form())
  let samples = evaluate_telegram_track(
    telegram,
    track_model([track_segment(0, 100, 0, 80)]),
    train_profile(120, 2, 4),
    60,
  )
  inspect(samples.length(), content="1")
  match samples[0].status {
    TrackStatus::Overspeed => ()
    _ => fail("packet 27 should tighten the track sample")
  }
}
