///|
/// A minimal usage example for the moonqipai components. This binary is
/// documentation, not a product: the deliverable of this project is the
/// library, which applications embed directly.
///
/// Drives one representative of every game family through the shared
/// abstractions: a turn-based board game (chess via the unified engine),
/// a connection game (gomoku, fully original), a randomness-driven card
/// game with hidden information (blackjack) and a complete multi-player
/// betting game (five-card draw).
fn main {
  println("moonqipai usage example")
  println("=======================")
  // unified engine: chess opening
  let c = @core.Engine::make(@core.Chess)
  for mv in ["e2e4", "e7e5", "g1f3"] {
    ignore(c.apply(mv))
  }
  println("chess legal moves: \{c.legal_moves().length()}")
  // original gomoku engine: a horizontal line in the making
  let g = @gomoku.Gomoku::standard()
  for i in 0..<4 {
    let _ = g.play(7, i)
    let _ = g.play(0, i + 1)
  }
  let _ = g.play(7, 4)
  let gw = if g.winner() is @gomoku.Black { "black" } else { "none" }
  println("gomoku over=\{g.is_over()} winner=\{gw}")
  // original othello engine: classical opening line
  let o = @othello.Othello::new()
  let _ = o.play(2, 3)
  let _ = o.play(4, 2)
  let (b, w) = o.counts()
  println("othello after two moves: \{b} vs \{w}")
  // blackjack: seeded, reproducible, dealer hole card hidden until stand
  let bj = @blackjack.Blackjack::new(42UL)
  let _ = bj.act(@blackjack.Stand)
  match bj.result() {
    Some(@blackjack.PlayerWin(payout)) =>
      println("blackjack settled: player wins, payout \{payout}")
    Some(@blackjack.DealerWin) => println("blackjack settled: dealer wins")
    Some(@blackjack.Push) => println("blackjack settled: push")
    None => println("blackjack still running")
  }
  // five-card draw: complete multi-player betting hand
  let p = @fivedraw.DrawPoker::new(3, 7UL)
  for seat in 0..<3 {
    let _ = p.bet(seat, @fivedraw.Call)
  }
  for seat in 0..<3 {
    let _ = p.discard(seat, [])
  }
  for seat in 0..<3 {
    let _ = p.bet(seat, @fivedraw.Check)
  }
  println("five-card draw winner: seat \{p.winner()}, pot \{p.pot()}")
  // poker evaluation utilities are exposed for pipelines
  match @cards.Card::parse_many("9c 9d 9h 2s 2c") {
    Some(cards) =>
      match @cards.evaluate_five(cards) {
        Some(hv) => println("hand 9c 9d 9h 2s 2c = \{hv.rank.name()}")
        None => println("evaluation failed")
      }
    None => println("parse failed")
  }
}
