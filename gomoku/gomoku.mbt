///|
/// Stone colours on a Gomoku board.
pub(all) enum Stone {
  Empty
  Black
  White
} derive(Eq, Debug)

///|
pub extend Stone with Eq::{equal, not_equal}

///|
pub extend Stone with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn Stone::opponent(self : Stone) -> Stone {
  match self {
    Empty => Empty
    Black => White
    White => Black
  }
}

///|
/// Failure modes of a Gomoku move.
pub(all) enum MoveError {
  OutOfBounds
  Occupied
  GameOver
} derive(Eq, Debug)

///|
pub extend MoveError with Eq::{equal, not_equal}

///|
pub extend MoveError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn MoveError::message(self : MoveError) -> String {
  match self {
    OutOfBounds => "coordinates out of bounds"
    Occupied => "the point is already occupied"
    GameOver => "the game is already over"
  }
}

///|
/// A free-style Gomoku position (no forbidden-move rules): `size x size`
/// board, black moves first, five or more in a row wins, a full board
/// without a line is a draw. All state changes go through the same
/// `play` / `undo` discipline as the other engines in this library.
pub struct Gomoku {
  priv size : Int32
  priv cells : Array[Stone]
  priv mut turn : Stone
  priv mut winner : Stone
  priv mut moves_played : Int32
  priv undo_stack : Array[Int32]
}

///|
/// Creates an empty `size x size` position (2..=26).
pub fn Gomoku::new(size : Int32) -> Gomoku {
  let cells : Array[Stone] = []
  let n = size * size
  for _ in 0..<n {
    cells.push(Empty)
  }
  { size, cells, turn: Black, winner: Empty, moves_played: 0, undo_stack: [], }
}

///|
/// The default 15x15 board.
pub fn Gomoku::standard() -> Gomoku {
  Gomoku::new(15)
}

///|
/// The board size.
pub fn Gomoku::size(self : Gomoku) -> Int32 {
  self.size
}

///|
/// The side to move.
pub fn Gomoku::turn(self : Gomoku) -> Stone {
  self.turn
}

///|
/// The colour that completed a line, or `Empty` while running (and for a
/// draw).
pub fn Gomoku::winner(self : Gomoku) -> Stone {
  self.winner
}

///|
/// Whether the game has ended (win or full-board draw).
pub fn Gomoku::is_over(self : Gomoku) -> Bool {
  !(self.winner is Empty) || self.moves_played == self.size * self.size
}

///|
/// Number of stones on the board.
pub fn Gomoku::stone_count(self : Gomoku) -> Int32 {
  self.moves_played
}

///|
/// Reads a point; out-of-range indices yield `Empty`.
pub fn Gomoku::get(self : Gomoku, row : Int32, col : Int32) -> Stone {
  if row < 0 || col < 0 || row >= self.size || col >= self.size {
    return Empty
  }
  self.cells[row * self.size + col]
}

///|
fn Gomoku::set(self : Gomoku, row : Int32, col : Int32, s : Stone) -> Unit {
  self.cells[row * self.size + col] = s
}

///|
/// Whether the move is inside the board and the point is empty.
pub fn Gomoku::is_legal(self : Gomoku, row : Int32, col : Int32) -> Bool {
  if row < 0 || col < 0 || row >= self.size || col >= self.size {
    return false
  }
  self.get(row, col) is Empty
}

///|
/// All legal moves as (row, col) pairs in scan order.
pub fn Gomoku::legal_moves(self : Gomoku) -> Array[(Int32, Int32)] {
  let acc : Array[(Int32, Int32)] = []
  if !(self.winner is Empty) {
    return acc
  }
  let n = self.size * self.size
  for i in 0..<n {
    if self.cells[i] is Empty {
      acc.push((i / self.size, i % self.size))
    }
  }
  acc
}

///|
/// Places a stone for the side to move. Alternation is enforced: the
/// stone colour always equals the current turn.
pub fn Gomoku::play(
  self : Gomoku,
  row : Int32,
  col : Int32,
) -> Result[Unit, MoveError] {
  if !(self.winner is Empty) {
    return Err(GameOver)
  }
  if !self.is_legal(row, col) {
    if row < 0 || col < 0 || row >= self.size || col >= self.size {
      return Err(OutOfBounds)
    }
    return Err(Occupied)
  }
  self.undo_stack.push(row * self.size + col)
  self.set(row, col, self.turn)
  self.moves_played += 1
  if self.has_line_at(row, col) {
    self.winner = self.turn
  } else {
    self.turn = self.turn.opponent()
  }
  Ok(())
}

///|
/// Takes back the last stone. Returns `false` at the starting position.
pub fn Gomoku::undo(self : Gomoku) -> Bool {
  match self.undo_stack.pop() {
    Some(i) => {
      self.set(i / self.size, i % self.size, Empty)
      self.moves_played -= 1
      if !(self.winner is Empty) {
        // the retracted stone was the winning move: restore its colour
        self.turn = self.winner
        self.winner = Empty
      } else {
        self.turn = self.turn.opponent()
      }
      true
    }
    None => false
  }
}

///|
/// Whether the stone just placed at (row, col) completes a line of five
/// or more in any of the four directions.
fn Gomoku::has_line_at(self : Gomoku, row : Int32, col : Int32) -> Bool {
  let dirs : Array[(Int32, Int32)] = [(0, 1), (1, 0), (1, 1), (1, -1)]
  let s = self.get(row, col)
  for d in dirs {
    let (dr, dc) = d
    let mut count = 1
    // scan both ways from the placed stone
    let mut r = row + dr
    let mut c = col + dc
    while self.get(r, c) == s {
      count += 1
      r += dr
      c += dc
    }
    r = row - dr
    c = col - dc
    while self.get(r, c) == s {
      count += 1
      r -= dr
      c -= dc
    }
    if count >= 5 {
      return true
    }
  }
  false
}

///|
/// ASCII rendering: header with column letters, rows top-down.
pub fn Gomoku::render(self : Gomoku) -> String {
  let letters : Array[Char] = "abcdefghijklmno".to_array()
  let buf = StringBuilder()
  buf.write_string("   ")
  for c in 0..<self.size {
    buf.write_char(letters[c])
    buf.write_string(" ")
  }
  buf.write_string("\n")
  for r in 0..<self.size {
    let label = if r + 1 < 10 { " \{r + 1}" } else { "\{r + 1}" }
    buf.write_string("\{label} ")
    for c in 0..<self.size {
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
