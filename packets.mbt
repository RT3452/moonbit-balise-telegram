///|
/// Packet identifiers from the ETCS/Eurobalise packet namespace.
pub fn packet_linking_id() -> Int {
  5
}

///|
pub fn packet_movement_authority_id() -> Int {
  12
}

///|
pub fn packet_gradient_id() -> Int {
  21
}

///|
pub fn packet_static_speed_id() -> Int {
  27
}

///|
pub fn packet_end_id() -> Int {
  255
}

///|
pub enum PacketDirection {
  Nominal
  Reverse
  Both
  Unknown(Int)
}

///|
/// Public builders keep protocol records constructible from another package.
pub fn nominal_direction() -> PacketDirection {
  PacketDirection::Nominal
}

///|
pub fn reverse_direction() -> PacketDirection {
  PacketDirection::Reverse
}

///|
pub fn both_direction() -> PacketDirection {
  PacketDirection::Both
}

///|
pub fn packet_header(id : Int, direction : PacketDirection) -> PacketHeader {
  { id, direction, length_bits: 0 }
}

///|
pub fn linking_section(
  distance : Int,
  country : Int,
  group : Int,
  orientation : Int,
  reaction : Int,
  location_accuracy : Int,
) -> LinkingSection {
  { distance, country, group, orientation, reaction, location_accuracy }
}

///|
pub fn authority_section(
  distance : Int,
  permitted_speed : Int,
  release_speed : Int,
) -> AuthoritySection {
  { distance, permitted_speed, release_speed }
}

///|
pub fn gradient_section(
  distance : Int,
  uphill : Bool,
  gradient : Int,
) -> GradientSection {
  { distance, uphill, gradient }
}

///|
pub fn speed_section(
  distance : Int,
  speed : Int,
  differential : Int,
) -> SpeedSection {
  { distance, speed, differential }
}

///|
pub fn make_linking_packet(
  header : PacketHeader,
  sections : Array[LinkingSection],
) -> Packet {
  Packet::Linking({ header, sections })
}

///|
pub fn make_movement_authority_packet(
  header : PacketHeader,
  scale : Int,
  sections : Array[AuthoritySection],
) -> Packet {
  Packet::MovementAuthority({ header, scale, sections })
}

///|
pub fn make_gradient_packet(
  header : PacketHeader,
  scale : Int,
  sections : Array[GradientSection],
) -> Packet {
  Packet::Gradient({ header, scale, sections })
}

///|
pub fn make_static_speed_packet(
  header : PacketHeader,
  scale : Int,
  front : Int,
  sections : Array[SpeedSection],
) -> Packet {
  Packet::StaticSpeed({ header, scale, front, sections })
}

///|
fn direction_to_int(direction : PacketDirection) -> Int {
  match direction {
    Nominal => 0
    Reverse => 1
    Both => 2
    Unknown(value) => value
  }
}

///|
fn direction_from_int(value : Int) -> PacketDirection {
  match value {
    0 => Nominal
    1 => Reverse
    2 => Both
    other => Unknown(other)
  }
}

///|
pub struct PacketHeader {
  id : Int
  direction : PacketDirection
  length_bits : Int
}

///|
pub struct LinkingSection {
  distance : Int
  country : Int
  group : Int
  orientation : Int
  reaction : Int
  location_accuracy : Int
}

///|
pub struct LinkingPacket {
  header : PacketHeader
  sections : Array[LinkingSection]
}

///|
pub struct AuthoritySection {
  distance : Int
  permitted_speed : Int
  release_speed : Int
}

///|
pub struct MovementAuthorityPacket {
  header : PacketHeader
  scale : Int
  sections : Array[AuthoritySection]
}

///|
pub struct GradientSection {
  distance : Int
  uphill : Bool
  gradient : Int
}

///|
pub struct GradientPacket {
  header : PacketHeader
  scale : Int
  sections : Array[GradientSection]
}

///|
pub struct SpeedSection {
  distance : Int
  speed : Int
  differential : Int
}

///|
pub struct StaticSpeedPacket {
  header : PacketHeader
  scale : Int
  front : Int
  sections : Array[SpeedSection]
}

///|
pub enum Packet {
  Linking(LinkingPacket)
  MovementAuthority(MovementAuthorityPacket)
  Gradient(GradientPacket)
  StaticSpeed(StaticSpeedPacket)
  Unknown(PacketHeader, BitVector)
  End
}

