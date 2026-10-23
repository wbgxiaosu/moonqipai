///|
/// A complete UNO game for 2..=8 players: the standard 108-card deck
/// (colour/number/action faces plus wilds), turn direction with skip /
/// reverse / draw-two / wild-draw-four effects, a draw pile that
/// reshuffles the discard pile when exhausted, per-seat hidden hands, and
/// a seeded shuffle so every deal replays exactly.
///
/// Simplifications (documented, deterministic): a starting non-number
/// card is re-shuffled away so the opening face is always a number; there
/// is no UNO-call penalty; a player who draws may play the drawn card
/// immediately or hold.
pub struct Uno {
  priv hands : Array[Array[Card]]
  priv mut draw_pile : Array[Card]
  priv mut discard : Array[Card]
  priv mut turn : Int
  /// +1 for clockwise seat order, -1 for counter-clockwise.
  priv mut direction : Int
  priv mut active_color : Color
  priv mut active_face : Kind
  /// Set right after a draw that produced a playable card.
  priv mut drawn : Bool
  priv mut winner : Int
  priv log : Array[String]
  priv rng : @core.Rng
}

///|
/// The size of every player's starting hand.
pub const STARTING_HAND : Int = 7

///|
/// Deals a game for `players` (2..=8) seats from a seeded shuffle.
pub fn Uno::new(players : Int, seed : UInt64) -> Uno {
  let n = if players < 2 {
    2
  } else if players > 8 {
    8
  } else {
    players
  }
  let hands : Array[Array[Card]] = []
  for _ in 0..<n {
    hands.push([])
  }
  let u = {
    hands,
    draw_pile: [],
    discard: [],
    turn: 0,
    direction: 1,
    active_color: Red,
    active_face: Number(0),
    drawn: false,
    winner: -1,
    log: [],
    rng: @core.Rng::new(seed),
  }
  u.build_deck()
  u.rng.shuffle(u.draw_pile)
  // deal seven cards per seat
  for s in 0..<n {
    for _ in 0..<STARTING_HAND {
      match u.take_from_pile() {
        Some(c) => u.hands[s].push(c)
        None => ()
      }
    }
  }
  // ensure the opening face is a plain number card
  while true {
    match u.draw_pile.get(0) {
      Some(c) =>
        match c.kind {
          Number(_) => break
          _ => {
            // move the non-number card to a random position in the pile
            let pos = u.rng.below(u.draw_pile.length())
            let moved = u.draw_pile.remove(0)
            u.draw_pile.insert(pos, moved)
          }
        }
      None => break
    }
  }
  let first = u.draw_pile.remove(0)
  u.discard.push(first)
  match first.color {
    Some(c) => {
      u.active_color = c
      u.active_face = first.kind
    }
    None => {
      u.active_color = Red
      u.active_face = first.kind
    }
  }
  u
}

///|
/// Builds the standard 108-card deck.
fn Uno::build_deck(self : Uno) -> Unit {
  for c in Color::all() {
    self.draw_pile.push({ color: Some(c), kind: Number(0) })
    for _ in 0..<2 {
      for n in 1..<10 {
        self.draw_pile.push({ color: Some(c), kind: Number(n) })
      }
      self.draw_pile.push({ color: Some(c), kind: Skip })
      self.draw_pile.push({ color: Some(c), kind: Reverse })
      self.draw_pile.push({ color: Some(c), kind: DrawTwo })
    }
  }
  for _ in 0..<4 {
    self.draw_pile.push({ color: None, kind: Wild })
    self.draw_pile.push({ color: None, kind: WildDrawFour })
  }
}

///|
/// Takes the top card of the draw pile, reshuffling the discard pile
/// (except its top card) when it runs dry.
fn Uno::take_from_pile(self : Uno) -> Card? {
  if self.draw_pile.length() == 0 && self.discard.length() > 1 {
    let top = self.discard.remove(self.discard.length() - 1)
    self.rng.shuffle(self.discard)
    self.draw_pile = self.discard
    self.discard = [top]
  }
  match self.draw_pile.pop() {
    Some(c) => Some(c)
    None => {
      // single-card deadlock: recycle the discard top is not allowed in
      // UNO; report exhaustion
      None
    }
  }
}

///|
/// Number of seats.
pub fn Uno::player_count(self : Uno) -> Int {
  self.hands.length()
}

///|
/// The seat whose turn it is.
pub fn Uno::turn(self : Uno) -> Int {
  self.turn
}

///|
/// The active colour every non-wild card must match.
pub fn Uno::active_color(self : Uno) -> Color {
  self.active_color
}

///|
/// The active face.
pub fn Uno::active_face(self : Uno) -> Kind {
  self.active_face
}

///|
/// Whether a drawn card is awaiting a play-or-hold decision.
pub fn Uno::drawn_pending(self : Uno) -> Bool {
  self.drawn
}

///|
/// The winner's seat index, or -1 while the game runs.
pub fn Uno::winner(self : Uno) -> Int {
  self.winner
}

///|
/// The public action log.
pub fn Uno::log(self : Uno) -> Array[String] {
  self.log
}

///|
/// The private hand of one seat — readable only by the seat's owner.
pub fn Uno::hand_of(self : Uno, seat : Int) -> Array[Card]? {
  match self.hands.get(seat) {
    Some(h) => Some(h)
    None => None
  }
}

///|
/// The visible top of the discard pile.
pub fn Uno::top(self : Uno) -> Card? {
  match self.discard.length() {
    0 => None
    n => self.discard.get(n - 1)
  }
}

///|
/// Whether the game has finished.
pub fn Uno::is_over(self : Uno) -> Bool {
  self.winner >= 0
}

