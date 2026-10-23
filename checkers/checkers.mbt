///|
/// Man colours on a checkers board.
pub(all) enum Man {
  Empty
  Black
  White
} derive(Eq, Debug)

///|
pub extend Man with Eq::{equal, not_equal}

///|
pub extend Man with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn Man::opponent(self : Man) -> Man {
  match self {
    Empty => Empty
    Black => White
    White => Black
  }
}

///|
/// A single move: origin square, destination square, and the intermediate
/// squares of a jump chain (empty for a simple diagonal step).
pub(all) struct Move {
  from : Int32
  to : Int32
  /// Captured square indices in chain order.
  captures : Array[Int32]
} derive(Eq, Debug)

///|
pub extend Move with Eq::{equal, not_equal}

///|
pub extend Move with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Move failures with human-readable messages.
pub(all) enum CheckersError {
  OutOfBounds
  NotYours
  NotMovable
  IncompleteJump
  MustContinueJump
  WrongDistance
  Occupied
  GameOver
} derive(Eq, Debug)

///|
pub extend CheckersError with Eq::{equal, not_equal}

///|
pub extend CheckersError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn CheckersError::message(self : CheckersError) -> String {
  match self {
    OutOfBounds => "square out of bounds"
    NotYours => "that is not your piece"
    NotMovable => "the piece cannot move there"
    IncompleteJump => "a jump must land two squares away"
    MustContinueJump => "a jump chain must continue while jumps exist"
    WrongDistance => "a king may only jump one enemy piece at a time"
    Occupied => "the destination is occupied"
    GameOver => "the game is already over"
  }
}

///|
/// A standard English-draughts position on an 8x8 board: twelve pieces
/// per side on the dark squares, black moves first, captures are
/// mandatory and jump chains must be completed, pieces crown on the far
/// rank, kings move and capture in all four diagonal directions.
pub struct Checkers {
  /// Square index 0..=63, row-major from the top-left; dark squares hold
  /// pieces.
  priv mut cells : Array[Man]
  priv mut kings : Array[Bool]
  priv mut turn : Man
  /// During a jump chain: the square of the piece that must keep jumping.
  priv mut chain : Int32
  priv undo_stack : Array[(Array[Man], Array[Bool], Man, Int32)]
  priv mut move_count : Int32
}

///|
/// Creates the classical starting position.
pub fn Checkers::new() -> Checkers {
  let cells : Array[Man] = []
  let kings : Array[Bool] = []
  for i in 0..<64 {
    let r = i / 8
    let c = i % 8
    let dark = (r + c) % 2 == 1
    let m = if dark && r < 3 {
      Black
    } else if dark && r > 4 {
      White
    } else {
      Empty
    }
    cells.push(m)
    kings.push(false)
  }
  { cells, kings, turn: Black, chain: -1, undo_stack: [], move_count: 0, }
}

///|
/// Reads a square.
pub fn Checkers::get(self : Checkers, index : Int32) -> Man {
  if index < 0 || index > 63 {
    return Empty
  }
  self.cells[index]
}

///|
/// Whether the piece on a square is crowned.
pub fn Checkers::is_king(self : Checkers, index : Int32) -> Bool {
  if index < 0 || index > 63 {
    return false
  }
  self.kings[index]
}

///|
/// The side to move.
pub fn Checkers::turn(self : Checkers) -> Man {
  self.turn
}

///|
/// Whether a jump chain is in progress (the mover must keep jumping).
pub fn Checkers::jump_pending(self : Checkers) -> Bool {
  self.chain >= 0
}

///|
/// Number of actions played so far.
pub fn Checkers::move_count(self : Checkers) -> Int32 {
  self.move_count
}

///|
fn dark(index : Int32) -> Bool {
  let r = index / 8
  let c = index % 8
  (r + c) % 2 == 1
}

///|
/// Piece colour sign: black pieces move down the board (increasing row).
fn forward_delta(who : Man) -> Int32 {
  if who is Black {
    1
  } else {
    -1
  }
}

///|
/// Enumerates every legal action for the side to move: if a jump exists
/// anywhere, only jumps are listed (captures are mandatory).
pub fn Checkers::legal_moves(self : Checkers) -> Array[Move] {
  let acc : Array[Move] = []
  if self.chain >= 0 {
    // continue the chain with the same piece
    for m in self.jumps_from(self.chain) {
      acc.push(m)
    }
    return acc
  }
  let jumps : Array[Move] = []
  for i in 0..<64 {
    if self.cells[i] == self.turn {
      for m in self.jumps_from(i) {
        jumps.push(m)
      }
    }
  }
  if jumps.length() > 0 {
    for m in jumps {
      acc.push(m)
    }
    return acc
  }
  for i in 0..<64 {
    if self.cells[i] == self.turn {
      for m in self.steps_from(i) {
        acc.push(m)
      }
    }
  }
  acc
}

///|
fn Checkers::steps_from(self : Checkers, i : Int32) -> Array[Move] {
  let acc : Array[Move] = []
  let r = i / 8
  let c = i % 8
  let who = self.cells[i]
  let dirs : Array[(Int32, Int32)] = if self.kings[i] {
    [(1, 1), (1, -1), (-1, 1), (-1, -1)]
  } else {
    let f = forward_delta(who)
    [(f, 1), (f, -1)]
  }
  for d in dirs {
    let (dr, dc) = d
    let nr = r + dr
    let nc = c + dc
    if nr < 0 || nr > 7 || nc < 0 || nc > 7 {
      continue
    }
    let t = nr * 8 + nc
    if self.cells[t] is Empty {
      acc.push({ from: i, to: t, captures: [], })
    }
  }
  acc
}

