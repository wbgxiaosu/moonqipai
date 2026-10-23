///|
/// A player decision after the initial deal.
pub(all) enum Action {
  /// Take another card.
  Hit
  /// Stop drawing; the dealer completes its hand.
  Stand
} derive(Eq, Debug)

///|
pub extend Action with Eq::{equal, not_equal}

///|
pub extend Action with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Terminal settlement. `PlayerWin(payout)` carries the total returned to
/// the player including the stake (1.0 for an even-money win, 2.5 for a
/// natural blackjack paid 3:2); `Push` returns the stake.
pub(all) enum Settlement {
  PlayerWin(Double)
  DealerWin
  Push
} derive(Eq, Debug)

///|
pub extend Settlement with Eq::{equal, not_equal}

///|
pub extend Settlement with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// A single hand of casino blackjack against one dealer, with a fixed
/// one-unit stake. Randomness comes from a seeded 52-card shuffle, so
/// every deal is reproducible. The dealer's hole card is hidden until the
/// player stands or busts — `dealer_hand()` only exposes the upcard while
/// the hand is running, which makes this engine a usable reference for
/// hidden-information tooling.
pub struct Blackjack {
  priv deck : @cards.Deck
  priv player : Array[@cards.Card]
  priv dealer : Array[@cards.Card]
  priv mut done : Bool
  priv mut result : Settlement?
}

///|
/// Deals a new hand from a seeded shuffle.
pub fn Blackjack::new(seed : UInt64) -> Blackjack {
  let deck = @cards.Deck::shuffled(seed)
  let player = deck.deal(2)
  let dealer = deck.deal(2)
  let b = {
    deck,
    player,
    dealer,
    done: false,
    result: None,
  }
  // naturals settle immediately
  if hand_value(b.player) == 21 {
    if hand_value(b.dealer) == 21 {
      b.done = true
      b.result = Some(Push)
    } else {
      b.done = true
      b.result = Some(PlayerWin(2.5))
    }
  }
  b
}

///|
/// Point value of a hand: aces count 11 while the total stays <= 21,
/// otherwise 1.
pub fn hand_value(cards : Array[@cards.Card]) -> Int {
  let mut total = 0
  let mut aces = 0
  for c in cards {
    let v = c.rank.value()
    if v == 14 {
      aces += 1
      total += 11
    } else if v > 10 {
      total += 10
    } else {
      total += v
    }
  }
  while total > 21 && aces > 0 {
    total -= 10
    aces -= 1
  }
  total
}

///|
/// The player's cards (always fully visible to the player).
pub fn Blackjack::player_hand(self : Blackjack) -> Array[@cards.Card] {
  self.player
}

///|
/// The player's point total.
pub fn Blackjack::player_total(self : Blackjack) -> Int {
  hand_value(self.player)
}

///|
/// The dealer's visible upcard while the hand runs; the full hand after
/// settlement.
pub fn Blackjack::dealer_upcard(self : Blackjack) -> @cards.Card? {
  self.dealer.get(0)
}

///|
/// The dealer's complete hand; only meaningful once the hand is over.
pub fn Blackjack::dealer_hand(self : Blackjack) -> Array[@cards.Card]? {
  if self.done {
    Some(self.dealer)
  } else {
    None
  }
}

///|
/// Whether the hand has been settled.
pub fn Blackjack::is_over(self : Blackjack) -> Bool {
  self.done
}

///|
/// The settlement, available only after the hand is over.
pub fn Blackjack::result(self : Blackjack) -> Settlement? {
  self.result
}

///|
/// Applies a player decision. Hitting past 21 busts immediately; standing
/// lets the dealer draw to 17 and compares totals.
pub fn Blackjack::act(self : Blackjack, a : Action) -> Result[Unit, String] {
  if self.done {
    return Err("the hand is already settled")
  }
  match a {
    Hit => {
      let drawn = self.deck.deal(1)
      match drawn.get(0) {
        Some(c) => self.player.push(c)
        None => return Err("the shoe is empty")
      }
      if hand_value(self.player) > 21 {
        self.done = true
        self.result = Some(DealerWin)
      }
      Ok(())
    }
    Stand => {
      self.done = true
      let pt = hand_value(self.player)
      if pt > 21 {
        self.result = Some(DealerWin)
        return Ok(())
      }
      // dealer draws until reaching 17 or more (stands on soft 17 for a
      // fixed, deterministic rule)
      while hand_value(self.dealer) < 17 {
        match self.deck.deal(1).get(0) {
          Some(c) => self.dealer.push(c)
          None => break
        }
      }
      let dt = hand_value(self.dealer)
      if dt > 21 || dt < pt {
        self.result = Some(PlayerWin(2.0))
      } else if dt == pt {
        self.result = Some(Push)
      } else {
        self.result = Some(DealerWin)
      }
      Ok(())
    }
  }
}
