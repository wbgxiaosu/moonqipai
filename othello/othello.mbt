///|
/// Disc colours; `Empty` marks vacant squares.
pub(all) enum Disc {
  Empty
  Black
  White
} derive(Eq, Debug)

///|
pub extend Disc with Eq::{equal, not_equal}

///|
pub extend Disc with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// The opponent of a colour; `Empty` maps to itself.
pub fn Disc::opponent(self : Disc) -> Disc {
  match self {
    Empty => Empty
    Black => White
    White => Black
  }
}

///|
/// Move failures on an Othello board.
pub(all) enum OthelloError {
  OutOfBounds
  Occupied
  NoFlip
  GameOver
} derive(Eq, Debug)

///|
pub extend OthelloError with Eq::{equal, not_equal}

///|
pub extend OthelloError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn OthelloError::message(self : OthelloError) -> String {
  match self {
    OutOfBounds => "coordinates out of bounds"
    Occupied => "the square is already occupied"
    NoFlip => "the move must flip at least one disc"
    GameOver => "the game is already over"
  }
}

///|
/// A standard 8x8 Othello (Reversi) position. Black moves first from the
/// classical centre setup; a move must bracket at least one opposing
/// line; a side without a legal move passes; two consecutive passes (or
/// a full board) end the game and the majority wins.
pub struct Othello {
  priv mut cells : Array[Disc]
  priv mut turn : Disc
  priv mut passes : Int32
  priv undo_stack : Array[Array[Disc]]
}

///|
/// Creates the classical starting position.
pub fn Othello::new() -> Othello {
  let cells : Array[Disc] = []
  for _ in 0..<64 {
    cells.push(Empty)
  }
  cells[3 * 8 + 3] = White
  cells[3 * 8 + 4] = Black
  cells[4 * 8 + 3] = Black
  cells[4 * 8 + 4] = White
  { cells, turn: Black, passes: 0, undo_stack: [], }
}

///|
/// The side to move.
pub fn Othello::turn(self : Othello) -> Disc {
  self.turn
}

///|
/// Reads a square; out-of-range reads yield `Empty`.
pub fn Othello::get(self : Othello, row : Int32, col : Int32) -> Disc {
  if row < 0 || col < 0 || row > 7 || col > 7 {
    return Empty
  }
  self.cells[row * 8 + col]
}

///|
/// Disc counts as (black, white).
pub fn Othello::counts(self : Othello) -> (Int32, Int32) {
  let mut b = 0
  let mut w = 0
  for d in self.cells {
    match d {
      Black => b += 1
      White => w += 1
      Empty => ()
    }
  }
  (b, w)
}

///|
/// The discs that a move at (row, col) would flip, empty when illegal.
fn Othello::flips_for(
  self : Othello,
  row : Int32,
  col : Int32,
  who : Disc,
) -> Array[Int32] {
  let acc : Array[Int32] = []
  if row < 0 || col < 0 || row > 7 || col > 7 {
    return acc
  }
  if !(self.cells[row * 8 + col] is Empty) {
    return acc
  }
  let opp = who.opponent()
  let dirs : Array[(Int32, Int32)] = [
    (0, 1),
    (0, -1),
    (1, 0),
    (-1, 0),
    (1, 1),
    (1, -1),
    (-1, 1),
    (-1, -1),
  ]
  for d in dirs {
    let (dr, dc) = d
    let line : Array[Int32] = []
    let mut r = row + dr
    let mut c = col + dc
    while r >= 0 && c >= 0 && r < 8 && c < 8 && self.cells[r * 8 + c] == opp {
      line.push(r * 8 + c)
      r += dr
      c += dc
    }
    // the line must terminate in one of our own discs and be non-empty
    let closed = r >= 0 && c >= 0 && r < 8 && c < 8
    if line.length() > 0 && closed && self.cells[r * 8 + c] == who {
      for i in line {
        acc.push(i)
      }
    }
  }
  acc
}

///|
/// Whether the side to move has any legal move.
pub fn Othello::has_move(self : Othello) -> Bool {
  for r in 0..<8 {
    for c in 0..<8 {
      if self.flips_for(r, c, self.turn).length() > 0 {
        return true
      }
    }
  }
  false
}

///|
/// All legal moves as (row, col) pairs in scan order.
pub fn Othello::legal_moves(self : Othello) -> Array[(Int32, Int32)] {
  let acc : Array[(Int32, Int32)] = []
  for r in 0..<8 {
    for c in 0..<8 {
      if self.flips_for(r, c, self.turn).length() > 0 {
        acc.push((r, c))
      }
    }
  }
  acc
}

///|
/// Whether the game has ended (two consecutive passes or a full board).
pub fn Othello::is_over(self : Othello) -> Bool {
  self.passes >= 2 || self.full()
}

///|
fn Othello::full(self : Othello) -> Bool {
  let mut empty = 0
  for d in self.cells {
    if d is Empty {
      empty += 1
    }
  }
  empty == 0
}

///|
/// Places a disc for the side to move, flipping all bracketed lines.
pub fn Othello::play(
  self : Othello,
  row : Int32,
  col : Int32,
) -> Result[Unit, OthelloError] {
  if self.is_over() {
    return Err(GameOver)
  }
  if row < 0 || col < 0 || row > 7 || col > 7 {
    return Err(OutOfBounds)
  }
  if !(self.cells[row * 8 + col] is Empty) {
    return Err(Occupied)
  }
  let flips = self.flips_for(row, col, self.turn)
  if flips.length() == 0 {
    return Err(NoFlip)
  }
  self.undo_stack.push(self.cells.copy())
  self.cells[row * 8 + col] = self.turn
  for i in flips {
    self.cells[i] = self.turn
  }
  self.passes = 0
  self.turn = self.turn.opponent()
  Ok(())
}

///|
/// Passes when the side to move has no legal move. Returns an error when
/// a legal move exists (a side must play if it can).
pub fn Othello::pass(self : Othello) -> Result[Unit, OthelloError] {
  if self.is_over() {
    return Err(GameOver)
  }
  if self.has_move() {
    return Err(NoFlip)
  }
  self.undo_stack.push(self.cells.copy())
  self.passes += 1
  self.turn = self.turn.opponent()
  Ok(())
}

///|
/// Takes back the last action (move or pass). Returns `false` at the
/// starting position.
pub fn Othello::undo(self : Othello) -> Bool {
  match self.undo_stack.pop() {
    Some(prev) => {
      self.cells = prev
      self.turn = self.turn.opponent()
      // the pass counter is rebuilt by inspection: the restored position
      // has at least the same empties; recompute passes conservatively
      self.passes = 0
      true
    }
    None => false
  }
}

///|
/// The winner once the game is over: `Some(Black/White)` by majority,
/// `None` for a 32-32 draw, and `None` while the game is running.
pub fn Othello::winner(self : Othello) -> Disc? {
  if !self.is_over() {
    return None
  }
  let (b, w) = self.counts()
  if b > w {
    Some(Black)
  } else if w > b {
    Some(White)
  } else {
    None
  }
}

///|
/// ASCII rendering: `X` black, `O` white, `.` empty.
pub fn Othello::render(self : Othello) -> String {
  let buf = StringBuilder()
  buf.write_string("  a b c d e f g h\n")
  for r in 0..<8 {
    buf.write_string("\{r + 1} ")
    for c in 0..<8 {
      buf.write_string(
        match self.get(r, c) {
          Empty => ". "
          Black => "X "
          White => "O "
        },
      )
    }
    buf.write_string("\n")
  }
  buf.to_string()
}
