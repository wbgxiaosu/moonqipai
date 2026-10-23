///|
/// Betting decisions during a betting round. `Check` and `Call` are kept
/// separate so the log can distinguish a free continuation from a paid
/// one; `Raise` carries the *total* bet level the player moves to.
pub(all) enum BetAction {
  /// Withdraw from the hand.
  Fold
  /// Pass the action with no outstanding bet.
  Check
  /// Match the outstanding bet.
  Call
  /// Increase the outstanding bet to the given level.
  Raise(Int)
} derive(Eq, Debug)

///|
pub extend BetAction with Eq::{equal, not_equal}

///|
pub extend BetAction with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Failures of betting and discarding actions.
pub(all) enum BetError {
  OutOfTurn
  UnknownSeat
  AmountTooLow(Int)
  AlreadyFolded
  WrongPhase
  BadDiscards
} derive(Eq, Debug)

///|
pub extend BetError with Eq::{equal, not_equal}

///|
pub extend BetError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn BetError::message(self : BetError) -> String {
  match self {
    OutOfTurn => "it is not this player's turn"
    UnknownSeat => "no such seat at the table"
    AmountTooLow(need) => "the amount must reach \{need}"
    AlreadyFolded => "the player has already folded"
    WrongPhase => "the action is not valid in the current phase"
    BadDiscards => "discard indices must be 0..=4, at most three"
  }
}

///|
/// The phases of a five-card draw hand.
pub(all) enum Phase {
  /// First betting round after the deal.
  DealBetting
  /// Discard phase: each live player may replace up to three cards.
  Draw
  /// Second betting round after the draw.
  PostDrawBetting
  /// Showdown: the best five-card hand among live players wins.
  Showdown
} derive(Eq, Debug)

///|
pub extend Phase with Eq::{equal, not_equal}

///|
pub extend Phase with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// The fixed ante every player posts to see the deal.
pub const ANTE : Int = 1

///|
/// The minimum raise step above the current level.
pub const MIN_RAISE : Int = 5
