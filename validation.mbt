///|
/// Validation is intentionally separate from decoding: a decoder preserves
/// unknown fields, while a validator tells a test harness what to fix.
pub enum ValidationSeverity {
  Info
  Warning
  Error
}

///|
pub struct ValidationIssue {
  severity : ValidationSeverity
  code : String
  message : String
  bit_offset : Int
}

///|
pub struct ValidationReport {
  issues : Array[ValidationIssue]
}

///|
pub fn new_validation_report() -> ValidationReport {
  { issues: [] }
}

///|
pub fn ValidationReport::add(
  self : ValidationReport,
  severity : ValidationSeverity,
  code : String,
  message : String,
  bit_offset : Int,
) -> Unit {
  self.issues.push({ severity, code, message, bit_offset })
}

///|
pub fn ValidationReport::is_valid(self : ValidationReport) -> Bool {
  for issue in self.issues {
    match issue.severity {
      ValidationSeverity::Error => return false
      _ => ()
    }
  }
  true
}

///|
pub fn ValidationReport::error_count(self : ValidationReport) -> Int {
  let mut count = 0
  for issue in self.issues {
    match issue.severity {
      ValidationSeverity::Error => count = count + 1
      _ => ()
    }
  }
  count
}

///|
pub fn ValidationReport::warning_count(self : ValidationReport) -> Int {
  let mut count = 0
  for issue in self.issues {
    match issue.severity {
      ValidationSeverity::Warning => count = count + 1
      _ => ()
    }
  }
  count
}

///|
fn issue_length(
  report : ValidationReport,
  actual : Int,
  expected : Int,
  label : String,
) -> Unit {
  if actual != expected {
    report.add(
      ValidationSeverity::Error,
      "length",
      label + ": " + actual.to_string() + "/" + expected.to_string(),
      0,
    )
  }
}

///|
fn validate_direction(
  report : ValidationReport,
  direction : PacketDirection,
) -> Unit {
  match direction {
    PacketDirection::Unknown(value) =>
      report.add(
        ValidationSeverity::Warning,
        "direction",
        "unknown Q_DIR=" + value.to_string(),
        -1,
      )
    _ => ()
  }
}

///|
fn validate_linking(report : ValidationReport, packet : LinkingPacket) -> Unit {
  validate_direction(report, packet.header.direction)
  if packet.sections.length() == 0 {
    report.add(
      ValidationSeverity::Error,
      "link.empty",
      "Packet 5 needs at least one link section",
      28,
    )
  }
  if packet.sections.length() > 32 {
    report.add(
      ValidationSeverity::Error,
      "link.count",
      "Packet 5 has more than 32 sections",
      28,
    )
  }
  for section in packet.sections {
    if section.country < 0 || section.country > 1023 {
      report.add(
        ValidationSeverity::Error,
        "link.country",
        "NID_C is outside 10 bits",
        -1,
      )
    }
    if section.group < 0 || section.group > 16383 {
      report.add(
        ValidationSeverity::Error,
        "link.group",
        "NID_BG is outside 14 bits",
        -1,
      )
    }
    if section.distance < 0 || section.distance > 32767 {
      report.add(
        ValidationSeverity::Error,
        "link.distance",
        "D_LINK is outside 15 bits",
        -1,
      )
    }
  }
}

///|
fn validate_authority(
  report : ValidationReport,
  packet : MovementAuthorityPacket,
) -> Unit {
  validate_direction(report, packet.header.direction)
  if packet.scale < 0 || packet.scale > 3 {
    report.add(
      ValidationSeverity::Error,
      "authority.scale",
      "Q_SCALE is outside 2 bits",
      23,
    )
  }
  if packet.sections.length() == 0 {
    report.add(
      ValidationSeverity::Error,
      "authority.empty",
      "Packet 12 has no authority section",
      28,
    )
  }
  for section in packet.sections {
    if section.distance < 0 || section.distance > 32767 {
      report.add(
        ValidationSeverity::Error,
        "authority.distance",
        "D section is outside 15 bits",
        -1,
      )
    }
    if section.permitted_speed < 0 || section.permitted_speed > 127 {
      report.add(
        ValidationSeverity::Error,
        "authority.speed",
        "V_MAIN is outside 7 bits",
        -1,
      )
    }
    if section.release_speed < 0 || section.release_speed > 127 {
      report.add(
        ValidationSeverity::Error,
        "authority.release",
        "V_LOA is outside 7 bits",
        -1,
      )
    }
  }
}

///|
fn validate_gradient(
  report : ValidationReport,
  packet : GradientPacket,
) -> Unit {
  validate_direction(report, packet.header.direction)
  if packet.scale < 0 || packet.scale > 3 {
    report.add(
      ValidationSeverity::Error,
      "gradient.scale",
      "Q_SCALE is outside 2 bits",
      23,
    )
  }
  if packet.sections.length() == 0 {
    report.add(
      ValidationSeverity::Error,
      "gradient.empty",
      "Packet 21 has no gradient section",
      28,
    )
  }
  for section in packet.sections {
    if section.distance < 0 || section.distance > 32767 {
      report.add(
        ValidationSeverity::Error,
        "gradient.distance",
        "D_GRADIENT is outside 15 bits",
        -1,
      )
    }
    if section.gradient < 0 || section.gradient > 255 {
      report.add(
        ValidationSeverity::Error,
        "gradient.value",
        "G_A is outside 8 bits",
        -1,
      )
    }
  }
}

