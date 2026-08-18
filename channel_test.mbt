///|
test "short channel round trip" {
  let source = BitVector::from_array([false].repeat(210))
  let frame = match encode_default_channel(source, short_form()) {
    Ok(value) => value
    Err(error) => fail(error.message())
  }
  let decoded = match decode_channel(frame.raw(), short_form()) {
    Ok(value) => value
    Err(error) => fail(error.message())
  }
  inspect(decoded.raw().length(), content="341")
  inspect(decoded.logical_data.length(), content="210")
}

///|
test "long channel round trip" {
  let source = BitVector::from_array(
    [true, false, true, false, false].repeat(166),
  )
  let frame = match encode_default_channel(source, long_form()) {
    Ok(value) => value
    Err(error) => fail(error.message())
  }
  let decoded = match decode_channel(frame.raw(), long_form()) {
    Ok(value) => value
    Err(error) => fail(error.message())
  }
  inspect(decoded.raw().length(), content="1023")
  inspect(decoded.logical_data.length(), content="830")
}

///|
test "channel check rejects a damaged frame" {
  let source = BitVector::from_array(
    [true, false, false, true, true].repeat(166),
  )
  let frame = encode_default_channel(source, long_form()).unwrap()
  let raw = frame.raw()
  raw.bits[300] = !raw.bits[300]
  match decode_channel(raw, long_form()) {
    Err(ChannelError::CheckFailed) => ()
    _ => fail("damaged telegram was accepted")
  }
}
