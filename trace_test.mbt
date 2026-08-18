///|
fn trace_fixture() -> Scenario {
  let source_id = balise_identity(1, 200, 0)
  let target_id = balise_identity(1, 100, 0)
  let link_packet = make_linking_packet(
    packet_header(packet_linking_id(), nominal_direction()),
    [linking_section(300, 1, 100, 0, 0, 2)],
  )
  scenario(short_form(), [
    scenario_balise(source_id, [link_packet]),
    scenario_balise(target_id, []),
  ])
}

///|
test "forward and reverse pass reports" {
  let forward = try! simulate_pass(trace_fixture(), forward_pass())
  let reverse = try! simulate_pass(trace_fixture(), reverse_pass())
  inspect(forward.event_count(), content="2")
  inspect(forward.resolved_count(), content="1")
  inspect(reverse.event_count(), content="2")
  inspect(
    pass_report_summary(forward),
    content="forward events=2 matched=1 unresolved=0 ambiguous=0",
  )
}

///|
test "safety assessment exposes overspeed" {
  let header = telegram_header(1, 0, 1, 0, 1, 2, 0)
  let packet = make_static_speed_packet(
    packet_header(packet_static_speed_id(), nominal_direction()),
    0,
    0,
    [speed_section(200, 40, 0)],
  )
  let payload = try! encode_telegram(short_form(), header, [packet])
  let telegram = try! parse_telegram(payload, short_form())
  let samples = assess_speed_profile(telegram, 60)
  inspect(samples.length(), content="1")
  match samples[0].status {
    SafetyStatus::Overspeed => ()
    _ => fail("expected overspeed")
  }
}