///|
fn validate_speed(
  report : ValidationReport,
  packet : StaticSpeedPacket,
) -> Unit {
  validate_direction(report, packet.header.direction)
  if packet.scale < 0 || packet.scale > 3 {
    report.add(
      ValidationSeverity::Error,
      "speed.scale",
      "Q_SCALE is outside 2 bits",
      23,
    )
  }
  if packet.front < 0 || packet.front > 1 {
    report.add(
      ValidationSeverity::Error,
      "speed.front",
      "Q_FRONT is outside 1 bit",
      25,
    )
  }
  if packet.sections.length() == 0 {
    report.add(
      ValidationSeverity::Error,
      "speed.empty",
      "Packet 27 has no static speed section",
      28,
    )
  }
  for section in packet.sections {
    if section.distance < 0 || section.distance > 32767 {
      report.add(
        ValidationSeverity::Error,
        "speed.distance",
        "D_STATIC is outside 15 bits",
        -1,
      )
    }
    if section.speed < 0 || section.speed > 127 {
      report.add(
        ValidationSeverity::Error,
        "speed.value",
        "V_STATIC is outside 7 bits",
        -1,
      )
    }
    if section.differential < 0 || section.differential > 3 {
      report.add(
        ValidationSeverity::Error,
        "speed.differential",
        "Q_DIFF is outside 2 bits",
        -1,
      )
    }
  }
}

///|
/// Validate semantic packet ranges without destroying unknown packets.
pub fn validate_packet(packet : Packet) -> ValidationReport {
  let report = new_validation_report()
  match packet {
    Packet::Linking(value) => validate_linking(report, value)
    Packet::MovementAuthority(value) => validate_authority(report, value)
    Packet::Gradient(value) => validate_gradient(report, value)
    Packet::StaticSpeed(value) => validate_speed(report, value)
    Packet::Unknown(header, body) => {
      validate_direction(report, header.direction)
      issue_length(
        report,
        header.length_bits,
        body.length() + 23,
        "unknown packet",
      )
      report.add(
        ValidationSeverity::Info,
        "unknown.preserved",
        "unknown packet body was preserved",
        0,
      )
    }
    Packet::End =>
      report.add(
        ValidationSeverity::Info,
        "end",
        "Packet 255 terminates the packet sequence",
        0,
      )
  }
  report
}

///|
/// Validate every packet in a logical Telegram.
pub fn validate_telegram(telegram : BaliseTelegram) -> ValidationReport {
  let report = new_validation_report()
  if telegram.header.version < 0 || telegram.header.version > 127 {
    report.add(
      ValidationSeverity::Error,
      "header.version",
      "version is outside 7 bits",
      0,
    )
  }
  if telegram.header.balise_index < 0 || telegram.header.balise_index > 63 {
    report.add(
      ValidationSeverity::Error,
      "header.index",
      "balise index is outside 6 bits",
      7,
    )
  }
  if telegram.header.balise_count <= 0 || telegram.header.balise_count > 63 {
    report.add(
      ValidationSeverity::Error,
      "header.count",
      "balise count is outside 6 bits",
      13,
    )
  }
  if telegram.header.country < 0 || telegram.header.country > 1023 {
    report.add(
      ValidationSeverity::Error,
      "header.country",
      "country is outside 10 bits",
      20,
    )
  }
  if telegram.header.group < 0 || telegram.header.group > 16383 {
    report.add(
      ValidationSeverity::Error,
      "header.group",
      "group is outside 14 bits",
      30,
    )
  }
  for packet in telegram.packets {
    let packet_report = validate_packet(packet)
    for issue in packet_report.issues {
      report.issues.push(issue)
    }
  }
  issue_length(
    report,
    telegram.logical_payload.length(),
    telegram.form.logical_bits(),
    "telegram payload",
  )
  report
}

///|
/// Validate raw channel size and expose check failures as actionable issues.
pub fn validate_channel(
  raw : BitVector,
  form : TelegramForm,
) -> ValidationReport {
  let report = new_validation_report()
  let layout = channel_layout(form)
  issue_length(report, raw.length(), layout.total_bits, "channel frame")
  match decode_channel(raw, form) {
    Ok(_) => ()
    Err(ChannelError::CheckFailed) =>
      report.add(
        ValidationSeverity::Error,
        "check.failed",
        "85-bit block check failed",
        layout.total_bits - 85,
      )
    Err(_) =>
      report.add(
        ValidationSeverity::Error,
        "channel.decode",
        "channel frame could not be decoded",
        0,
      )
  }
  report
}

///|
/// A compact summary suitable for logs and fixture names.
pub fn telegram_summary(telegram : BaliseTelegram) -> String {
  let mut result = "balise=" + telegram.header.country.to_string()
  result = result + ":" + telegram.header.group.to_string()
  result = result + " packets=" + telegram.packets.length().to_string()
  result = result + " bits=" + telegram.logical_payload.length().to_string()
  result
}

///|
/// Return packet identifiers in acquisition order.
pub fn packet_ids(telegram : BaliseTelegram) -> Array[Int] {
  let ids = []
  for packet in telegram.packets {
    match packet {
      Packet::Linking(value) => ids.push(value.header.id)
      Packet::MovementAuthority(value) => ids.push(value.header.id)
      Packet::Gradient(value) => ids.push(value.header.id)
      Packet::StaticSpeed(value) => ids.push(value.header.id)
      Packet::Unknown(header, _) => ids.push(header.id)
      Packet::End => ids.push(packet_end_id())
    }
  }
  ids
}
