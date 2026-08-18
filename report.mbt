///|
/// Text adapters are intentionally dependency-free so they work in CI and
/// in the tiny inspector command alike.
pub fn PacketMetrics::summary(self : PacketMetrics) -> String {
  let mut result = "total=" + self.total.to_string()
  result = result + " unknown=" + self.unknown.to_string()
  result = result + " payload_bits=" + self.payload_bits.to_string()
  result
}

///|
pub fn ValidationReport::summary(self : ValidationReport) -> String {
  let mut result = "valid=" + self.is_valid().to_string()
  result = result + " errors=" + self.error_count().to_string()
  result = result + " warnings=" + self.warning_count().to_string()
  result
}

///|
pub fn format_bit_ranges(ranges : Array[(Int, Int)]) -> String {
  if ranges.length() == 0 {
    return "none"
  }
  let mut result = ""
  let mut index = 0
  for range in ranges {
    if index > 0 {
      result = result + ","
    }
    result = result + range.0.to_string() + "-" + range.1.to_string()
    index = index + 1
  }
  result
}

///|
pub fn frame_digest(frame : BitVector) -> String {
  let mut result = "bits=" + frame.length().to_string()
  result = result + " ones=" + frame.count_ones().to_string()
  result = result + " hex=" + frame.to_hex()
  result
}
