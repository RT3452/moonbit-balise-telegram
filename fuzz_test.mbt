///|
test "deterministic vectors and mutations" {
  let first = random_logical_vectors(short_form(), 42, 2)
  let second = random_logical_vectors(short_form(), 42, 2)
  inspect(first.length(), content="2")
  inspect(first[0].hamming_distance(second[0]), content="0")
  let pair = mutate_bits(first[0], 7, 3)
  inspect(pair.0.length(), content="210")
  inspect(pair.1.length(), content="3")
  inspect(pair.0.hamming_distance(first[0]), content="3")
}

///|
test "generated long scenario can be channel encoded" {
  let generated = generated_scenario(long_form(), 4)
  let fixtures = try! generate_test_case(generated)
  inspect(fixtures.length(), content="4")
  for fixture in fixtures {
    inspect(fixture.raw.length(), content="1023")
  }
}

///|
test "damaged fixture changes exactly one bit" {
  let pairs = try! damaged_channel_fixtures(short_form(), 99, 2)
  inspect(pairs.length(), content="2")
  inspect(pairs[0].0.hamming_distance(pairs[0].1), content="1")
}
