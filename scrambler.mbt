///|
/// Pluggable bit scrambler for recorded BTM traces. The channel frame keeps
/// the 12-bit seed explicit; this helper applies a deterministic LFSR mask to
/// a logical vector without coupling it to the packet parser.
pub struct ScramblerProfile {
  seed : Int
  polynomial : Int
  width : Int
}

///|
pub fn scrambler_profile(
  seed : Int,
  polynomial : Int,
  width : Int,
) -> ScramblerProfile {
  { seed, polynomial, width }
}

///|
pub fn default_scrambler_profile() -> ScramblerProfile {
  scrambler_profile(268435456, 305419896, 29)
}

///|
fn next_lfsr_bit(state : Int, polynomial : Int, width : Int) -> (Int, Bool) {
  let output = ((state >> (width - 1)) & 1) == 1
  let shifted = (state << 1) & ((1 << width) - 1)
  let next = if output { shifted ^ polynomial } else { shifted }
  (next, output)
}

///|
/// Generate an LFSR mask with a stable MSB-first representation.
pub fn scrambler_mask(profile : ScramblerProfile, length : Int) -> BitVector {
  let result = BitVector::new()
  let mut state = profile.seed & ((1 << profile.width) - 1)
  if state == 0 {
    state = 1
  }
  let mut index = 0
  while index < length {
    let next = next_lfsr_bit(state, profile.polynomial, profile.width)
    state = next.0
    result.bits.push(next.1)
    index = index + 1
  }
  result
}

///|
/// XOR the mask with a logical payload. Applying the same operation twice
/// restores the original vector, which is convenient for test fixtures.
pub fn scramble_bits(data : BitVector, profile : ScramblerProfile) -> BitVector {
  let mask = scrambler_mask(profile, data.length())
  let result = BitVector::new()
  let mut index = 0
  while index < data.length() {
    result.bits.push(data.bits[index] != mask.bits[index])
    index = index + 1
  }
  result
}

///|
pub fn descramble_bits(
  data : BitVector,
  profile : ScramblerProfile,
) -> BitVector {
  scramble_bits(data, profile)
}
