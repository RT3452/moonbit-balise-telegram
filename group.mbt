///|
/// A stable balise identity used to resolve linking packets.
pub struct BaliseIdentity {
  country : Int
  group : Int
  index : Int
}

///|
pub fn balise_identity(
  country : Int,
  group : Int,
  index : Int,
) -> BaliseIdentity {
  { country, group, index }
}

///|
pub struct BaliseObservation {
  ordinal : Int
  identity : BaliseIdentity
  direction : PacketDirection
  telegram : BaliseTelegram
}

///|
pub fn balise_observation(
  ordinal : Int,
  identity : BaliseIdentity,
  direction : PacketDirection,
  telegram : BaliseTelegram,
) -> BaliseObservation {
  { ordinal, identity, direction, telegram }
}

///|
pub struct BaliseGroup {
  expected_count : Int
  observations : Array[BaliseObservation]
}

///|
pub fn new_balise_group(expected_count : Int) -> BaliseGroup {
  { expected_count, observations: [] }
}

///|
pub(all) suberror GroupError {
  InvalidExpectedCount(Int)
  DuplicateOrdinal(Int)
  TooManyObservations(Int)
}

///|
pub fn GroupError::message(self : GroupError) -> String {
  match self {
    GroupError::InvalidExpectedCount(value) =>
      "invalid group count: " + value.to_string()
    GroupError::DuplicateOrdinal(value) =>
      "duplicate balise ordinal: " + value.to_string()
    GroupError::TooManyObservations(value) =>
      "too many observations: " + value.to_string()
  }
}

///|
/// Add an observation while preserving acquisition order and duplicate checks.
pub fn BaliseGroup::add(
  self : BaliseGroup,
  observation : BaliseObservation,
) -> Unit raise GroupError {
  if self.expected_count <= 0 {
    raise GroupError::InvalidExpectedCount(self.expected_count)
  }
  if self.observations.length() >= self.expected_count {
    raise GroupError::TooManyObservations(self.expected_count)
  }
  for existing in self.observations {
    if existing.ordinal == observation.ordinal {
      raise GroupError::DuplicateOrdinal(observation.ordinal)
    }
  }
  self.observations.push(observation)
}

///|
pub fn BaliseGroup::count(self : BaliseGroup) -> Int {
  self.observations.length()
}

///|
pub fn BaliseGroup::complete(self : BaliseGroup) -> Bool {
  self.observations.length() == self.expected_count
}

///|
pub enum LinkResolution {
  Matched(Int, Int)
  Unmatched(Int, Int)
  Ambiguous(Int, Int)
}

///|
pub struct GroupLinkReport {
  source_ordinal : Int
  target_country : Int
  target_group : Int
  resolution : LinkResolution
}

///|
fn packet_links(telegram : BaliseTelegram) -> Array[LinkingSection] {
  let links = []
  for packet in telegram.packets {
    match packet {
      Packet::Linking(value) => links.append(value.sections)
      _ => ()
    }
  }
  links
}

///|
fn same_identity(left : BaliseIdentity, country : Int, group : Int) -> Bool {
  left.country == country && left.group == group
}

///|
fn resolve_one(
  source : BaliseObservation,
  link : LinkingSection,
  observations : Array[BaliseObservation],
) -> LinkResolution {
  let matches = []
  for candidate in observations {
    if same_identity(candidate.identity, link.country, link.group) {
      matches.push(candidate.ordinal)
    }
  }
  if matches.length() == 1 {
    LinkResolution::Matched(source.ordinal, matches[0])
  } else if matches.length() == 0 {
    LinkResolution::Unmatched(link.country, link.group)
  } else {
    LinkResolution::Ambiguous(link.country, link.group)
  }
}

///|
/// Resolve Packet 5 links against every observed identity in the group.
pub fn BaliseGroup::resolve_links(self : BaliseGroup) -> Array[GroupLinkReport] {
  let reports = []
  for source in self.observations {
    for link in packet_links(source.telegram) {
      let resolution = resolve_one(source, link, self.observations)
      reports.push({
        source_ordinal: source.ordinal,
        target_country: link.country,
        target_group: link.group,
        resolution,
      })
    }
  }
  reports
}

///|
/// Return observation ordinals in the physical pass direction.
pub fn BaliseGroup::pass_order(
  self : BaliseGroup,
  reverse : Bool,
) -> Array[Int] {
  let result = []
  if reverse {
    let mut index = self.observations.length() - 1
    while index >= 0 {
      result.push(self.observations[index].ordinal)
      index = index - 1
    }
  } else {
    for observation in self.observations {
      result.push(observation.ordinal)
    }
  }
  result
}

///|
/// A deterministic scenario description used by the test-case generator.
pub struct ScenarioBalise {
  identity : BaliseIdentity
  packets : Array[Packet]
}

///|
pub fn scenario_balise(
  identity : BaliseIdentity,
  packets : Array[Packet],
) -> ScenarioBalise {
  { identity, packets }
}

///|
pub struct Scenario {
  form : TelegramForm
  balises : Array[ScenarioBalise]
  version : Int
}

///|
pub fn scenario(
  form : TelegramForm,
  balises : Array[ScenarioBalise],
) -> Scenario {
  { form, balises, version: 1 }
}

///|
pub struct GeneratedTelegram {
  ordinal : Int
  identity : BaliseIdentity
  logical : BitVector
  raw : BitVector
}

///|
/// Generate a complete deterministic set of raw telegram fixtures.
pub fn generate_test_case(
  scenario : Scenario,
) -> Array[GeneratedTelegram] raise PacketError {
  let generated = []
  let total = scenario.balises.length()
  let mut ordinal = 0
  for item in scenario.balises {
    let header = telegram_header(
      scenario.version,
      ordinal,
      total,
      0,
      item.identity.country,
      item.identity.group,
      ordinal,
    )
    let frame_result = encode_telegram_channel(
      scenario.form,
      header,
      item.packets,
    )
    let frame = match frame_result {
      Ok(value) => value
      Err(error) => raise PacketError::InvalidLength(error.message().length())
    }
    generated.push({
      ordinal,
      identity: item.identity,
      logical: frame.logical_data,
      raw: frame.raw(),
    })
    ordinal = ordinal + 1
  }
  generated
}
