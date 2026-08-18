///|
/// Packet metadata is kept in a small catalog so CLIs and trace exporters do
/// not need to duplicate a switch over the protocol namespace.
pub struct PacketDescriptor {
  id : Int
  name : String
  minimum_body_bits : Int
  repeatable : Bool
}

///|
pub fn packet_descriptor(id : Int) -> PacketDescriptor {
  match id {
    5 => { id: 5, name: "Linking", minimum_body_bits: 27, repeatable: true }
    12 =>
      {
        id: 12,
        name: "Movement Authority",
        minimum_body_bits: 12,
        repeatable: true,
      }
    21 => { id: 21, name: "Gradient", minimum_body_bits: 31, repeatable: true }
    27 =>
      { id: 27, name: "Static Speed", minimum_body_bits: 13, repeatable: true }
    255 => { id: 255, name: "End", minimum_body_bits: 0, repeatable: false }
    other =>
      {
        id: other,
        name: "Unknown(" + other.to_string() + ")",
        minimum_body_bits: 0,
        repeatable: false,
      }
  }
}

///|
pub fn packet_catalog() -> Array[PacketDescriptor] {
  [
    packet_descriptor(packet_linking_id()),
    packet_descriptor(packet_movement_authority_id()),
    packet_descriptor(packet_gradient_id()),
    packet_descriptor(packet_static_speed_id()),
    packet_descriptor(packet_end_id()),
  ]
}

///|
pub fn packet_id(packet : Packet) -> Int {
  match packet {
    Packet::Linking(value) => value.header.id
    Packet::MovementAuthority(value) => value.header.id
    Packet::Gradient(value) => value.header.id
    Packet::StaticSpeed(value) => value.header.id
    Packet::Unknown(header, _) => header.id
    Packet::End => packet_end_id()
  }
}

///|
pub fn packet_name(packet : Packet) -> String {
  packet_descriptor(packet_id(packet)).name
}

///|
pub fn packet_sequence(input : BitVector) -> Array[Packet] raise PacketError {
  let result = []
  let reader = BitReader::new(input)
  let mut done = false
  while reader.remaining() >= 8 && !done {
    let start = reader.mark()
    let id = read_value(reader, 8)
    if id == packet_end_id() {
      result.push(Packet::End)
      done = true
    } else {
      let _ = reader.reset(start)
      let envelope = match reader.read_bits(23) {
        Ok(value) => value
        Err(error) => raise PacketError::BitError(error)
      }
      let envelope_reader = BitReader::new(envelope)
      ignore(read_value(envelope_reader, 8))
      ignore(read_value(envelope_reader, 2))
      let length = read_value(envelope_reader, 13)
      let _ = reader.reset(start)
      if length > reader.remaining() {
        raise PacketError::Truncated(reader.remaining(), length)
      }
      let bits = match reader.read_bits(length) {
        Ok(value) => value
        Err(error) => raise PacketError::BitError(error)
      }
      result.push(parse_packet(bits))
    }
  }
  result
}

///|
pub struct PacketCursor {
  packets : Array[Packet]
  mut index : Int
}

///|
pub fn packet_cursor(packets : Array[Packet]) -> PacketCursor {
  { packets, index: 0 }
}

///|
pub fn PacketCursor::next(self : PacketCursor) -> Packet? {
  if self.index >= self.packets.length() {
    None
  } else {
    let result = self.packets[self.index]
    self.index = self.index + 1
    Some(result)
  }
}

///|
pub fn PacketCursor::rewind(self : PacketCursor) -> Unit {
  self.index = 0
}

///|
pub fn PacketCursor::remaining(self : PacketCursor) -> Int {
  self.packets.length() - self.index
}

///|
pub struct PacketMetrics {
  total : Int
  unknown : Int
  payload_bits : Int
  counts : Array[(Int, Int)]
}

///|
pub fn packet_metrics(packets : Array[Packet]) -> PacketMetrics {
  let mut unknown = 0
  let mut payload_bits = 0
  let counts : Array[(Int, Int)] = []
  for packet in packets {
    let id = packet_id(packet)
    if id != packet_end_id() {
      let mut found = false
      let mut index = 0
      while index < counts.length() {
        if counts[index].0 == id {
          counts[index] = (id, counts[index].1 + 1)
          found = true
        }
        index = index + 1
      }
      if !found {
        counts.push((id, 1))
      }
    }
    match packet {
      Packet::Unknown(_, body) => {
        unknown = unknown + 1
        payload_bits = payload_bits + body.length()
      }
      Packet::End => ()
      _ => ()
    }
  }
  { total: packets.length(), unknown, payload_bits, counts }
}

///|
pub fn has_packet(packets : Array[Packet], id : Int) -> Bool {
  for packet in packets {
    if packet_id(packet) == id {
      return true
    }
  }
  false
}

///|
pub fn select_packets(packets : Array[Packet], id : Int) -> Array[Packet] {
  let result = []
  for packet in packets {
    if packet_id(packet) == id {
      result.push(packet)
    }
  }
  result
}
