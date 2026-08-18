///|
test "query filters and link chain" {
  let header = telegram_header(1, 0, 1, 0, 86, 500, 0)
  let packet = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    0,
    [gradient_section(40, false, 2)],
  )
  let telegram = try! parse_telegram(
    try! encode_telegram(short_form(), header, [packet]),
    short_form(),
  )
  inspect(matches_query(query_country(86), telegram), content="true")
  inspect(matches_query(query_group(86, 999), telegram), content="false")
  inspect(
    matches_query(query_packet_id(packet_gradient_id()), telegram),
    content="true",
  )
  let filtered = filter_telegrams(query_all(), [telegram])
  inspect(filtered.length(), content="1")
}

///|
test "schema exposes packet offsets" {
  let schema = packet_schema(packet_gradient_id())
  inspect(schema_summary(schema), content="Gradient(21) fields=8 core_width=54")
  let gradient_field = schema_field(schema, "D_GRADIENT").unwrap()
  inspect(gradient_field.offset, content="30")
  inspect(gradient_field.width, content="15")
  let mask = schema_mask(schema, "G_A").unwrap()
  inspect(mask.length(), content="54")
  inspect(mask.count_ones(), content="8")
  inspect(schema_has_field(schema, "G_A"), content="true")
  inspect(schema_field_end(schema, "G_A").unwrap(), content="54")
  inspect(schema_value_valid(schema, "G_A", 255), content="true")
  inspect(schema_value_valid(schema, "G_A", 256), content="false")
  inspect(schema_repeated_count(schema), content="3")
}

///|
test "unknown schema keeps the common envelope" {
  let schema = packet_schema(200)
  inspect(schema_summary(schema), content="Unknown(200) fields=3 core_width=23")
  inspect(schema_width(schema), content="23")
  inspect(schema_has_field(schema, "V_MAIN"), content="false")
  inspect(schema_value_valid(schema, "V_MAIN", 1), content="false")
}
