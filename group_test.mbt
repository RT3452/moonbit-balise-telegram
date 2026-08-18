///|
test "generator and linking resolver" {
  let source_id = balise_identity(1, 200, 0)
  let target_id = balise_identity(1, 100, 0)
  let link_packet = make_linking_packet(
    packet_header(packet_linking_id(), nominal_direction()),
    [linking_section(300, 1, 100, 0, 0, 2)],
  )
  let source = scenario_balise(source_id, [link_packet])
  let target = scenario_balise(target_id, [])
  let fixtures = try! generate_test_case(
    scenario(short_form(), [source, target]),
  )
  inspect(fixtures.length(), content="2")
  let group = new_balise_group(2)
  for fixture in fixtures {
    let parsed_result = try! parse_channel_telegram(fixture.raw, short_form())
    let parsed = parsed_result.unwrap()
    group.add(
      balise_observation(
        fixture.ordinal,
        fixture.identity,
        nominal_direction(),
        parsed,
      ),
    )
  }
  inspect(group.complete(), content="true")
  let reports = group.resolve_links()
  inspect(reports.length(), content="1")
  match reports[0].resolution {
    LinkResolution::Matched(_, target) => inspect(target, content="1")
    _ => fail("link should resolve")
  }
  let order = group.pass_order(true)
  inspect(order.length(), content="2")
  inspect(order[0], content="1")
  inspect(order[1], content="0")
}
