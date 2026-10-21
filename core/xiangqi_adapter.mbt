///|
/// Applies an ICCS move (`h2e2`) to a xiangqi board, returning the new
/// board value.
pub fn xiangqi_apply(
  b : @xiangqi.Board,
  mv : String,
) -> Result[@xiangqi.Board, EngineError] {
  match b.move_from_iccs(mv) {
    Err(_) => Err(UnknownMove(mv))
    Ok(m) => {
      let legal = b.legal_moves()
      let mut found = false
      for lm in legal {
        if lm == m {
          found = true
        }
      }
      if !found {
        return Err(IllegalMove(mv))
      }
      Ok(b.apply_move(m))
    }
  }
}

///|
/// Lists all legal xiangqi moves as ICCS strings.
pub fn xiangqi_legal_moves(b : @xiangqi.Board) -> Array[String] {
  let acc : Array[String] = []
  for m in b.legal_moves() {
    acc.push(b.move_to_iccs(m))
  }
  acc
}

///|
/// The xiangqi outcome: `result()` for decisive results, plus the
/// stalemate-is-a-loss rule when the side to move has no legal moves.
pub fn xiangqi_outcome(b : @xiangqi.Board) -> Outcome? {
  match b.result() {
    @xiangqi.RedWins => return Some(Winner(P1))
    @xiangqi.BlackWins => return Some(Winner(P2))
    @xiangqi.Ongoing => ()
  }
  if b.is_checkmate() {
    return Some(if b.side() is @xiangqi.Red { Winner(P2) } else { Winner(P1) })
  }
  if b.is_stalemate() {
    // in xiangqi, the stalemated side loses
    return Some(if b.side() is @xiangqi.Red { Winner(P2) } else { Winner(P1) })
  }
  None
}
