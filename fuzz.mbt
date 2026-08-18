///|
/// Small deterministic generator for reproducible protocol fixtures.
pub struct DeterministicRng {
  mut state : Int
}

///|
pub fn deterministic_rng(seed : Int) -> DeterministicRng {
  let initial = match seed < 0 {
    true => -seed
    false => seed
  }
  { state: initial + 1 }
}

///|
pub fn DeterministicRng::next(self : DeterministicRng) -> Int {
  self.state = (self.state * 1103515245 + 12345) & 2147483647
  self.state
}

///|
pub fn DeterministicRng::next_bounded(
  self : DeterministicRng,
  bound : Int,
) -> Int {
  if bound <= 0 {
    0
  } else {
    self.next() % bound
  }
}

///|
pub fn DeterministicRng::next_bool(self : DeterministicRng) -> Bool {
  self.next_bounded(2) == 1
}

///|
pub enum MutationKind {
  SingleBit
  Burst(Int)
}

///|
pub struct BitMutation {
  offset : Int
  kind : MutationKind
  before : Bool
  after : Bool
}

///|
/// Flip deterministic bits without changing the frame length.
pub fn mutate_bits(
  input : BitVector,
  seed : Int,
  count : Int,
) -> (BitVector, Array[BitMutation]) {
  let output = BitVector::from_array(input.bits.copy())
  let mutations = []
  let rng = deterministic_rng(seed)
  let mut index = 0
  while index < count && output.length() > 0 {
    let offset = rng.next_bounded(output.length())
    let before = output.bits[offset]
    output.bits[offset] = !before
    let kind = match index % 3 {
      0 => MutationKind::Burst(1)
      _ => MutationKind::SingleBit
    }
    mutations.push({ offset, kind, before, after: output.bits[offset] })
    index = index + 1
  }
  (output, mutations)
}

///|
/// Generate logical payloads for property and performance tests.
pub fn random_logical_vectors(
  form : TelegramForm,
  seed : Int,
  count : Int,
) -> Array[BitVector] {
  let vectors = []
  let rng = deterministic_rng(seed)
  let mut vector_index = 0
  while vector_index < count {
    let bits = BitVector::new()
    let mut bit_index = 0
    while bit_index < form.logical_bits() {
      bits.bits.push(rng.next_bool())
      bit_index = bit_index + 1
    }
    vectors.push(bits)
    vector_index = vector_index + 1
  }
  vectors
}

///|
fn generated_packets_for(
  index : Int,
  total : Int,
  form : TelegramForm,
) -> Array[Packet] {
  let packets = []
  if index + 1 < total {
    let link = make_linking_packet(
      packet_header(packet_linking_id(), nominal_direction()),
      [linking_section(100 + index * 20, 86, 500 + index + 1, 0, 0, 2)],
    )
    packets.push(link)
  }
  let gradient = make_gradient_packet(
    packet_header(packet_gradient_id(), nominal_direction()),
    index % 4,
    [gradient_section(50 + index * 10, index % 2 == 0, 3 + index)],
  )
  packets.push(gradient)
  let include_speed = match form {
    Short => false
    Long => index % 2 == 0
  }
  if include_speed {
    let speed = make_static_speed_packet(
      packet_header(packet_static_speed_id(), nominal_direction()),
      1,
      0,
      [speed_section(200 + index * 5, 50 + index, 0)],
    )
    packets.push(speed)
  }
  packets
}

///|
/// Build a useful track-like group without external files.
pub fn generated_scenario(form : TelegramForm, count : Int) -> Scenario {
  let balises = []
  let total = if count < 0 { 0 } else { count }
  let mut index = 0
  while index < total {
    let identity = balise_identity(86, 500 + index, index)
    balises.push(
      scenario_balise(identity, generated_packets_for(index, total, form)),
    )
    index = index + 1
  }
  scenario(form, balises)
}

///|
/// Produce paired clean/damaged channel fixtures for a decoder test suite.
pub fn damaged_channel_fixtures(
  form : TelegramForm,
  seed : Int,
  count : Int,
) -> Array[(BitVector, BitVector)] raise PacketError {
  let pairs = []
  let vectors = random_logical_vectors(form, seed, count)
  let mut index = 0
  for logical in vectors {
    let clean = encode_default_channel(logical, form)
    let frame = match clean {
      Ok(value) => value
      Err(error) => raise PacketError::InvalidLength(error.message().length())
    }
    let mutation = mutate_bits(frame.raw(), seed + index + 1, 1)
    pairs.push((frame.raw(), mutation.0))
    index = index + 1
  }
  pairs
}
