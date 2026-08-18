///|
/// A compact, allocation-conscious bit container used by every protocol layer.
pub struct BitVector {
  bits : Array[Bool]
}

///|
pub fn BitVector::new() -> BitVector {
  { bits: [] }
}

///|
pub fn BitVector::from_array(bits : Array[Bool]) -> BitVector {
  { bits, }
}

///|
pub fn BitVector::from_string(text : String) -> Result[BitVector, BitReadError] {
  let out = BitVector::new()
  let mut index = 0
  while index < text.length() {
    let code = text.at(index)
    if code == 48 {
      out.bits.push(false)
    } else if code == 49 {
      out.bits.push(true)
    } else {
      return Err(InvalidCharacter(code.to_int()))
    }
    index = index + 1
  }
  Ok(out)
}

///|
pub fn BitVector::length(self : BitVector) -> Int {
  self.bits.length()
}

///|
pub fn BitVector::get(
  self : BitVector,
  index : Int,
) -> Result[Bool, BitReadError] {
  if index < 0 || index >= self.bits.length() {
    Err(OutOfBounds(index, self.bits.length()))
  } else {
    Ok(self.bits[index])
  }
}

///|
pub fn BitVector::push(self : BitVector, bit : Bool) -> Unit {
  self.bits.push(bit)
}

///|
pub fn BitVector::append(self : BitVector, other : BitVector) -> Unit {
  self.bits.append(other.bits)
}

///|
pub fn BitVector::slice(
  self : BitVector,
  start : Int,
  end : Int,
) -> Result[BitVector, BitReadError] {
  if start < 0 || end < start || end > self.bits.length() {
    Err(OutOfBounds(start, self.bits.length()))
  } else {
    let out = BitVector::new()
    let mut index = start
    while index < end {
      out.bits.push(self.bits[index])
      index = index + 1
    }
    Ok(out)
  }
}

///|
pub fn BitVector::to_string(self : BitVector) -> String {
  let mut out = ""
  for bit in self.bits {
    let bit_text = match bit {
      true => "1"
      false => "0"
    }
    out = out + bit_text
  }
  out
}

///|
pub enum BitReadError {
  InvalidWidth(Int)
  OutOfBounds(Int, Int)
  InvalidCharacter(Int)
  ValueOverflow(Int)
}

///|
pub struct BitReader {
  bits : Array[Bool]
  mut cursor : Int
}

///|
pub fn BitReader::new(input : BitVector) -> BitReader {
  { bits: input.bits, cursor: 0 }
}

///|
pub fn BitReader::position(self : BitReader) -> Int {
  self.cursor
}

///|
pub fn BitReader::remaining(self : BitReader) -> Int {
  self.bits.length() - self.cursor
}

///|
pub fn BitReader::mark(self : BitReader) -> Int {
  self.cursor
}

///|
pub fn BitReader::reset(
  self : BitReader,
  position : Int,
) -> Result[Unit, BitReadError] {
  if position < 0 || position > self.bits.length() {
    Err(OutOfBounds(position, self.bits.length()))
  } else {
    self.cursor = position
    Ok(())
  }
}

///|
pub fn BitReader::skip(
  self : BitReader,
  width : Int,
) -> Result[Unit, BitReadError] {
  if width < 0 || self.cursor + width > self.bits.length() {
    Err(OutOfBounds(self.cursor + width, self.bits.length()))
  } else {
    self.cursor = self.cursor + width
    Ok(())
  }
}

///|
pub fn BitReader::read_bit(self : BitReader) -> Result[Bool, BitReadError] {
  if self.cursor >= self.bits.length() {
    Err(OutOfBounds(self.cursor, self.bits.length()))
  } else {
    let bit = self.bits[self.cursor]
    self.cursor = self.cursor + 1
    Ok(bit)
  }
}

///|
pub fn BitReader::peek_bit(self : BitReader) -> Result[Bool, BitReadError] {
  if self.cursor >= self.bits.length() {
    Err(OutOfBounds(self.cursor, self.bits.length()))
  } else {
    Ok(self.bits[self.cursor])
  }
}

///|
pub fn BitReader::read_uint(
  self : BitReader,
  width : Int,
) -> Result[Int, BitReadError] {
  if width < 0 || width > 30 {
    return Err(InvalidWidth(width))
  }
  if self.cursor + width > self.bits.length() {
    return Err(OutOfBounds(self.cursor + width, self.bits.length()))
  }
  let mut value = 0
  let mut index = 0
  while index < width {
    let bit_value = match self.bits[self.cursor] {
      true => 1
      false => 0
    }
    value = value * 2 + bit_value
    self.cursor = self.cursor + 1
    index = index + 1
  }
  Ok(value)
}

///|
pub fn BitReader::read_bits(
  self : BitReader,
  width : Int,
) -> Result[BitVector, BitReadError] {
  if width < 0 || self.cursor + width > self.bits.length() {
    return Err(OutOfBounds(self.cursor + width, self.bits.length()))
  }
  let out = BitVector::new()
  let mut index = 0
  while index < width {
    out.bits.push(self.bits[self.cursor])
    self.cursor = self.cursor + 1
    index = index + 1
  }
  Ok(out)
}

///|
pub struct BitWriter {
  bits : BitVector
}

///|
pub fn BitWriter::new() -> BitWriter {
  { bits: BitVector::new() }
}

///|
pub fn BitWriter::write_bit(self : BitWriter, bit : Bool) -> Unit {
  self.bits.push(bit)
}

///|
pub fn BitWriter::write_uint(
  self : BitWriter,
  value : Int,
  width : Int,
) -> Result[Unit, BitReadError] {
  if width < 0 || width > 30 {
    return Err(InvalidWidth(width))
  }
  if value < 0 || value >= 1 << width {
    return Err(ValueOverflow(value))
  }
  let mut shift = width - 1
  while shift >= 0 {
    self.bits.push(((value >> shift) & 1) == 1)
    shift = shift - 1
  }
  Ok(())
}

///|
pub fn BitWriter::write_bits(self : BitWriter, bits : BitVector) -> Unit {
  self.bits.append(bits)
}

///|
pub fn BitWriter::finish(self : BitWriter) -> BitVector {
  self.bits
}