///|
pub(all) suberror PacketError {
  BitError(BitReadError)
  InvalidIdentifier(Int)
  InvalidDirection(Int)
  InvalidLength(Int)
  Truncated(Int, Int)
}

///|
pub fn PacketError::message(self : PacketError) -> String {
  match self {
    PacketError::BitError(_) => "packet bit error"
    PacketError::InvalidIdentifier(value) =>
      "invalid packet id: " + value.to_string()
    PacketError::InvalidDirection(value) =>
      "invalid packet direction: " + value.to_string()
    PacketError::InvalidLength(value) =>
      "invalid packet length: " + value.to_string()
    PacketError::Truncated(actual, expected) =>
      "packet truncated: " + actual.to_string() + "/" + expected.to_string()
  }
}

///|
fn read_value(reader : BitReader, width : Int) -> Int raise PacketError {
  match reader.read_uint(width) {
    Ok(value) => value
    Err(error) => raise PacketError::BitError(error)
  }
}

///|
fn write_value(
  writer : BitWriter,
  value : Int,
  width : Int,
) -> Unit raise PacketError {
  match writer.write_uint(value, width) {
    Ok(value) => value
    Err(error) => raise PacketError::BitError(error)
  }
}

///|
fn parse_linking(
  header : PacketHeader,
  body : BitVector,
) -> Packet raise PacketError {
  let reader = BitReader::new(body)
  let q_scale = read_value(reader, 2)
  let count = read_value(reader, 5)
  let sections = []
  let mut index = 0
  while index <= count {
    let distance = read_value(reader, 15)
    let country = read_value(reader, 10)
    let group = read_value(reader, 14)
    let orientation = read_value(reader, 1)
    let reaction = read_value(reader, 2)
    let location_accuracy = read_value(reader, 6)
    sections.push({
      distance,
      country,
      group,
      orientation,
      reaction,
      location_accuracy,
    })
    index = index + 1
  }
  ignore(q_scale)
  Linking({ header, sections })
}

///|
fn parse_movement_authority(
  header : PacketHeader,
  body : BitVector,
) -> Packet raise PacketError {
  let reader = BitReader::new(body)
  let scale = read_value(reader, 2)
  let count = read_value(reader, 5)
  let sections = []
  let mut index = 0
  while index <= count {
    let distance = read_value(reader, 15)
    let permitted_speed = read_value(reader, 7)
    let release_speed = read_value(reader, 7)
    sections.push({ distance, permitted_speed, release_speed })
    index = index + 1
  }
  MovementAuthority({ header, scale, sections })
}

///|
fn parse_gradient(
  header : PacketHeader,
  body : BitVector,
) -> Packet raise PacketError {
  let reader = BitReader::new(body)
  let scale = read_value(reader, 2)
  let count = read_value(reader, 5)
  let sections = []
  let mut index = 0
  while index <= count {
    let distance = read_value(reader, 15)
    let uphill = read_value(reader, 1) == 1
    let gradient = read_value(reader, 8)
    sections.push({ distance, uphill, gradient })
    index = index + 1
  }
  Gradient({ header, scale, sections })
}

///|
fn parse_static_speed(
  header : PacketHeader,
  body : BitVector,
) -> Packet raise PacketError {
  let reader = BitReader::new(body)
  let scale = read_value(reader, 2)
  let front = read_value(reader, 1)
  let count = read_value(reader, 5)
  let sections = []
  let mut index = 0
  while index <= count {
    let distance = read_value(reader, 15)
    let speed = read_value(reader, 7)
    let differential = read_value(reader, 2)
    sections.push({ distance, speed, differential })
    index = index + 1
  }
  StaticSpeed({ header, scale, front, sections })
}

///|
/// Parse one packet from the beginning of a bit vector.
pub fn parse_packet(input : BitVector) -> Packet raise PacketError {
  let reader = BitReader::new(input)
  let id = read_value(reader, 8)
  if id == packet_end_id() {
    return End
  }
  let direction_value = read_value(reader, 2)
  if direction_value > 2 {
    raise PacketError::InvalidDirection(direction_value)
  }
  let length_bits = read_value(reader, 13)
  if length_bits < 23 {
    raise PacketError::InvalidLength(length_bits)
  }
  if length_bits > input.length() {
    raise PacketError::Truncated(input.length(), length_bits)
  }
  let header = PacketHeader::{
    id,
    direction: direction_from_int(direction_value),
    length_bits,
  }
  let body = match input.slice(23, length_bits) {
    Ok(value) => value
    Err(error) => raise PacketError::BitError(error)
  }
  match id {
    5 => parse_linking(header, body)
    12 => parse_movement_authority(header, body)
    21 => parse_gradient(header, body)
    27 => parse_static_speed(header, body)
    _ => Unknown(header, body)
  }
}

