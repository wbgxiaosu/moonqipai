///|
/// A seat at the table. `hand` is private information; the engine only
/// exposes it through [DrawPoker::hand_of] for the seat's owner.
priv struct Seat {
  hand : Array[@cards.Card]
  mut chips : Int32
  mut live : Bool
  mut bet : Int32
}

///|
/// A complete five-card draw hand for 2..=6 players: deal, betting round,
/// draw, second betting round, showdown. Hidden information is explicit —
/// each seat only sees its own cards plus the public action log, and live
/// hands are revealed only at showdown. All randomness flows from one
/// seeded shuffle, so the whole hand replays bit-for-bit from the seed.
pub struct DrawPoker {
  priv seats : Array[Seat]
  priv deck : @cards.Deck
  priv mut phase : Phase
  priv mut turn : Int32
  /// The outstanding bet level to match.
  priv mut level : Int32
  /// Live seats that still owe an action before the round ends.
  priv mut pending : Int32
  priv mut pot : Int32
  priv mut winner : Int32
  priv log : Array[String]
}

///|
/// Deals a hand for `players` (2..=6) seats from a seeded shuffle.
pub fn DrawPoker::new(players : Int32, seed : UInt64) -> DrawPoker {
  let n = if players < 2 { 2 } else if players > 6 { 6 } else { players }
  let seats : Array[Seat] = []
  for _ in 0..<n {
    seats.push({ hand: [], chips: 100, live: true, bet: 0, })
  }
  let deck = @cards.Deck::shuffled(seed)
  let p = {
    seats,
    deck,
    phase: DealBetting,
    turn: 0,
    level: ANTE,
    pending: n,
    pot: 0,
    winner: -1,
    log: [],
  }
  for s in p.seats {
    s.chips -= ANTE
    s.bet = ANTE
    p.pot += ANTE
    for card in p.deck.deal(5) {
      s.hand.push(card)
    }
  }
  p
}

///|
/// Number of seats.
pub fn DrawPoker::player_count(self : DrawPoker) -> Int32 {
  self.seats.length()
}

///|
/// The current phase.
pub fn DrawPoker::phase(self : DrawPoker) -> Phase {
  self.phase
}

///|
/// The seat whose action is expected.
pub fn DrawPoker::turn(self : DrawPoker) -> Int32 {
  self.turn
}

///|
/// The outstanding bet level to match.
pub fn DrawPoker::bet_level(self : DrawPoker) -> Int32 {
  self.level
}

///|
/// The pot size.
pub fn DrawPoker::pot(self : DrawPoker) -> Int32 {
  self.pot
}

///|
/// The public action log (safe to show to everyone).
pub fn DrawPoker::log(self : DrawPoker) -> Array[String] {
  self.log
}

///|
/// The winner's seat index, or -1 while the hand runs.
pub fn DrawPoker::winner(self : DrawPoker) -> Int32 {
  self.winner
}

///|
/// The private hand of one seat — the *only* sanctioned way to read the
/// hidden information, intended for the seat's owner.
pub fn DrawPoker::hand_of(
  self : DrawPoker,
  seat : Int32,
) -> Array[@cards.Card]? {
  match self.seats.get(seat) {
    Some(s) => Some(s.hand)
    None => None
  }
}

///|
/// Whether a seat is still in the hand.
pub fn DrawPoker::is_live(self : DrawPoker, seat : Int32) -> Bool {
  match self.seats.get(seat) {
    Some(s) => s.live
    None => false
  }
}

///|
/// Chip count of a seat.
pub fn DrawPoker::chips_of(self : DrawPoker, seat : Int32) -> Int32 {
  match self.seats.get(seat) {
    Some(s) => s.chips
    None => 0
  }
}

///|
fn DrawPoker::live_count(self : DrawPoker) -> Int32 {
  let mut n = 0
  for s in self.seats {
    if s.live {
      n += 1
    }
  }
  n
}

///|
fn DrawPoker::next_live_from(self : DrawPoker, start : Int32) -> Int32 {
  let n = self.seats.length()
  let mut i = start % n
  let mut steps = 0
  while steps < n {
    if self.seats[i].live {
      return i
    }
    i = (i + 1) % n
    steps += 1
  }
  start
}

///|
fn DrawPoker::advance_turn(self : DrawPoker) -> Unit {
  self.turn = self.next_live_from(self.turn + 1)
}

///|
/// Whether the hand has finished.
pub fn DrawPoker::is_over(self : DrawPoker) -> Bool {
  self.phase is Showdown
}

