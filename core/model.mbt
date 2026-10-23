///|
/// Identifiers for the games the unified engine layer covers.
pub(all) enum GameId {
  /// Go (Weiqi/Baduk) with the given board size (2..=26) and komi.
  Go(Int32, Double)
  /// Chinese chess (Xiangqi), standard initial position.
  Xiangqi
  /// International chess, standard initial position.
  Chess
  /// Free-style Gomoku with the given board size (2..=26).
  Gomoku(Int32)
  /// Othello (Reversi), standard 8x8 initial position.
  Othello
} derive(Eq, Debug)

///|
pub extend GameId with Eq::{equal, not_equal}

///|
pub extend GameId with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Player identity normalised across games: the side that moves first is
/// `P1` (Black in Go, Red in Xiangqi, White in chess), the other is `P2`.
pub(all) enum Player {
  P1
  P2
} derive(Eq, Debug)

///|
pub extend Player with Eq::{equal, not_equal}

///|
pub extend Player with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// The opponent of the given player.
pub fn Player::opponent(self : Player) -> Player {
  match self {
    P1 => P2
    P2 => P1
  }
}

///|
/// The conventional label of a player in a given game, e.g. "B"/"W" for Go,
/// "Red"/"Black" for Xiangqi, "White"/"Black" for chess.
pub fn Player::label(self : Player, game : GameId) -> String {
  let first = match game {
    Go(_, _) => "B"
    Xiangqi => "Red"
    Chess => "White"
    Gomoku(_) => "B"
    Othello => "Black"
  }
  let second = match game {
    Go(_, _) => "W"
    Xiangqi => "Black"
    Chess => "Black"
    Gomoku(_) => "W"
    Othello => "White"
  }
  match self {
    P1 => first
    P2 => second
  }
}

///|
/// Terminal game result normalised across games.
pub(all) enum Outcome {
  /// One side won outright (checkmate, capture of the general, etc.).
  Winner(Player)
  /// Drawn game (stalemate in chess, agreed draw, ...).
  Draw
  /// Win by counted margin, as in area scoring in Go ("B+2.5").
  Score(Player, Double)
} derive(Eq, Debug)

///|
pub extend Outcome with Eq::{equal, not_equal}

///|
pub extend Outcome with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Record-style result string ("1-0", "0-1", "1/2-1/2").
pub fn Outcome::record_string(self : Outcome) -> String {
  match self {
    Winner(P1) => "1-0"
    Winner(P2) => "0-1"
    Draw => "1/2-1/2"
    Score(P1, _) => "1-0"
    Score(P2, _) => "0-1"
  }
}

///|
/// Game-conventional result string: Go uses "B+2.5"-style margins,
/// Xiangqi and chess use record notation.
pub fn Outcome::describe(self : Outcome, game : GameId) -> String {
  match self {
    Winner(_) => self.record_string()
    Draw => self.record_string()
    Score(p, margin) => "\{p.label(game)}+\{margin}"
  }
}

///|
/// Failure modes of the unified engine interface. The message is
/// human-readable and safe to surface to end users.
pub(all) enum EngineError {
  /// The move text is not recognisable in the game's notation.
  UnknownMove(String)
  /// The move is well-formed but illegal in the current position.
  IllegalMove(String)
  /// The game has already ended; no further moves are accepted.
  GameOver
} derive(Eq, Debug)

///|
pub extend EngineError with Eq::{equal, not_equal}

///|
pub extend EngineError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn EngineError::message(self : EngineError) -> String {
  match self {
    UnknownMove(s) => "unknown move: \{s}"
    IllegalMove(s) => "illegal move: \{s}"
    GameOver => "the game is already over"
  }
}

///|
/// The default komi used when constructing Go positions.
pub const DEFAULT_KOMI : Double = 7.5

///|
/// The default board size used when constructing Go positions.
pub const DEFAULT_BOARD_SIZE : Int32 = 19
