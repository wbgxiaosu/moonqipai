///|
/// The four suits of a standard French deck.
pub(all) enum Suit {
  Spades
  Hearts
  Diamonds
  Clubs
} derive(Eq, Debug)

///|
pub extend Suit with Eq::{equal, not_equal}

///|
pub extend Suit with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Single-character symbol of the suit (pips).
pub fn Suit::symbol(self : Suit) -> String {
  match self {
    Spades => "s"
    Hearts => "h"
    Diamonds => "d"
    Clubs => "c"
  }
}

///|
/// All suits in declaration order.
pub fn Suit::all() -> Array[Suit] {
  [Spades, Hearts, Diamonds, Clubs]
}

///|
/// The thirteen ranks of a standard deck, deuce through ace.
pub(all) enum Rank {
  R2
  R3
  R4
  R5
  R6
  R7
  R8
  R9
  R10
  Jack
  Queen
  King
  Ace
} derive(Eq, Debug)

///|
pub extend Rank with Eq::{equal, not_equal}

///|
pub extend Rank with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Numeric value of the rank: deuce = 2 ... ace = 14 (aces high).
pub fn Rank::value(self : Rank) -> Int32 {
  match self {
    R2 => 2
    R3 => 3
    R4 => 4
    R5 => 5
    R6 => 6
    R7 => 7
    R8 => 8
    R9 => 9
    R10 => 10
    Jack => 11
    Queen => 12
    King => 13
    Ace => 14
  }
}

///|
/// Single-character text of the rank, as used in text card codes.
pub fn Rank::text(self : Rank) -> String {
  match self {
    R2 => "2"
    R3 => "3"
    R4 => "4"
    R5 => "5"
    R6 => "6"
    R7 => "7"
    R8 => "8"
    R9 => "9"
    R10 => "T"
    Jack => "J"
    Queen => "Q"
    King => "K"
    Ace => "A"
  }
}

///|
/// All ranks in ascending order.
pub fn Rank::all() -> Array[Rank] {
  [R2, R3, R4, R5, R6, R7, R8, R9, R10, Jack, Queen, King, Ace]
}

///|
/// A single playing card of a standard 52-card deck.
pub(all) struct Card {
  suit : Suit
  rank : Rank
} derive(Eq, Debug)

///|
pub extend Card with Eq::{equal, not_equal}

///|
pub extend Card with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Builds a card from a suit and rank.
pub fn Card::of(suit : Suit, rank : Rank) -> Card {
  { suit, rank, }
}

///|
/// Parses a two-character card code such as `As`, `Td` or `2c`.
/// Case-insensitive; returns `None` for malformed input.
pub fn Card::parse(text : String) -> Card? {
  if text.length() != 2 {
    return None
  }
  let chars = text.to_lower().to_array()
  let rank = match chars[0] {
    '2' => Some(R2)
    '3' => Some(R3)
    '4' => Some(R4)
    '5' => Some(R5)
    '6' => Some(R6)
    '7' => Some(R7)
    '8' => Some(R8)
    '9' => Some(R9)
    't' => Some(R10)
    'j' => Some(Jack)
    'q' => Some(Queen)
    'k' => Some(King)
    'a' => Some(Ace)
    _ => None
  }
  let suit = match chars[1] {
    's' => Some(Spades)
    'h' => Some(Hearts)
    'd' => Some(Diamonds)
    'c' => Some(Clubs)
    _ => None
  }
  match (rank, suit) {
    (Some(r), Some(s)) => Some({ suit: s, rank: r, })
    _ => None
  }
}

///|
/// Parses a list of card codes separated by whitespace or commas.
pub fn Card::parse_many(text : String) -> Array[Card]? {
  let acc : Array[Card] = []
  let mut cur = StringBuilder()
  for ch in text {
    if ch == ' ' || ch == ',' {
      if cur.to_string().length() > 0 {
        match Card::parse(cur.to_string()) {
          Some(c) => acc.push(c)
          None => return None
        }
        cur = StringBuilder()
      }
    } else {
      cur.write_char(ch)
    }
  }
  if cur.to_string().length() > 0 {
    match Card::parse(cur.to_string()) {
      Some(c) => acc.push(c)
      None => return None
    }
  }
  Some(acc)
}

///|
/// Two-character code of the card, e.g. `As`.
pub fn Card::text(self : Card) -> String {
  self.rank.text() + self.suit.symbol()
}