///|
fn Checkers::jumps_from(self : Checkers, i : Int32) -> Array[Move] {
  let acc : Array[Move] = []
  let r = i / 8
  let c = i % 8
  let who = self.cells[i]
  let opp = who.opponent()
  let dirs : Array[(Int32, Int32)] = if self.kings[i] {
    [(1, 1), (1, -1), (-1, 1), (-1, -1)]
  } else {
    let f = forward_delta(who)
    [(f, 1), (f, -1)]
  }
  for d in dirs {
    let (dr, dc) = d
    let mr = r + dr
    let mc = c + dc
    let lr = r + 2 * dr
    let lc = c + 2 * dc
    if lr < 0 || lr > 7 || lc < 0 || lc > 7 {
      continue
    }
    let mid = mr * 8 + mc
    let land = lr * 8 + lc
    if self.cells[mid] == opp && self.cells[land] is Empty {
      acc.push({ from: i, to: land, captures: [mid], })
    }
  }
  acc
}

///|
/// Whether the game has ended: the side to move has no legal action
/// (eliminated or blocked).
pub fn Checkers::is_over(self : Checkers) -> Bool {
  self.legal_moves().length() == 0
}

///|
/// The winning colour once the game is over; `None` while running or on
/// a blocked deadlock (which scores as a draw for tooling purposes).
pub fn Checkers::winner(self : Checkers) -> Man? {
  if !self.is_over() {
    return None
  }
  // count material: a blocked side with pieces still on the board is a
  // draw-like deadlock
  let mut black = 0
  let mut white = 0
  for m in self.cells {
    match m {
      Black => black += 1
      White => white += 1
      Empty => ()
    }
  }
  if black == 0 {
    Some(White)
  } else if white == 0 {
    Some(Black)
  } else {
    None
  }
}

///|
/// Executes a move. During a jump chain only continuations of the same
/// piece are accepted, and the chain must be played out.
pub fn Checkers::play(self : Checkers, m : Move) -> Result[Unit, CheckersError] {
  if self.is_over() && self.chain < 0 {
    return Err(GameOver)
  }
  let legal = self.legal_moves()
  let mut found : Move? = None
  for lm in legal {
    if lm.from == m.from &&
      lm.to == m.to &&
      lm.captures.length() == m.captures.length() {
      found = Some(lm)
    }
  }
  match found {
    None => {
      // classify the failure for better messages
      if m.from < 0 || m.from > 63 || m.to < 0 || m.to > 63 {
        return Err(OutOfBounds)
      }
      if !(self.cells[m.from] == self.turn) {
        return Err(NotYours)
      }
      if m.captures.length() == 0 {
        return Err(NotMovable)
      }
      if self.chain >= 0 && m.from != self.chain {
        return Err(MustContinueJump)
      }
      return Err(NotMovable)
    }
    Some(real) => {
      self.undo_stack.push(
        (self.cells.copy(), self.kings.copy(), self.turn, self.chain),
      )
      // move the piece
      self.cells[m.to] = self.cells[m.from]
      self.cells[m.from] = Empty
      self.kings[m.to] = self.kings[m.from]
      self.kings[m.from] = false
      // remove captured pieces
      for cap in real.captures {
        self.cells[cap] = Empty
        self.kings[cap] = false
      }
      // crowning
      let row = m.to / 8
      if !self.kings[m.to] {
        if self.turn is Black && row == 7 {
          self.kings[m.to] = true
        }
        if self.turn is White && row == 0 {
          self.kings[m.to] = true
        }
      }
      self.move_count += 1
      // jump chain continuation
      if real.captures.length() > 0 {
        let more = self.jumps_from(m.to)
        if more.length() > 0 {
          self.chain = m.to
          return Ok(())
        }
      }
      self.chain = -1
      self.turn = self.turn.opponent()
      Ok(())
    }
  }
}

///|
/// Takes back the last action, including mid-chain states.
pub fn Checkers::undo(self : Checkers) -> Bool {
  match self.undo_stack.pop() {
    Some((cells, kings, turn, chain)) => {
      self.cells = cells
      self.kings = kings
      self.turn = turn
      self.chain = chain
      self.move_count -= 1
      true
    }
    None => false
  }
}

///|
/// ASCII rendering: `b/w` men, `B/W` kings, `.` empty, `-` light square.
pub fn Checkers::render(self : Checkers) -> String {
  let buf = StringBuilder()
  buf.write_string("  a b c d e f g h\n")
  for r in 0..<8 {
    buf.write_string("\{r + 1} ")
    for c in 0..<8 {
      let i = r * 8 + c
      if !dark(i) {
        buf.write_string("- ")
      } else {
        match self.cells[i] {
          Empty => buf.write_string(". ")
          Black =>
            if self.kings[i] {
              buf.write_string("B ")
            } else {
              buf.write_string("b ")
            }
          White =>
            if self.kings[i] {
              buf.write_string("W ")
            } else {
              buf.write_string("w ")
            }
        }
      }
    }
    buf.write_string("\n")
  }
  buf.to_string()
}