///|
fn Uno::next_seat(self : Uno, from : Int, step : Int) -> Int {
  let n = self.hands.length()
  ((from + step * self.direction) % n + n) % n
}

///|
/// Whether the game has ended; the first empty hand wins.
fn Uno::check_win(self : Uno, seat : Int) -> Bool {
  if self.hands[seat].length() == 0 {
    self.winner = seat
    return true
  }
  false
}

///|
/// Applies one card's effects and advances the turn.
fn Uno::apply_card(self : Uno, seat : Int, card : Card, chosen : Color?) -> Unit {
  self.discard.push(card)
  self.log.push("p\{seat} plays \{card.text()}")
  match card.kind {
    Number(_) => {
      self.active_color = match card.color {
        Some(c) => c
        None => self.active_color
      }
      self.active_face = card.kind
      self.turn = self.next_seat(seat, 1)
    }
    Skip => {
      self.active_color = match card.color {
        Some(c) => c
        None => self.active_color
      }
      self.active_face = card.kind
      let skipped = self.next_seat(seat, 1)
      self.log.push("p\{skipped} is skipped")
      self.turn = self.next_seat(seat, 2)
    }
    Reverse => {
      self.direction = 0 - self.direction
      self.active_color = match card.color {
        Some(c) => c
        None => self.active_color
      }
      self.active_face = card.kind
      self.log.push("direction reversed")
      // with two players reverse acts like a skip: the same player goes again
      if self.hands.length() == 2 {
        self.turn = seat
      } else {
        self.turn = self.next_seat(seat, 1)
      }
    }
    DrawTwo => {
      self.active_color = match card.color {
        Some(c) => c
        None => self.active_color
      }
      self.active_face = card.kind
      let victim = self.next_seat(seat, 1)
      for _ in 0..<2 {
        match self.take_from_pile() {
          Some(c) => self.hands[victim].push(c)
          None => ()
        }
      }
      self.log.push("p\{victim} draws two and is skipped")
      self.turn = self.next_seat(seat, 2)
    }
    Wild => {
      self.active_color = match chosen {
        Some(c) => c
        None => self.active_color
      }
      self.active_face = Wild
      self.log.push("p\{seat} plays W")
      self.turn = self.next_seat(seat, 1)
    }
    WildDrawFour => {
      self.active_color = match chosen {
        Some(c) => c
        None => self.active_color
      }
      self.active_face = WildDrawFour
      let victim = self.next_seat(seat, 1)
      for _ in 0..<4 {
        match self.take_from_pile() {
          Some(c) => self.hands[victim].push(c)
          None => ()
        }
      }
      self.log.push("p\{victim} draws four and is skipped")
      self.turn = self.next_seat(seat, 2)
    }
  }
}

///|
/// Applies a player decision.
pub fn Uno::act(self : Uno, seat : Int, a : Action) -> Result[Unit, UnoError] {
  if self.is_over() {
    return Err(GameOver)
  }
  if seat < 0 || seat >= self.hands.length() {
    return Err(UnknownSeat)
  }
  if seat != self.turn {
    return Err(OutOfTurn)
  }
  match a {
    Play(idx, chosen) => {
      if self.drawn {
        return Err(NoDrawnCard)
      }
      let hand = self.hands[seat]
      if idx < 0 || idx >= hand.length() {
        return Err(NotYourCard)
      }
      let card = hand[idx]
      match card.playable_on(self.active_color, self.active_face) {
        true => {
          match card.kind {
            Wild => match chosen {
              None => return Err(WildNeedsColor)
              Some(_) => ()
            }
            WildDrawFour => match chosen {
              None => return Err(WildNeedsColor)
              Some(_) => ()
            }
            _ =>
              match chosen {
                Some(_) => return Err(NotPlayable("only wilds take a colour"))
                None => ()
              }
          }
          let _ = hand.remove(idx)
          self.apply_card(seat, card, chosen)
          let _ = self.check_win(seat)
          Ok(())
        }
        false => Err(NotPlayable("does not match the active colour or face"))
      }
    }
    Draw => {
      if self.drawn {
        return Err(NoDrawnCard)
      }
      match self.take_from_pile() {
        Some(c) => {
          self.hands[seat].push(c)
          self.log.push("p\{seat} draws")
          if c.playable_on(self.active_color, self.active_face) {
            self.drawn = true
            Ok(())
          } else {
            self.drawn = false
            self.turn = self.next_seat(seat, 1)
            Ok(())
          }
        }
        None => {
          // pile exhausted with a single discard: the turn passes
          self.log.push("p\{seat} draws (pile dry), passes")
          self.turn = self.next_seat(seat, 1)
          Ok(())
        }
      }
    }
    PlayDrawn(chosen) => {
      if !(self.drawn) {
        return Err(NoDrawnCard)
      }
      let hand = self.hands[seat]
      let idx = hand.length() - 1
      let card = hand[idx]
      match card.kind {
        Wild =>
          match chosen {
            None => return Err(WildNeedsColor)
            Some(_) => ()
          }
        WildDrawFour =>
          match chosen {
            None => return Err(WildNeedsColor)
            Some(_) => ()
          }
        _ => ()
      }
      let _ = hand.remove(idx)
      self.drawn = false
      self.apply_card(seat, card, chosen)
      let _ = self.check_win(seat)
      Ok(())
    }
    Hold => {
      if !(self.drawn) {
        return Err(NoDrawnCard)
      }
      self.drawn = false
      self.log.push("p\{seat} holds")
      self.turn = self.next_seat(seat, 1)
      Ok(())
    }
  }
}
