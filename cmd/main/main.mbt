///|
/// A minimal usage example for the moonqipai components. This binary is
/// documentation, not a product: the deliverable of this project is the
/// library, which applications embed directly.
///
/// Drives one representative of every game family through the shared
/// abstractions: five board games behind the single unified engine
/// (chess, gomoku and othello shown here), a randomness-driven card game
/// with hidden information (blackjack), a complete multi-player betting
/// game (five-card draw) and a casual action-card game (UNO).
fn main {
  println("moonqipai usage example")
  println("=======================")
  // one engine interface, five board games — chess opening
  let c = @core.Engine::make(@core.Chess)
  for mv in ["e2e4", "e7e5", "g1f3"] {
    ignore(c.apply(mv))
  }
  println("chess legal moves: \{c.legal_moves().length()}")
  // the same interface drives gomoku...
  let g = @core.Engine::make(@core.Gomoku(15))
  for mv in ["H8", "I9", "J10", "G7", "K11", "F6"] {
    ignore(g.apply(mv))
  }
  let gm = g.outcome()
  println("gomoku over=\{g.is_over()} outcome=\{gm is Some(_)}")
  // ...and othello
  let o = @core.Engine::make(@core.Othello)
  for mv in ["D3", "C5", "F6"] {
    ignore(o.apply(mv))
  }
  println("othello legal moves: \{o.legal_moves().length()}")
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
  // UNO: action-card game with hidden hands
  let u = @uno.Uno::new(3, 42UL)
  let mut steps = 0
  while !(u.is_over()) && steps < 60 {
    let seat = u.turn()
    let hand = u.hand_of(seat).unwrap()
    let mut played = false
    if !(u.drawn_pending()) {
      for i in 0..<hand.length() {
        let card = hand[i]
        let choice = if card.kind is @uno.Wild || card.kind is @uno.WildDrawFour {
          Some(@uno.Blue)
        } else {
          None
        }
        if card.playable_on(u.active_color(), u.active_face()) {
          let _ = u.act(seat, @uno.Play(i, choice))
          played = true
          break
        }
      }
      if !played {
        let _ = u.act(seat, @uno.Draw)
      }
    } else {
      if u.act(seat, @uno.PlayDrawn(Some(@uno.Red))) is Err(_) {
        let _ = u.act(seat, @uno.Hold)
      }
    }
    steps += 1
  }
  println("uno progressed \{steps} actions, over=\{u.is_over()}")
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
