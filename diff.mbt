///|
/// Diff tools make decoder regressions visible without depending on a GUI.
pub struct BitDiff {
  same_length : Bool
  hamming_distance : Int
  first_difference : Int
  changed_positions : Array[Int]
}

///|
pub fn diff_bits(left : BitVector, right : BitVector, limit : Int) -> BitDiff {
  let common = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  let positions = []
  let mut hamming = 0
  let mut first = -1
  let mut index = 0
  while index < common {
    if left.bits[index] != right.bits[index] {
      hamming = hamming + 1
      if first < 0 {
        first = index
      }
      if positions.length() < limit {
        positions.push(index)
      }
    }
    index = index + 1
  }
  {
    same_length: left.length() == right.length(),
    hamming_distance: hamming +
    (left.length() - common) +
    (right.length() - common),
    first_difference: first,
    changed_positions: positions,
  }
}

///|
pub fn channel_diff(
  left : BitVector,
  right : BitVector,
  limit : Int,
) -> BitDiff {
  diff_bits(left, right, limit)
}

///|
pub enum TelegramDifference {
  HeaderVersion
  HeaderIndex
  HeaderCount
  HeaderIdentity
  PacketCount
  PacketIdentifier(Int, Int, Int)
  PayloadBits
}

///|
/// Compare logical Telegrams while keeping the difference semantic.
pub fn telegram_diff(
  left : BaliseTelegram,
  right : BaliseTelegram,
) -> Array[TelegramDifference] {
  let differences = []
  if left.header.version != right.header.version {
    differences.push(TelegramDifference::HeaderVersion)
  }
  if left.header.balise_index != right.header.balise_index {
    differences.push(TelegramDifference::HeaderIndex)
  }
  if left.header.balise_count != right.header.balise_count {
    differences.push(TelegramDifference::HeaderCount)
  }
  let identity_changed = left.header.country != right.header.country ||
    left.header.group != right.header.group
  if identity_changed {
    differences.push(TelegramDifference::HeaderIdentity)
  }
  if left.packets.length() != right.packets.length() {
    differences.push(TelegramDifference::PacketCount)
  }
  let common = if left.packets.length() < right.packets.length() {
    left.packets.length()
  } else {
    right.packets.length()
  }
  let mut index = 0
  while index < common {
    let left_id = packet_id(left.packets[index])
    let right_id = packet_id(right.packets[index])
    if left_id != right_id {
      differences.push(
        TelegramDifference::PacketIdentifier(index, left_id, right_id),
      )
    }
    index = index + 1
  }
  if left.logical_payload.hamming_distance(right.logical_payload) > 0 {
    differences.push(TelegramDifference::PayloadBits)
  }
  differences
}

///|
/// Return ranges of consecutive changed bits for compact diagnostics.
pub fn changed_ranges(diff : BitDiff) -> Array[(Int, Int)] {
  let ranges = []
  if diff.changed_positions.length() == 0 {
    return ranges
  }
  let mut start = diff.changed_positions[0]
  let mut previous = start
  let mut index = 1
  while index < diff.changed_positions.length() {
    let position = diff.changed_positions[index]
    if position != previous + 1 {
      ranges.push((start, previous))
      start = position
    }
    previous = position
    index = index + 1
  }
  ranges.push((start, previous))
  ranges
}
