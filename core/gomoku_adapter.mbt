///|
/// Column letters for Gomoku vertices; the letter `i` is skipped, in
/// line with the Go convention used elsewhere in this library.
let gomoku_cols : Array[Char] = "ABCDEFGHJKLMNOPQRSTUVWXYZ".to_array()

///|
/// Converts 0-based (row, col) with row 0 at the top to a vertex such as
/// `H8`.
pub fn gomoku_vertex(size : Int, row : Int, col : Int) -> String {
  let buf = StringBuilder()
  buf.write_char(gomoku_cols[col])
  buf.write_string("\{size - row}")
  buf.to_string()
}

///|
/// Parses a Gomoku vertex (`H8`); returns `None` for malformed or
/// out-of-range input.
pub fn gomoku_parse_vertex(size : Int, text : String) -> (Int, Int)? {
  let t = text.to_lower()
  if t.length() < 2 {
    return None
  }
  let chars = t.to_array()
  let letter = chars[0].to_ascii_uppercase()
  let mut col = -1
  for i in 0..<gomoku_cols.length() {
    if gomoku_cols[i] == letter {
      col = i
    }
  }
  if col < 0 || col >= size {
    return None
  }
  let mut number = 0
  for i in 1..<chars.length() {
    let ch = chars[i]
    if ch < '0' || ch > '9' {
      return None
    }
    number = number * 10 + (ch.to_int() - '0'.to_int())
  }
  let row = size - number
  if row < 0 || row >= size {
    return None
  }
  Some((row, col))
}

///|
/// Applies a Gomoku vertex move.
pub fn gomoku_apply(g : @gomoku.Gomoku, mv : String) -> Result[Unit, EngineError] {
  let size = g.size()
  match gomoku_parse_vertex(size, mv) {
    None => Err(UnknownMove(mv))
    Some((row, col)) =>
      match g.play(row, col) {
        Ok(_) => Ok(())
        Err(e) => Err(IllegalMove(e.message()))
      }
  }
}

///|
/// Lists all legal Gomoku moves as vertices.
pub fn gomoku_legal_moves(g : @gomoku.Gomoku) -> Array[String] {
  let size = g.size()
  let acc : Array[String] = []
  for pt in g.legal_moves() {
    let (r, c) = pt
    acc.push(gomoku_vertex(size, r, c))
  }
  acc
}

///|
/// The Gomoku outcome: the line-maker wins, a full board without a line
/// is a draw.
pub fn gomoku_outcome(g : @gomoku.Gomoku) -> Outcome? {
  if !(g.is_over()) {
    return None
  }
  match g.winner() {
    w if w is @gomoku.Black => Some(Winner(P1))
    w if w is @gomoku.White => Some(Winner(P2))
    _ => Some(Draw)
  }
}
