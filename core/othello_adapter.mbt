///|
/// Converts 0-based (row, col) with row 0 at the top to an Othello
/// vertex such as `D3`.
pub fn othello_vertex(row : Int32, col : Int32) -> String {
  let buf = StringBuilder()
  buf.write_char("ABCDEFGH".to_array()[col])
  buf.write_string("\{row + 1}")
  buf.to_string()
}

///|
/// Parses an Othello vertex (`D3`); returns `None` for malformed input.
pub fn othello_parse_vertex(text : String) -> (Int32, Int32)? {
  let t = text.to_lower()
  if t.length() != 2 {
    return None
  }
  let chars = t.to_array()
  let mut col = -1
  for i in 0..<8 {
    if "abcdefgh".to_array()[i] == chars[0] {
      col = i
    }
  }
  if col < 0 {
    return None
  }
  let ch = chars[1]
  if ch < '1' || ch > '8' {
    return None
  }
  let row = ch.to_int() - '0'.to_int() - 1
  Some((row, col))
}

///|
/// Applies an Othello vertex move; `pass` is accepted only when the side
/// to move has no legal move.
pub fn othello_apply(
  o : @othello.Othello,
  mv : String,
) -> Result[Unit, EngineError] {
  let t = mv.to_lower()
  if t == "pass" {
    match o.pass() {
      Ok(_) => Ok(())
      Err(e) => Err(IllegalMove(e.message()))
    }
  } else {
    match othello_parse_vertex(mv) {
      None => Err(UnknownMove(mv))
      Some((row, col)) =>
        match o.play(row, col) {
          Ok(_) => Ok(())
          Err(e) => Err(IllegalMove(e.message()))
        }
    }
  }
}

///|
/// Lists all legal Othello moves as vertices, plus `pass` when the side
/// to move cannot move.
pub fn othello_legal_moves(o : @othello.Othello) -> Array[String] {
  let acc : Array[String] = []
  for pt in o.legal_moves() {
    let (r, c) = pt
    acc.push(othello_vertex(r, c))
  }
  if acc.length() == 0 && !o.is_over() {
    acc.push("pass")
  }
  acc
}

///|
/// The Othello outcome: majority winner or a draw.
pub fn othello_outcome(o : @othello.Othello) -> Outcome? {
  match o.winner() {
    Some(w) =>
      if w is @othello.Black {
        Some(Winner(P1))
      } else {
        Some(Winner(P2))
      }
    None => if o.is_over() { Some(Draw) } else { None }
  }
}
