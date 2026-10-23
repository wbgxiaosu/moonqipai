///|
/// The four UNO card colours.
pub(all) enum Color {
  Red
  Yellow
  Green
  Blue
} derive(Eq, Debug)

///|
pub extend Color with Eq::{equal, not_equal}

///|
pub extend Color with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// All colours in declaration order.
pub fn Color::all() -> Array[Color] {
  [Red, Yellow, Green, Blue]
}

///|
/// One-letter symbol of a colour.
pub fn Color::symbol(self : Color) -> String {
  match self {
    Red => "R"
    Yellow => "Y"
    Green => "G"
    Blue => "B"
  }
}

///|
/// Card faces. `Number(n)` covers 0..=9; the action faces are Skip,
/// Reverse and DrawTwo; the wild faces carry no printed colour.
pub(all) enum Kind {
  Number(Int32)
  Skip
  Reverse
  DrawTwo
  Wild
  WildDrawFour
} derive(Eq, Debug)

///|
pub extend Kind with Eq::{equal, not_equal}

///|
pub extend Kind with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Whether two non-wild faces match (same number or same symbol).
pub fn Kind::matches(self : Kind, other : Kind) -> Bool {
  match (self, other) {
    (Number(a), Number(b)) => a == b
    (Skip, Skip) => true
    (Reverse, Reverse) => true
    (DrawTwo, DrawTwo) => true
    _ => false
  }
}

///|
/// A UNO card. Wild cards are dealt colourless; the active colour is
/// chosen when they are played and tracked by the game.
pub(all) struct Card {
  /// The printed colour; `None` for wild cards.
  color : Color?
  kind : Kind
} derive(Eq, Debug)

///|
pub extend Card with Eq::{equal, not_equal}

///|
pub extend Card with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Text code of the card, e.g. `R7`, `GSK`, `W` or `W4`.
pub fn Card::text(self : Card) -> String {
  let prefix = match self.color {
    Some(c) => c.symbol()
    None => ""
  }
  let body = match self.kind {
    Number(n) => "\{n}"
    Skip => "SK"
    Reverse => "RV"
    DrawTwo => "D2"
    Wild => "W"
    WildDrawFour => "W4"
  }
  prefix + body
}

///|
/// Whether the card can legally be played onto the given active colour
/// and face. Wild cards always match.
pub fn Card::playable_on(self : Card, color : Color, face : Kind) -> Bool {
  match self.kind {
    Wild => true
    WildDrawFour => true
    _ =>
      match self.color {
        Some(c) => c == color || self.kind.matches(face)
        None => false
      }
  }
}
