///|
/// GTP column letters for Go vertices; the letter `i` is skipped by
/// convention. Index 0 = column `A`.
let go_cols : Array[Char] = "ABCDEFGHJKLMNOPQRSTUVWXYZ".to_array()

///|
/// Converts a 0-based (row, col) with row 0 at the top to a GTP vertex
/// such as `Q16`.
pub fn go_vertex(size : Int32, row : Int32, col : Int32) -> String {
  let buf = StringBuilder()
  buf.write_char(go_cols[col])
  buf.write_string("\{size - row}")
  buf.to_string()
}

///|
/// Parses a GTP vertex (`Q16`) or `pass` into (row, col) coordinates with
/// row 0 at the top. Returns `Some((-1, -1))` for a pass; `None` for
/// malformed or out-of-range input.
pub fn go_parse_vertex(size : Int32, text : String) -> (Int32, Int32)? {
  let t = text.to_lower()
  if t == "pass" {
    return Some((-1, -1))
  }
  if t.length() < 2 {
    return None
  }
  let chars = t.to_array()
  let letter = chars[0].to_ascii_uppercase()
  let mut col = -1
  for i in 0..<go_cols.length() {
    if go_cols[i] == letter {
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
/// Applies a GTP-style move (`Q16` or `pass`) to a running Go game.
pub fn go_apply(g : @moonbaduk.Game, mv : String) -> Result[Unit, EngineError] {
  let size = g.size()
  match go_parse_vertex(size, mv) {
    None => Err(UnknownMove(mv))
    Some((row, col)) => {
      if row < 0 {
        g.play_pass(g.turn())
        return Ok(())
      }
      match g.play(row, col) {
        Ok(_) => Ok(())
        Err(e) => Err(IllegalMove(e.message()))
      }
    }
  }
}

///|
/// Lists all legal Go moves (GTP vertices) plus `pass`.
pub fn go_legal_moves(g : @moonbaduk.Game) -> Array[String] {
  let size = g.size()
  let acc : Array[String] = []
  for pt in g.legal_points(g.turn()) {
    let (r, c) = pt
    acc.push(go_vertex(size, r, c))
  }
  acc.push("pass")
  acc
}

///|
/// The Go outcome once the game is over: area scoring converted to a
/// `Score` outcome (or `Draw` for a jigo). `None` while still running.
pub fn go_outcome(g : @moonbaduk.Game) -> Outcome? {
  if !g.is_over() {
    return None
  }
  let score = g.final_score()
  if score == "0" {
    return Some(Draw)
  }
  if score.has_prefix("B+") {
    match parse_go_margin(score[2:].to_owned()) {
      Some(m) => return Some(Score(P1, m))
      None => return Some(Winner(P1))
    }
  }
  if score.has_prefix("W+") {
    match parse_go_margin(score[2:].to_owned()) {
      Some(m) => return Some(Score(P2, m))
      None => return Some(Winner(P2))
    }
  }
  Some(Winner(P1))
}

///|
/// Parses a non-negative decimal margin such as `"2.5"`.
fn parse_go_margin(text : String) -> Double? {
  let chars = text.to_array()
  if chars.length() == 0 {
    return None
  }
  let mut whole = 0
  let mut frac = 0
  let mut frac_digits = 0
  let mut seen_dot = false
  for ch in chars {
    if ch == '.' {
      if seen_dot {
        return None
      }
      seen_dot = true
    } else if ch >= '0' && ch <= '9' {
      if seen_dot {
        frac = frac * 10 + (ch.to_int() - '0'.to_int())
        frac_digits += 1
      } else {
        whole = whole * 10 + (ch.to_int() - '0'.to_int())
      }
    } else {
      return None
    }
  }
  let divisor = {
    let mut d = 1.0
    for _ in 0..<frac_digits {
      d = d * 10.0
    }
    d
  }
  Some(whole.to_double() + frac.to_double() / divisor)
}
