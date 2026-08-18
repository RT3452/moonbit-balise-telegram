///|
/// Query objects keep command-line and future JSON adapters independent from
/// the concrete storage used by `BaliseTelegram`.
pub struct TelegramQuery {
  country : Int?
  group : Int?
  packet_id : Int?
  direction : PacketDirection?
}

///|
pub fn query_all() -> TelegramQuery {
  { country: None, group: None, packet_id: None, direction: None }
}

///|
pub fn query_country(country : Int) -> TelegramQuery {
  { country: Some(country), group: None, packet_id: None, direction: None }
}

///|
pub fn query_group(country : Int, group : Int) -> TelegramQuery {
  {
    country: Some(country),
    group: Some(group),
    packet_id: None,
    direction: None,
  }
}

///|
pub fn query_packet_id(id : Int) -> TelegramQuery {
  { country: None, group: None, packet_id: Some(id), direction: None }
}

///|
pub fn query_direction(direction : PacketDirection) -> TelegramQuery {
  { country: None, group: None, packet_id: None, direction: Some(direction) }
}

///|
fn directions_equal(left : PacketDirection, right : PacketDirection) -> Bool {
  match (left, right) {
    (PacketDirection::Nominal, PacketDirection::Nominal) => true
    (PacketDirection::Reverse, PacketDirection::Reverse) => true
    (PacketDirection::Both, PacketDirection::Both) => true
    (PacketDirection::Unknown(a), PacketDirection::Unknown(b)) => a == b
    _ => false
  }
}

///|
pub fn matches_query(query : TelegramQuery, telegram : BaliseTelegram) -> Bool {
  let country_ok = match query.country {
    None => true
    Some(value) => telegram.header.country == value
  }
  let group_ok = match query.group {
    None => true
    Some(value) => telegram.header.group == value
  }
  let packet_ok = match query.packet_id {
    None => true
    Some(value) => has_packet(telegram.packets, value)
  }
  let direction_ok = match query.direction {
    None => true
    Some(direction) => {
      let mut matched = false
      for packet in telegram.packets {
        match packet {
          Packet::Linking(value) =>
            matched = matched ||
              directions_equal(value.header.direction, direction)
          Packet::MovementAuthority(value) =>
            matched = matched ||
              directions_equal(value.header.direction, direction)
          Packet::Gradient(value) =>
            matched = matched ||
              directions_equal(value.header.direction, direction)
          Packet::StaticSpeed(value) =>
            matched = matched ||
              directions_equal(value.header.direction, direction)
          Packet::Unknown(header, _) =>
            matched = matched || directions_equal(header.direction, direction)
          Packet::End => ()
        }
      }
      matched
    }
  }
  country_ok && group_ok && packet_ok && direction_ok
}

///|
pub fn filter_telegrams(
  query : TelegramQuery,
  telegrams : Array[BaliseTelegram],
) -> Array[BaliseTelegram] {
  let result = []
  for telegram in telegrams {
    if matches_query(query, telegram) {
      result.push(telegram)
    }
  }
  result
}

///|
/// A resolved route step, useful for visualizers and replay logs.
pub struct LinkChainStep {
  source : Int
  target : Int
  country : Int
  group : Int
  distance : Int
  status : LinkResolution
}

///|
pub fn resolved_link_chain(group : BaliseGroup) -> Array[LinkChainStep] {
  let result = []
  for report in group.resolve_links() {
    let distance = 0
    let status = report.resolution
    match status {
      LinkResolution::Matched(source, target) =>
        result.push({
          source,
          target,
          country: report.target_country,
          group: report.target_group,
          distance,
          status,
        })
      LinkResolution::Unmatched(country, target_group) =>
        result.push({
          source: report.source_ordinal,
          target: -1,
          country,
          group: target_group,
          distance,
          status,
        })
      LinkResolution::Ambiguous(country, target_group) =>
        result.push({
          source: report.source_ordinal,
          target: -1,
          country,
          group: target_group,
          distance,
          status,
        })
    }
  }
  result
}

///|
pub fn group_summary(group : BaliseGroup) -> String {
  let links = group.resolve_links()
  let mut matched = 0
  let mut unresolved = 0
  let mut ambiguous = 0
  for link in links {
    match link.resolution {
      LinkResolution::Matched(_, _) => matched = matched + 1
      LinkResolution::Unmatched(_, _) => unresolved = unresolved + 1
      LinkResolution::Ambiguous(_, _) => ambiguous = ambiguous + 1
    }
  }
  let mut result = "observations=" + group.count().to_string()
  result = result + " matched=" + matched.to_string()
  result = result + " unresolved=" + unresolved.to_string()
  result = result + " ambiguous=" + ambiguous.to_string()
  result
}
