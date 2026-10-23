///|
/// The halfmove clock limit of the fifty-move rule (100 half-moves).
pub const FIFTY_MOVE_LIMIT : Int32 = 100

///|
/// Applies a UCI move (`e2e4`, promotion `e7e8q`) to a chess position,
/// returning the new position value.
pub fn chess_apply(
  p : @moonchess.Position,
  mv : String,
) -> Result[@moonchess.Position, EngineError] {
  let text = mv.to_lower()
  if text.length() < 4 {
    return Err(UnknownMove(mv))
  }
  // match against the legal move list by UCI text; this validates both the
  // syntax and the legality in one step
  let legal = p.legal_moves()
  let mut found : @moonchess.Move? = None
  for m in legal {
    if m.to_uci() == text {
      found = Some(m)
    }
  }
  match found {
    None =>
      // distinguish syntax errors from illegal moves
      match @moonchess.Square::parse(text[0:2].to_owned()) {
        Some(_) =>
          match @moonchess.Square::parse(text[2:4].to_owned()) {
            Some(_) => Err(IllegalMove(mv))
            None => Err(UnknownMove(mv))
          }
        None => Err(UnknownMove(mv))
      }
    Some(m) => Ok(p.make_move(m))
  }
}

///|
/// Lists all legal chess moves as UCI strings.
pub fn chess_legal_moves(p : @moonchess.Position) -> Array[String] {
  let acc : Array[String] = []
  for m in p.legal_moves() {
    acc.push(m.to_uci())
  }
  acc
}

///|
/// The chess outcome: checkmate, stalemate and the fifty-move rule.
/// Repetition and insufficient-material draws are delegated to the caller
/// (the underlying position tracks a Zobrist hash for that purpose).
pub fn chess_outcome(p : @moonchess.Position) -> Outcome? {
  let legal = p.legal_moves()
  if legal.length() == 0 {
    if p.in_check(p.turn()) {
      return Some(
        if p.turn() is @moonchess.White {
          Winner(P2)
        } else {
          Winner(P1)
        },
      )
    }
    return Some(Draw) // stalemate
  }
  if p.halfmove_clock() >= FIFTY_MOVE_LIMIT {
    return Some(Draw)
  }
  None
}
