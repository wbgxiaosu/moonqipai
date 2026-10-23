///|
/// Player decisions during a turn.
pub(all) enum Action {
  /// Play the hand card at the given index; for wild cards a colour must
  /// be chosen.
  Play(Int, Color?)
  /// Draw one card. If the drawn card is playable, the player may then
  /// play it via [PlayDrawn] or hold via [Hold].
  Draw
  /// Play the card just drawn (only valid immediately after a [Draw]
  /// that produced a playable card). Wilds still need a colour choice.
  PlayDrawn(Color?)
  /// Decline to play the drawn card; the turn passes.
  Hold
} derive(Eq, Debug)

///|
pub extend Action with Eq::{equal, not_equal}

///|
pub extend Action with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Action failures with human-readable messages.
pub(all) enum UnoError {
  OutOfTurn
  UnknownSeat
  NotYourCard
  NotPlayable(String)
  WildNeedsColor
  NoDrawnCard
  GameOver
} derive(Eq, Debug)

///|
pub extend UnoError with Eq::{equal, not_equal}

///|
pub extend UnoError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn UnoError::message(self : UnoError) -> String {
  match self {
    OutOfTurn => "it is not this player's turn"
    UnknownSeat => "no such seat at the table"
    NotYourCard => "the card index is out of the player's hand"
    NotPlayable(why) => "the card cannot be played: \{why}"
    WildNeedsColor => "a wild card requires a colour choice"
    NoDrawnCard => "no drawn card is pending"
    GameOver => "the game is already over"
  }
}
