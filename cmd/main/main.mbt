///|
/// A minimal usage example for the moonqipai components. This binary is
/// documentation, not a product: the deliverable of this project is the
/// library (core unified engine + cards), which applications embed
/// directly.
///
/// Prints, for each supported game, the first two moves of a scripted line
/// through the unified interface, then evaluates one five-card poker hand.
fn main {
  println("moonqipai usage example")
  println("=======================")
  // Go: a capture on a 9x9 board
  let go = @core.Engine::make(@core.Go(9, 5.5))
  for mv in ["E5", "E6", "pass"] {
    ignore(go.apply(mv))
  }
  println("go legal moves so far: \{go.legal_moves().length()}")
  // Xiangqi: central cannon opening
  let x = @core.Engine::make(@core.Xiangqi)
  for mv in ["h2e2", "h9g7"] {
    match x.apply(mv) {
      Ok(_) => println("xiangqi ok: \{mv}")
      Err(e) => println("xiangqi \{mv} rejected: \{e.message()}")
    }
  }
  // Chess: Italian game opening
  let c = @core.Engine::make(@core.Chess)
  for mv in ["e2e4", "e7e5", "g1f3"] {
    match c.apply(mv) {
      Ok(_) => println("chess ok: \{mv}")
      Err(e) => println("chess \{mv} rejected: \{e.message()}")
    }
  }
  println("chess legal moves: \{c.legal_moves().length()}")
  // Poker: evaluate a full house
  match @cards.Card::parse_many("9c 9d 9h 2s 2c") {
    Some(cards) =>
      match @cards.evaluate_five(cards) {
        Some(hv) => println("poker: 9c 9d 9h 2s 2c = \{hv.rank.name()}")
        None => println("poker: evaluation failed")
      }
    None => println("poker: parse failed")
  }
}
