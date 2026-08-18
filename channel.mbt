///|
/// Wire sizes for the two Eurobalise telegram forms.
pub enum TelegramForm {
  Short
  Long
}

///|
pub fn short_form() -> TelegramForm {
  TelegramForm::Short
}

///|
pub fn long_form() -> TelegramForm {
  TelegramForm::Long
}

///|
pub fn TelegramForm::total_bits(self : TelegramForm) -> Int {
  match self {
    Short => 341
    Long => 1023
  }
}

///|
pub fn TelegramForm::symbol_count(self : TelegramForm) -> Int {
  match self {
    Short => 21
    Long => 83
  }
}

///|
pub fn TelegramForm::logical_bits(self : TelegramForm) -> Int {
  self.symbol_count() * 10
}

///|
pub fn TelegramForm::symbol_bits(self : TelegramForm) -> Int {
  self.symbol_count() * 11
}

///|
pub struct ChannelLayout {
  form : TelegramForm
  total_bits : Int
  logical_bits : Int
  symbol_bits : Int
  auxiliary_bits : Int
  check_bits : Int
}

///|
pub fn channel_layout(form : TelegramForm) -> ChannelLayout {
  {
    form,
    total_bits: form.total_bits(),
    logical_bits: form.logical_bits(),
    symbol_bits: form.symbol_bits(),
    auxiliary_bits: 25,
    check_bits: 85,
  }
}

///|
pub enum ChannelError {
  WrongLength(Int, Int)
  InvalidControlLength(Int)
  InvalidScramblingLength(Int)
  InvalidExtraLength(Int)
  InvalidCodeword(Int)
  CheckFailed
}

///|
/// Stable diagnostic text for CLI and integration tests.
pub fn ChannelError::message(self : ChannelError) -> String {
  match self {
    WrongLength(actual, expected) =>
      "wrong length: " + actual.to_string() + "/" + expected.to_string()
    InvalidControlLength(actual) => "control length: " + actual.to_string()
    InvalidScramblingLength(actual) =>
      "scrambling length: " + actual.to_string()
    InvalidExtraLength(actual) => "extra shaping length: " + actual.to_string()
    InvalidCodeword(value) => "invalid codeword: " + value.to_string()
    CheckFailed => "check failed"
  }
}

///|
priv struct CheckParameters {
  frame_generator : BitVector
}

///|
fn literal_bits(text : String) -> BitVector {
  match BitVector::from_string(text) {
    Ok(bits) => bits
    Err(_) => BitVector::new()
  }
}

///|
fn long_check_parameters() -> CheckParameters {
  {
    frame_generator: polynomial_multiply(
      literal_bits("11011011111"),
      literal_bits(
        "1011100010000111001110011010011110100010111011010101001000111011101000010011",
      ),
    ),
  }
}

///|
fn short_check_parameters() -> CheckParameters {
  {
    frame_generator: polynomial_multiply(
      literal_bits("10110101011"),
      literal_bits(
        "1001111101111001000011000010111111101111011111001010010010101001111001001011",
      ),
    ),
  }
}

///|
fn check_parameters(form : TelegramForm) -> CheckParameters {
  match form {
    Short => short_check_parameters()
    Long => long_check_parameters()
  }
}

///|
fn xor_at(left : Array[Bool], right : Array[Bool], offset : Int) -> Unit {
  let mut index = 0
  while index < right.length() {
    left[offset + index] = left[offset + index] != right[index]
    index = index + 1
  }
}

///|
fn polynomial_multiply(left : BitVector, right : BitVector) -> BitVector {
  let result = BitVector::from_array(
    [false].repeat(left.length() + right.length() - 1),
  )
  let mut left_index = 0
  while left_index < left.length() {
    if left.bits[left_index] {
      let mut right_index = 0
      while right_index < right.length() {
        if right.bits[right_index] {
          let position = left_index + right_index
          result.bits[position] = !result.bits[position]
        }
        right_index = right_index + 1
      }
    }
    left_index = left_index + 1
  }
  result
}

///|
fn polynomial_remainder(data : BitVector, generator : BitVector) -> BitVector {
  let degree = generator.length() - 1
  let work = data.bits.copy()
  let mut padding = 0
  while padding < degree {
    work.push(false)
    padding = padding + 1
  }
  let mut position = 0
  while position + degree < work.length() {
    if work[position] {
      xor_at(work, generator.bits, position)
    }
    position = position + 1
  }
  let result = BitVector::new()
  let start = work.length() - degree
  let mut index = start
  while index < work.length() {
    result.bits.push(work[index])
    index = index + 1
  }
  result
}

///|
fn bit_vectors_equal(left : BitVector, right : BitVector) -> Bool {
  if left.length() != right.length() {
    return false
  }
  let mut index = 0
  while index < left.length() {
    if left.bits[index] != right.bits[index] {
      return false
    }
    index = index + 1
  }
  true
}

///|
fn calculate_check(precheck : BitVector, form : TelegramForm) -> BitVector {
  let parameters = check_parameters(form)
  polynomial_remainder(precheck, parameters.frame_generator)
}

