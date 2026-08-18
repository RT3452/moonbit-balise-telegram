///|
/// The fixed 50-bit header used by the simulator's logical telegram view.
/// Field widths follow the ETCS balise header layout; the payload remains
/// opaque after the packet terminator so future packet families can be added.
pub struct TelegramHeader {
  version : Int
  balise_index : Int
  balise_count : Int
  copy : Int
  country : Int
  group : Int
  sequence : Int
}

///|
pub fn telegram_header(
  version : Int,
  balise_index : Int,
  balise_count : Int,
  copy : Int,
  country : Int,
  group : Int,
  sequence : Int,
) -> TelegramHeader {
  { version, balise_index, balise_count, copy, country, group, sequence }
}

///|
pub struct BaliseTelegram {
  form : TelegramForm
  header : TelegramHeader
  packets : Array[Packet]
  logical_payload : BitVector
}

///|
pub fn telegram_header_bits() -> Int {
  50
}

///|
fn encode_telegram_header(
  header : TelegramHeader,
  writer : BitWriter,
) -> Unit raise PacketError {
  write_value(writer, header.version, 7)
  write_value(writer, header.balise_index, 6)
  write_value(writer, header.balise_count, 6)
  write_value(writer, header.copy, 1)
  write_value(writer, header.country, 10)
  write_value(writer, header.group, 14)
  write_value(writer, header.sequence, 6)
}

///|
fn decode_telegram_header(
  reader : BitReader,
) -> TelegramHeader raise PacketError {
  let version = read_value(reader, 7)
  let balise_index = read_value(reader, 6)
  let balise_count = read_value(reader, 6)
  let copy = read_value(reader, 1)
  let country = read_value(reader, 10)
  let group = read_value(reader, 14)
  let sequence = read_value(reader, 6)
  { version, balise_index, balise_count, copy, country, group, sequence }
}

///|
/// Encode the logical user-data region before 10-to-11 channel shaping.
pub fn encode_telegram(
  form : TelegramForm,
  header : TelegramHeader,
  packets : Array[Packet],
) -> BitVector raise PacketError {
  let writer = BitWriter::new()
  encode_telegram_header(header, writer)
  for packet in packets {
    let encoded = encode_packet(packet)
    writer.write_bits(encoded)
  }
  writer.write_bits(encode_packet(Packet::End))
  let target_bits = form.logical_bits()
  if writer.bits.length() > target_bits {
    raise PacketError::InvalidLength(writer.bits.length())
  }
  while writer.bits.length() < target_bits {
    writer.write_bit(false)
  }
  writer.finish()
}

///|
/// Encode a logical telegram and then apply the physical channel frame.
pub fn encode_telegram_channel(
  form : TelegramForm,
  header : TelegramHeader,
  packets : Array[Packet],
) -> Result[ChannelFrame, ChannelError] raise PacketError {
  let logical = encode_telegram(form, header, packets)
  encode_default_channel(logical, form)
}

///|
fn reset_reader(reader : BitReader, position : Int) -> Unit raise PacketError {
  match reader.reset(position) {
    Ok(value) => value
    Err(error) => raise PacketError::BitError(error)
  }
}

///|
fn read_bits_or_raise(
  reader : BitReader,
  width : Int,
) -> BitVector raise PacketError {
  match reader.read_bits(width) {
    Ok(value) => value
    Err(error) => raise PacketError::BitError(error)
  }
}

///|
fn packet_from_reader(reader : BitReader) -> Packet raise PacketError {
  let start = reader.mark()
  let id = read_value(reader, 8)
  if id == packet_end_id() {
    return Packet::End
  }
  reset_reader(reader, start)
  let envelope = read_bits_or_raise(reader, 23)
  let envelope_reader = BitReader::new(envelope)
  ignore(read_value(envelope_reader, 8))
  ignore(read_value(envelope_reader, 2))
  let length_bits = read_value(envelope_reader, 13)
  reset_reader(reader, start)
  if length_bits > reader.remaining() {
    raise PacketError::Truncated(reader.remaining(), length_bits)
  }
  let packet_bits = read_bits_or_raise(reader, length_bits)
  parse_packet(packet_bits)
}

///|
/// Parse the logical user-data region and stop at Packet 255.
pub fn parse_telegram(
  input : BitVector,
  form : TelegramForm,
) -> BaliseTelegram raise PacketError {
  if input.length() != form.logical_bits() {
    raise PacketError::InvalidLength(input.length())
  }
  let reader = BitReader::new(input)
  let header = decode_telegram_header(reader)
  let packets = []
  let mut terminated = false
  while reader.remaining() >= 8 && !terminated {
    let packet = packet_from_reader(reader)
    match packet {
      Packet::End => terminated = true
      _ => packets.push(packet)
    }
  }
  { form, header, packets, logical_payload: input }
}

///|
/// Convenience pipeline for a raw 341/1023-bit telegram.
pub fn parse_channel_telegram(
  raw : BitVector,
  form : TelegramForm,
) -> Result[BaliseTelegram, ChannelError] raise PacketError {
  let frame = match decode_channel(raw, form) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok(parse_telegram(frame.logical_data, form))
}
