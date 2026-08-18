///|
/// Interop helpers for fixture files and CLI adapters. They deliberately use
/// `Int` for bytes so the core package stays backend-neutral.
pub fn BitVector::count_ones(self : BitVector) -> Int {
  let mut count = 0
  for bit in self.bits {
    if bit {
      count = count + 1
    }
  }
  count
}

///|
pub fn BitVector::hamming_distance(self : BitVector, other : BitVector) -> Int {
  let common = if self.length() < other.length() {
    self.length()
  } else {
    other.length()
  }
  let mut distance = if self.length() > other.length() {
    self.length() - common
  } else {
    other.length() - common
  }
  let mut index = 0
  while index < common {
    if self.bits[index] != other.bits[index] {
      distance = distance + 1
    }
    index = index + 1
  }
  distance
}

///|
pub fn BitVector::invert(self : BitVector) -> BitVector {
  let result = BitVector::new()
  for bit in self.bits {
    result.bits.push(!bit)
  }
  result
}

///|
pub fn BitVector::from_bytes(
  bytes : Array[Int],
) -> Result[BitVector, BitReadError] {
  let result = BitVector::new()
  for value in bytes {
    if value < 0 || value > 255 {
      return Err(ValueOverflow(value))
    }
    let mut shift = 7
    while shift >= 0 {
      result.bits.push(((value >> shift) & 1) == 1)
      shift = shift - 1
    }
  }
  Ok(result)
}

///|
pub fn BitVector::to_bytes(self : BitVector) -> Array[Int] {
  let result = []
  let mut index = 0
  while index < self.length() {
    let mut value = 0
    let mut offset = 0
    while offset < 8 {
      let position = index + offset
      let bit = match position < self.length() {
        true => self.bits[position]
        false => false
      }
      let bit_value = match bit {
        true => 1
        false => 0
      }
      value = value * 2 + bit_value
      offset = offset + 1
    }
    result.push(value)
    index = index + 8
  }
  result
}

///|
fn hex_value(code : UInt16) -> Int? {
  if code >= 48 && code <= 57 {
    Some(code.to_int() - 48)
  } else if code >= 65 && code <= 70 {
    Some(code.to_int() - 65 + 10)
  } else if code >= 97 && code <= 102 {
    Some(code.to_int() - 97 + 10)
  } else {
    None
  }
}

///|
/// Parse hexadecimal fixture text, accepting spaces, colons and underscores.
pub fn BitVector::from_hex(text : String) -> Result[BitVector, BitReadError] {
  let result = BitVector::new()
  let mut high : Int? = None
  let mut index = 0
  while index < text.length() {
    let code = text.at(index)
    if code == 32 ||
      code == 9 ||
      code == 10 ||
      code == 13 ||
      code == 58 ||
      code == 95 {
      index = index + 1
      continue
    }
    let value = match hex_value(code) {
      Some(value) => value
      None => return Err(InvalidCharacter(code.to_int()))
    }
    match high {
      None => high = Some(value)
      Some(left) => {
        let byte = left * 16 + value
        let mut shift = 7
        while shift >= 0 {
          result.bits.push(((byte >> shift) & 1) == 1)
          shift = shift - 1
        }
        high = None
      }
    }
    index = index + 1
  }
  match high {
    Some(value) => {
      let mut shift = 3
      while shift >= 0 {
        result.bits.push(((value >> shift) & 1) == 1)
        shift = shift - 1
      }
    }
    None => ()
  }
  Ok(result)
}

///|
pub fn BitVector::to_hex(self : BitVector) -> String {
  let digits = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
  ]
  let mut result = ""
  let mut index = 0
  while index < self.length() {
    let mut value = 0
    let mut offset = 0
    while offset < 4 {
      let position = index + offset
      let bit = match position < self.length() {
        true => self.bits[position]
        false => false
      }
      let bit_value = match bit {
        true => 1
        false => 0
      }
      value = value * 2 + bit_value
      offset = offset + 1
    }
    result = result + digits[value]
    index = index + 4
  }
  result
}

///|
/// Read a field without changing the caller's cursor.
pub fn BitReader::read_uint_at(
  self : BitReader,
  position : Int,
  width : Int,
) -> Result[Int, BitReadError] {
  let old = self.mark()
  match self.reset(position) {
    Err(error) => Err(error)
    Ok(_) => {
      let result = self.read_uint(width)
      let _ = self.reset(old)
      result
    }
  }
}

///|
pub fn BitReader::seek(
  self : BitReader,
  position : Int,
) -> Result[Unit, BitReadError] {
  self.reset(position)
}

///|
pub fn BitWriter::write_bytes(
  self : BitWriter,
  bytes : Array[Int],
) -> Result[Unit, BitReadError] {
  for value in bytes {
    let result = self.write_uint(value, 8)
    match result {
      Ok(_) => ()
      Err(error) => return Err(error)
    }
  }
  Ok(())
}

///|
/// CRC-16/CCITT helper for test adapters and trace files.
pub fn crc16_ccitt(input : BitVector, initial : Int) -> Int {
  let mut crc = initial & 65535
  for bit in input.bits {
    let high = ((crc >> 15) & 1) == 1
    crc = (crc << 1) & 65535
    if high != bit {
      crc = crc ^ 4129
    }
  }
  crc
}
