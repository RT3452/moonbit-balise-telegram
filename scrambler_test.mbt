///|
test "scrambler is reversible" {
  let input = BitVector::from_string("1011001110001111").unwrap()
  let profile = default_scrambler_profile()
  let scrambled = scramble_bits(input, profile)
  inspect(scrambled.length(), content="16")
  let restored = descramble_bits(scrambled, profile)
  inspect(restored.to_string(), content="1011001110001111")
  inspect(input.hamming_distance(scrambled) > 0, content="true")
}
