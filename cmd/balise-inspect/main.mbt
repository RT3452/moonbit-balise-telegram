///|
/// A tiny runnable inspector used by the README and CI smoke test.
fn main raise {
  let header = @balise.telegram_header(1, 0, 1, 0, 86, 1200, 0)
  let gradient = @balise.make_gradient_packet(
    @balise.packet_header(
      @balise.packet_gradient_id(),
      @balise.nominal_direction(),
    ),
    1,
    [@balise.gradient_section(120, true, 8)],
  )
  let speed = @balise.make_static_speed_packet(
    @balise.packet_header(
      @balise.packet_static_speed_id(),
      @balise.nominal_direction(),
    ),
    1,
    0,
    [@balise.speed_section(250, 60, 1)],
  )
  let form = @balise.long_form()
  let payload = @balise.encode_telegram(form, header, [gradient, speed])
  println("moonbit-balise-telegram")
  println("logical payload bits: " + payload.length().to_string())
  let parsed = @balise.parse_telegram(payload, form)
  println("decoded packet count: " + parsed.packets.length().to_string())
}