///|
/// Applies a betting action for the given seat.
pub fn DrawPoker::bet(
  self : DrawPoker,
  seat : Int32,
  a : BetAction,
) -> Result[Unit, BetError] {
  if !(self.phase is DealBetting) && !(self.phase is PostDrawBetting) {
    return Err(WrongPhase)
  }
  if seat < 0 || seat >= self.seats.length() {
    return Err(UnknownSeat)
  }
  let s = self.seats[seat]
  if !s.live {
    return Err(AlreadyFolded)
  }
  if seat != self.turn {
    return Err(OutOfTurn)
  }
  match a {
    Fold => {
      s.live = false
      self.log.push("p\{seat} folds")
      self.settle_pending(1)
      Ok(())
    }
    Check => {
      if s.bet < self.level {
        return Err(AmountTooLow(self.level))
      }
      self.log.push("p\{seat} checks")
      self.settle_pending(1)
      Ok(())
    }
    Call => {
      let owe = self.level - s.bet
      if owe > 0 {
        s.chips -= owe
        self.pot += owe
        s.bet = self.level
      }
      self.log.push("p\{seat} calls")
      self.settle_pending(1)
      Ok(())
    }
    Raise(to) => {
      if to < self.level + MIN_RAISE {
        return Err(AmountTooLow(self.level + MIN_RAISE))
      }
      let owe = to - s.bet
      s.chips -= owe
      self.pot += owe
      s.bet = to
      self.level = to
      self.log.push("p\{seat} raises to \{to}")
      // a raise reopens the action for everyone else
      self.pending = self.live_count() - 1
      self.advance_turn()
      if self.pending <= 0 || self.live_count() <= 1 {
        self.end_round()
      }
      Ok(())
    }
  }
}

///|
/// Consumes one pending action; a fold can end the hand outright.
fn DrawPoker::settle_pending(self : DrawPoker, n : Int32) -> Unit {
  self.pending -= n
  self.advance_turn()
  if self.live_count() <= 1 || self.pending <= 0 {
    self.end_round()
  }
}

///|
fn DrawPoker::end_round(self : DrawPoker) -> Unit {
  if self.live_count() <= 1 {
    self.settle_uncontested()
    return
  }
  match self.phase {
    DealBetting => {
      self.phase = Draw
      self.turn = self.next_live_from(0)
    }
    PostDrawBetting => self.showdown()
    _ => ()
  }
}

///|
fn DrawPoker::settle_uncontested(self : DrawPoker) -> Unit {
  for i in 0..<self.seats.length() {
    if self.seats[i].live {
      self.winner = i
    }
  }
  if self.winner >= 0 {
    let w = self.seats[self.winner]
    w.chips += self.pot
  }
  self.phase = Showdown
}

///|
/// Declares which cards to replace (indices into the seat's own hand,
/// at most three). Only valid in the draw phase, on turn.
pub fn DrawPoker::discard(
  self : DrawPoker,
  seat : Int32,
  idx : Array[Int32],
) -> Result[Unit, BetError] {
  if !(self.phase is Draw) {
    return Err(WrongPhase)
  }
  if seat < 0 || seat >= self.seats.length() {
    return Err(UnknownSeat)
  }
  let s = self.seats[seat]
  if !s.live {
    return Err(AlreadyFolded)
  }
  if seat != self.turn {
    return Err(OutOfTurn)
  }
  if idx.length() > 3 {
    return Err(BadDiscards)
  }
  let sorted = idx.copy()
  sort_descending(sorted)
  for i in sorted {
    if i < 0 || i > 4 {
      return Err(BadDiscards)
    }
  }
  // replace from the highest index first so earlier indices stay valid
  for i in sorted {
    let _ = s.hand.remove(i)
    match self.deck.deal(1).get(0) {
      Some(c) => s.hand.push(c)
      None => ()
    }
  }
  self.log.push("p\{seat} draws \{sorted.length()}")
  let next = self.next_live_from(seat + 1)
  if next <= seat && self.last_live(seat) {
    self.phase = PostDrawBetting
    self.level = 0
    for s2 in self.seats {
      s2.bet = 0
    }
    self.pending = self.live_count()
    self.turn = self.next_live_from(0)
  } else {
    self.turn = next
  }
  Ok(())
}

///|
/// Whether `seat` is the last live player in scan order.
fn DrawPoker::last_live(self : DrawPoker, seat : Int32) -> Bool {
  for i in (seat + 1)..<self.seats.length() {
    if self.seats[i].live {
      return false
    }
  }
  true
}

///|
fn sort_descending(items : Array[Int32]) -> Unit {
  for i in 1..<items.length() {
    let key = items[i]
    let mut j = i - 1
    while j >= 0 && items[j] < key {
      items[j + 1] = items[j]
      j -= 1
    }
    items[j + 1] = key
  }
}

///|
/// Runs the showdown: the best five-card hand among live players wins
/// the pot. Evaluates hands with the cards package.
pub fn DrawPoker::showdown(self : DrawPoker) -> Unit {
  let mut best_seat = -1
  let mut best : @cards.HandValue? = None
  for i in 0..<self.seats.length() {
    let s = self.seats[i]
    if s.live {
      match @cards.evaluate_best(s.hand) {
        Some(hv) =>
          match best {
            None => {
              best = Some(hv)
              best_seat = i
            }
            Some(b) =>
              if hv.beats(b) {
                best = Some(hv)
                best_seat = i
              }
          }
        None => ()
      }
    }
  }
  self.winner = best_seat
  if best_seat >= 0 {
    self.seats[best_seat].chips += self.pot
  }
  self.phase = Showdown
}
