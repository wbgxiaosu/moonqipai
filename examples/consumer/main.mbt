///|
fn main {
  // board games through the unified Engine facade
  let chess = @core.Engine::make(@core.Chess)
  println("chess legal moves: \{chess.legal_moves().length()}")
  let info = @core.Engine::game_info(chess)
  let (min_p, max_p) = info.players
  println(
    "chess game_info: players=\{min_p}..\{max_p} perfect=\{info.perfect_information}",
  )

  // a self-contained original engine
  let g = @gomoku.Gomoku::standard()
  let _ = g.play(7, 7)
  let _ = g.play(8, 8)
  println("gomoku white to move: \{g.turn() is @gomoku.White}")

  // othello with its native API
  let ot = @othello.Othello::new()
  println("othello legal moves at start: \{ot.legal_moves().length()}")

  // checkers: black opens d4-c5 style step (square 23 -> 30)
  let ck = @checkers.Checkers::new()
  let _ = ck.play({ from: 23, to: 30, captures: [], })
  println("checkers white to move: \{ck.turn() is @checkers.White}")

  // card games
  let bj = @blackjack.Blackjack::new(42UL)
  let _ = bj.act(@blackjack.Hit)
  println("blackjack round over: \{bj.is_over()}")

  let uno = @uno.Uno::new(3, 7UL)
  println("uno players: \{uno.player_count()}, over: \{uno.is_over()}")

  // five-card draw with a betting round
  let p = @fivedraw.DrawPoker::new(3, 7UL)
  let _ = p.bet(0, @fivedraw.Call)
  println("draw poker over after first bet: \{p.is_over()}")

  // pure poker hand evaluation
  match @cards.Card::parse_many("9c 9d 9h 2s 2c") {
    Some(hand) =>
      match @cards.evaluate_five(hand) {
        Some(hv) => println("hand 9c 9d 9h 2s 2c = \{hv.rank.name()}")
        None => println("evaluation failed")
      }
    None => println("parse failed")
  }

  println("consumer example OK")
}