///|
pub struct ChannelFrame {
  form : TelegramForm
  logical_data : BitVector
  symbol_data : BitVector
  control_bits : BitVector
  scrambling_bits : BitVector
  extra_shaping_bits : BitVector
  check_bits : BitVector
}

///|
fn check_auxiliary(bits : BitVector, width : Int) -> Bool {
  bits.length() == width
}

///|
pub fn encode_channel(
  logical_data : BitVector,
  form : TelegramForm,
  control_bits : BitVector,
  scrambling_bits : BitVector,
  extra_shaping_bits : BitVector,
) -> Result[ChannelFrame, ChannelError] {
  let layout = channel_layout(form)
  if logical_data.length() != layout.logical_bits {
    return Err(WrongLength(logical_data.length(), layout.logical_bits))
  }
  if !check_auxiliary(control_bits, 3) {
    return Err(InvalidControlLength(control_bits.length()))
  }
  if !check_auxiliary(scrambling_bits, 12) {
    return Err(InvalidScramblingLength(scrambling_bits.length()))
  }
  if !check_auxiliary(extra_shaping_bits, 10) {
    return Err(InvalidExtraLength(extra_shaping_bits.length()))
  }
  let symbol_data = encode_symbols(logical_data, form)
  let precheck = BitVector::new()
  precheck.append(symbol_data)
  precheck.append(control_bits)
  precheck.append(scrambling_bits)
  precheck.append(extra_shaping_bits)
  let check_bits = calculate_check(precheck, form)
  Ok({
    form,
    logical_data,
    symbol_data: precheck.slice(0, layout.symbol_bits).unwrap(),
    control_bits,
    scrambling_bits,
    extra_shaping_bits,
    check_bits,
  })
}

///|
pub fn encode_default_channel(
  logical_data : BitVector,
  form : TelegramForm,
) -> Result[ChannelFrame, ChannelError] {
  encode_channel(
    logical_data,
    form,
    BitVector::from_array([false, false, true]),
    BitVector::from_array([false].repeat(12)),
    BitVector::from_array([false].repeat(10)),
  )
}

///|
pub fn ChannelFrame::raw(self : ChannelFrame) -> BitVector {
  let out = BitVector::new()
  out.append(self.symbol_data)
  out.append(self.control_bits)
  out.append(self.scrambling_bits)
  out.append(self.extra_shaping_bits)
  out.append(self.check_bits)
  out
}

///|
pub fn decode_channel(
  raw : BitVector,
  form : TelegramForm,
) -> Result[ChannelFrame, ChannelError] {
  let layout = channel_layout(form)
  if raw.length() != layout.total_bits {
    return Err(WrongLength(raw.length(), layout.total_bits))
  }
  let symbol_data = raw.slice(0, layout.symbol_bits).unwrap()
  let control_bits = raw
    .slice(layout.symbol_bits, layout.symbol_bits + 3)
    .unwrap()
  let scrambling_bits = raw
    .slice(layout.symbol_bits + 3, layout.symbol_bits + 15)
    .unwrap()
  let extra_shaping_bits = raw
    .slice(layout.symbol_bits + 15, layout.symbol_bits + 25)
    .unwrap()
  let check_bits = raw
    .slice(layout.symbol_bits + 25, layout.total_bits)
    .unwrap()
  let precheck = raw.slice(0, layout.total_bits - 85).unwrap()
  if !bit_vectors_equal(calculate_check(precheck, form), check_bits) {
    return Err(CheckFailed)
  }
  let logical_data = decode_symbols(symbol_data, form)
  Ok({
    form,
    logical_data,
    symbol_data,
    control_bits,
    scrambling_bits,
    extra_shaping_bits,
    check_bits,
  })
}

///|
fn encode_symbols(logical_data : BitVector, form : TelegramForm) -> BitVector {
  let reader = BitReader::new(logical_data)
  let writer = BitWriter::new()
  let mut index = 0
  while index < form.symbol_count() {
    let value = reader.read_uint(10).unwrap()
    let codeword = channel_codeword(value)
    writer.write_uint(codeword, 11).unwrap()
    index = index + 1
  }
  writer.finish()
}

///|
fn decode_symbols(symbol_data : BitVector, form : TelegramForm) -> BitVector {
  let reader = BitReader::new(symbol_data)
  let writer = BitWriter::new()
  let mut index = 0
  while index < form.symbol_count() {
    let codeword = reader.read_uint(11).unwrap()
    let value = channel_symbol_index(codeword).unwrap()
    writer.write_uint(value, 10).unwrap()
    index = index + 1
  }
  writer.finish()
}

///|
fn channel_symbol_index(codeword : Int) -> Result[Int, ChannelError] {
  let mut index = 0
  while index < channel_codebook.length() {
    if channel_codebook[index] == codeword {
      return Ok(index)
    }
    index = index + 1
  }
  Err(InvalidCodeword(codeword))
}
