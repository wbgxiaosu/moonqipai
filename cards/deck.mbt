///|
/// A deck of cards with a deal cursor. The deck itself is deterministic:
/// [Deck::standard52] yields the factory order, [Deck::shuffled] applies a
/// seeded splitmix64 Fisher-Yates shuffle so any deal can be reproduced.
pub struct Deck {
  priv cards : Array[Card]
  priv mut next : Int32
}

///|
/// The factory order of a standard 52-card deck: spades, hearts, diamonds,
/// clubs, each from deuce to ace.
pub fn Deck::standard52() -> Deck {
  let cards : Array[Card] = []
  for suit in Suit::all() {
    for rank in Rank::all() {
      cards.push({ suit, rank, })
    }
  }
  { cards, next: 0, }
}

///|
/// A deterministically shuffled 52-card deck. Two decks built with the
/// same seed produce the exact same deal order, which makes games
/// reproducible and testable.
pub fn Deck::shuffled(seed : UInt64) -> Deck {
  let deck = Deck::standard52()
  let mut state = seed
  // Fisher-Yates from the top using splitmix64 draws
  let n = deck.cards.length()
  for k in 0..<(n - 1) {
    let i = n - 1 - k
    let (s, r) = splitmix64(state)
    state = s
    let j = (r % (i.to_uint64() + 1UL)).to_int()
    let tmp = deck.cards[i]
    deck.cards[i] = deck.cards[j]
    deck.cards[j] = tmp
  }
  deck
}

///|
/// splitmix64: returns (next state, 64-bit random value).
fn splitmix64(state : UInt64) -> (UInt64, UInt64) {
  let z = state + 0x9E3779B97F4A7C15UL
  let mut r = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL
  r = (r ^ (r >> 27)) * 0x94D049BB133111EBUL
  r = r ^ (r >> 31)
  (z, r)
}

///|
/// The number of cards left to deal.
pub fn Deck::remaining(self : Deck) -> Int32 {
  self.cards.length() - self.next
}

///|
/// Deals up to `n` cards from the top. Returns fewer than `n` cards only
/// when the deck runs out.
pub fn Deck::deal(self : Deck, n : Int32) -> Array[Card] {
  let acc : Array[Card] = []
  let mut count = 0
  while count < n && self.next < self.cards.length() {
    acc.push(self.cards[self.next])
    self.next += 1
    count += 1
  }
  acc
}

///|
/// Resets the deck to its full order (as built), preserving the current
/// ordering.
pub fn Deck::reset(self : Deck) -> Unit {
  self.next = 0
}