///|
fn encode_linking(packet : LinkingPacket) -> BitVector raise PacketError {
  let body = BitWriter::new()
  write_value(body, 0, 2)
  if packet.sections.length() == 0 || packet.sections.length() > 32 {
    raise PacketError::InvalidLength(packet.sections.length())
  }
  write_value(body, packet.sections.length() - 1, 5)
  for section in packet.sections {
    write_value(body, section.distance, 15)
    write_value(body, section.country, 10)
    write_value(body, section.group, 14)
    write_value(body, section.orientation, 1)
    write_value(body, section.reaction, 2)
    write_value(body, section.location_accuracy, 6)
  }
  encode_with_header(
    packet_linking_id(),
    packet.header.direction,
    body.finish(),
  )
}

///|
fn encode_movement_authority(
  packet : MovementAuthorityPacket,
) -> BitVector raise PacketError {
  let body = BitWriter::new()
  write_value(body, packet.scale, 2)
  if packet.sections.length() == 0 || packet.sections.length() > 32 {
    raise PacketError::InvalidLength(packet.sections.length())
  }
  write_value(body, packet.sections.length() - 1, 5)
  for section in packet.sections {
    write_value(body, section.distance, 15)
    write_value(body, section.permitted_speed, 7)
    write_value(body, section.release_speed, 7)
  }
  encode_with_header(
    packet_movement_authority_id(),
    packet.header.direction,
    body.finish(),
  )
}

///|
fn encode_gradient(packet : GradientPacket) -> BitVector raise PacketError {
  let body = BitWriter::new()
  write_value(body, packet.scale, 2)
  if packet.sections.length() == 0 || packet.sections.length() > 32 {
    raise PacketError::InvalidLength(packet.sections.length())
  }
  write_value(body, packet.sections.length() - 1, 5)
  for section in packet.sections {
    write_value(body, section.distance, 15)
    let uphill = match section.uphill {
      true => 1
      false => 0
    }
    write_value(body, uphill, 1)
    write_value(body, section.gradient, 8)
  }
  encode_with_header(
    packet_gradient_id(),
    packet.header.direction,
    body.finish(),
  )
}

///|
fn encode_static_speed(
  packet : StaticSpeedPacket,
) -> BitVector raise PacketError {
  let body = BitWriter::new()
  write_value(body, packet.scale, 2)
  write_value(body, packet.front, 1)
  if packet.sections.length() == 0 || packet.sections.length() > 32 {
    raise PacketError::InvalidLength(packet.sections.length())
  }
  write_value(body, packet.sections.length() - 1, 5)
  for section in packet.sections {
    write_value(body, section.distance, 15)
    write_value(body, section.speed, 7)
    write_value(body, section.differential, 2)
  }
  encode_with_header(
    packet_static_speed_id(),
    packet.header.direction,
    body.finish(),
  )
}

///|
fn encode_with_header(
  id : Int,
  direction : PacketDirection,
  body : BitVector,
) -> BitVector raise PacketError {
  if id < 0 || id > 255 {
    raise PacketError::InvalidIdentifier(id)
  }
  let direction_value = direction_to_int(direction)
  if direction_value < 0 || direction_value > 2 {
    raise PacketError::InvalidDirection(direction_value)
  }
  let length_bits = 23 + body.length()
  if length_bits > 8191 {
    raise PacketError::InvalidLength(length_bits)
  }
  let writer = BitWriter::new()
  write_value(writer, id, 8)
  write_value(writer, direction_value, 2)
  write_value(writer, length_bits, 13)
  writer.write_bits(body)
  writer.finish()
}

///|
/// Encode a packet using its computed L_PACKET envelope.
pub fn encode_packet(packet : Packet) -> BitVector raise PacketError {
  match packet {
    Linking(value) => encode_linking(value)
    MovementAuthority(value) => encode_movement_authority(value)
    Gradient(value) => encode_gradient(value)
    StaticSpeed(value) => encode_static_speed(value)
    Unknown(header, body) =>
      encode_with_header(header.id, header.direction, body)
    End =>
      BitVector::from_array([true, true, true, true, true, true, true, true])
  }
}
