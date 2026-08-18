///|
/// Deterministic pass direction, independent of Packet Q_DIR.
pub enum PassDirection {
  Forward
  Reverse
}

///|
pub fn forward_pass() -> PassDirection {
  PassDirection::Forward
}

///|
pub fn reverse_pass() -> PassDirection {
  PassDirection::Reverse
}

///|
pub struct TrainProfile {
  max_speed : Int
  acceleration : Int
  braking : Int
}

///|
pub fn train_profile(
  max_speed : Int,
  acceleration : Int,
  braking : Int,
) -> TrainProfile {
  { max_speed, acceleration, braking }
}

///|
/// A single observation in a simulated overrun.
pub struct PassEvent {
  ordinal : Int
  travel_distance : Int
  identity : BaliseIdentity
  packet_count : Int
  matched_links : Int
  unresolved_links : Int
  ambiguous_links : Int
}

///|
pub struct PassReport {
  direction : PassDirection
  events : Array[PassEvent]
  link_reports : Array[GroupLinkReport]
}

///|
pub fn PassReport::event_count(self : PassReport) -> Int {
  self.events.length()
}

///|
pub fn PassReport::resolved_count(self : PassReport) -> Int {
  let mut count = 0
  for report in self.link_reports {
    match report.resolution {
      LinkResolution::Matched(_, _) => count = count + 1
      _ => ()
    }
  }
  count
}

///|
pub fn PassReport::unresolved_count(self : PassReport) -> Int {
  let mut count = 0
  for report in self.link_reports {
    match report.resolution {
      LinkResolution::Unmatched(_, _) => count = count + 1
      _ => ()
    }
  }
  count
}

///|
pub fn PassReport::ambiguous_count(self : PassReport) -> Int {
  let mut count = 0
  for report in self.link_reports {
    match report.resolution {
      LinkResolution::Ambiguous(_, _) => count = count + 1
      _ => ()
    }
  }
  count
}

///|
fn fixture_for(
  fixtures : Array[GeneratedTelegram],
  ordinal : Int,
) -> GeneratedTelegram {
  for fixture in fixtures {
    if fixture.ordinal == ordinal {
      return fixture
    }
  }
  {
    ordinal: -1,
    identity: balise_identity(0, 0, 0),
    logical: BitVector::new(),
    raw: BitVector::new(),
  }
}

///|
fn reports_for(
  reports : Array[GroupLinkReport],
  ordinal : Int,
) -> Array[GroupLinkReport] {
  let result = []
  for report in reports {
    if report.source_ordinal == ordinal {
      result.push(report)
    }
  }
  result
}

///|
fn report_counts(reports : Array[GroupLinkReport]) -> (Int, Int, Int) {
  let mut matched = 0
  let mut unresolved = 0
  let mut ambiguous = 0
  for report in reports {
    match report.resolution {
      LinkResolution::Matched(_, _) => matched = matched + 1
      LinkResolution::Unmatched(_, _) => unresolved = unresolved + 1
      LinkResolution::Ambiguous(_, _) => ambiguous = ambiguous + 1
    }
  }
  (matched, unresolved, ambiguous)
}

///|
/// Simulate a train passing a complete generated balise group.
pub fn simulate_pass(
  scenario : Scenario,
  direction : PassDirection,
) -> PassReport raise PacketError {
  let fixtures = generate_test_case(scenario)
  let group = new_balise_group(fixtures.length())
  for fixture in fixtures {
    let decoded_result = parse_channel_telegram(fixture.raw, scenario.form)
    let decoded = match decoded_result {
      Ok(value) => value
      Err(error) => raise PacketError::InvalidLength(error.message().length())
    }
    group.add(
      balise_observation(
        fixture.ordinal,
        fixture.identity,
        match direction {
          PassDirection::Forward => nominal_direction()
          PassDirection::Reverse => reverse_direction()
        },
        decoded,
      ),
    ) catch {
      error => raise PacketError::InvalidLength(error.message().length())
    }
  }
  let reverse = match direction {
    PassDirection::Forward => false
    PassDirection::Reverse => true
  }
  let order = group.pass_order(reverse)
  let all_reports = group.resolve_links()
  let events = []
  let mut distance = 0
  for ordinal in order {
    let fixture = fixture_for(fixtures, ordinal)
    let local_reports = reports_for(all_reports, ordinal)
    let counts = report_counts(local_reports)
    let decoded_result = parse_channel_telegram(fixture.raw, scenario.form)
    let decoded = match decoded_result {
      Ok(value) => value
      Err(error) => raise PacketError::InvalidLength(error.message().length())
    }
    events.push({
      ordinal,
      travel_distance: distance,
      identity: fixture.identity,
      packet_count: decoded.packets.length(),
      matched_links: counts.0,
      unresolved_links: counts.1,
      ambiguous_links: counts.2,
    })
    distance = distance + 100
  }
  { direction, events, link_reports: all_reports }
}

///|
/// A simple safety pass over Packet 27 speed sections.
pub enum SafetyStatus {
  WithinLimit
  Overspeed
  NoSpeedProfile
}

///|
pub struct SafetySample {
  ordinal : Int
  speed_limit : Int
  actual_speed : Int
  status : SafetyStatus
}

///|
pub fn assess_speed_profile(
  telegram : BaliseTelegram,
  actual_speed : Int,
) -> Array[SafetySample] {
  let samples = []
  let mut ordinal = 0
  for packet in telegram.packets {
    match packet {
      Packet::StaticSpeed(value) =>
        for section in value.sections {
          let status = if actual_speed <= section.speed {
            SafetyStatus::WithinLimit
          } else {
            SafetyStatus::Overspeed
          }
          samples.push({
            ordinal,
            speed_limit: section.speed,
            actual_speed,
            status,
          })
          ordinal = ordinal + 1
        }
      _ => ()
    }
  }
  if samples.length() == 0 {
    samples.push({
      ordinal: 0,
      speed_limit: 0,
      actual_speed,
      status: SafetyStatus::NoSpeedProfile,
    })
  }
  samples
}

///|
/// Produce a stable human-readable report for a command-line tool.
pub fn pass_report_summary(report : PassReport) -> String {
  let direction = match report.direction {
    PassDirection::Forward => "forward"
    PassDirection::Reverse => "reverse"
  }
  let mut result = direction + " events=" + report.event_count().to_string()
  result = result + " matched=" + report.resolved_count().to_string()
  result = result + " unresolved=" + report.unresolved_count().to_string()
  result = result + " ambiguous=" + report.ambiguous_count().to_string()
  result
}
