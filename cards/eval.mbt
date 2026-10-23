///|
/// Poker hand categories, in ascending strength.
pub(all) enum HandRank {
  HighCard
  Pair
  TwoPair
  ThreeOfAKind
  Straight
  Flush
  FullHouse
  FourOfAKind
  StraightFlush
} derive(Eq, Debug)

///|
pub extend HandRank with Eq::{equal, not_equal}

///|
pub extend HandRank with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Numeric strength of the category; larger beats smaller.
pub fn HandRank::strength(self : HandRank) -> Int32 {
  match self {
    HighCard => 0
    Pair => 1
    TwoPair => 2
    ThreeOfAKind => 3
    Straight => 4
    Flush => 5
    FullHouse => 6
    FourOfAKind => 7
    StraightFlush => 8
  }
}

///|
/// Human-readable name of the category.
pub fn HandRank::name(self : HandRank) -> String {
  match self {
    HighCard => "high card"
    Pair => "one pair"
    TwoPair => "two pair"
    ThreeOfAKind => "three of a kind"
    Straight => "straight"
    Flush => "flush"
    FullHouse => "full house"
    FourOfAKind => "four of a kind"
    StraightFlush => "straight flush"
  }
}

///|
/// The value of a five-card poker hand: the category plus the ordered
/// tiebreak ranks used to compare hands within the same category. The
/// first tiebreak entry is the most significant rank (e.g. the rank of
/// the quads in four of a kind).
pub(all) struct HandValue {
  rank : HandRank
  tiebreak : Array[Int32]
} derive(Eq, Debug)

///|
pub extend HandValue with Eq::{equal, not_equal}

///|
pub extend HandValue with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Returns `Some((-1 | 0 | 1))` as `self` loses/ties/wins against `other`.
pub fn HandValue::compare(self : HandValue, other : HandValue) -> Int32 {
  let a = self.rank.strength()
  let b = other.rank.strength()
  if a != b {
    return if a > b { 1 } else { -1 }
  }
  let n = if self.tiebreak.length() < other.tiebreak.length() {
    self.tiebreak.length()
  } else {
    other.tiebreak.length()
  }
  for i in 0..<n {
    if self.tiebreak[i] != other.tiebreak[i] {
      return if self.tiebreak[i] > other.tiebreak[i] { 1 } else { -1 }
    }
  }
  0
}

///|
/// Whether `self` beats `other`.
pub fn HandValue::beats(self : HandValue, other : HandValue) -> Bool {
  self.compare(other) > 0
}

///|
/// Evaluates exactly five cards into a [HandValue].
pub fn evaluate_five(cards : Array[Card]) -> HandValue? {
  if cards.length() != 5 {
    return None
  }
  let values : Array[Int32] = []
  let mut flush = true
  let first_suit = cards[0].suit
  for c in cards {
    values.push(c.rank.value())
    if c.suit != first_suit {
      flush = false
    }
  }
  // counts per rank value 2..=14
  let counts : Array[Int32] = []
  for _ in 0..<=14 {
    counts.push(0)
  }
  for v in values {
    counts[v] += 1
  }
  // straight detection (aces may play low in A-2-3-4-5)
  let sorted = sorted_desc(values)
  let mut straight_high = 0
  if is_run(sorted) {
    straight_high = sorted[0]
  } else if has_wheel(values) {
    straight_high = 5
  }
  // group ranks by multiplicity, scanning unique rank values from high to
  // low so pairs and kickers come out sorted descending
  let mut quad = 0
  let mut trip = 0
  let pairs : Array[Int32] = []
  let kickers : Array[Int32] = []
  for k in 0..<13 {
    let v = 14 - k
    match counts[v] {
      4 => quad = v
      3 => trip = v
      2 => pairs.push(v)
      1 => kickers.push(v)
      _ => ()
    }
  }
  if straight_high > 0 && flush {
    return Some({ rank: StraightFlush, tiebreak: [straight_high], })
  }
  if quad > 0 {
    return Some({ rank: FourOfAKind, tiebreak: [quad, kickers[0]], })
  }
  if trip > 0 && pairs.length() > 0 {
    return Some({ rank: FullHouse, tiebreak: [trip, pairs[0]], })
  }
  if flush {
    return Some({ rank: Flush, tiebreak: sorted, })
  }
  if straight_high > 0 {
    return Some({ rank: Straight, tiebreak: [straight_high], })
  }
  if trip > 0 {
    let tb = [trip]
    for k in kickers {
      tb.push(k)
    }
    return Some({ rank: ThreeOfAKind, tiebreak: tb, })
  }
  if pairs.length() >= 2 {
    let hi = if pairs[0] > pairs[1] { pairs[0] } else { pairs[1] }
    let lo = if pairs[0] > pairs[1] { pairs[1] } else { pairs[0] }
    return Some({ rank: TwoPair, tiebreak: [hi, lo, kickers[0]], })
  }
  if pairs.length() == 1 {
    let tb = [pairs[0]]
    for k in kickers {
      tb.push(k)
    }
    return Some({ rank: Pair, tiebreak: tb, })
  }
  Some({ rank: HighCard, tiebreak: sorted, })
}

///|
/// Evaluates the best five-card hand out of five to seven cards by
/// exhaustively checking all five-card subsets.
pub fn evaluate_best(cards : Array[Card]) -> HandValue? {
  let n = cards.length()
  if n < 5 || n > 7 {
    return None
  }
  if n == 5 {
    return evaluate_five(cards)
  }
  let mut best : HandValue? = None
  for combo in combinations(n, 5) {
    let hand : Array[Card] = []
    for i in combo {
      hand.push(cards[i])
    }
    match evaluate_five(hand) {
      Some(hv) =>
        match best {
          None => best = Some(hv)
          Some(b) => if hv.beats(b) { best = Some(hv) }
        }
      None => ()
    }
  }
  best
}

///|
/// Whether five strictly descending values form a consecutive run.
fn is_run(sorted_desc : Array[Int32]) -> Bool {
  for i in 0..<4 {
    if sorted_desc[i] != sorted_desc[i + 1] + 1 {
      return false
    }
  }
  true
}

///|
/// Whether the values contain A-2-3-4-5 (the wheel).
fn has_wheel(values : Array[Int32]) -> Bool {
  let seen : Array[Bool] = []
  for _ in 0..<=14 {
    seen.push(false)
  }
  for v in values {
    seen[v] = true
  }
  seen[14] && seen[2] && seen[3] && seen[4] && seen[5]
}

///|
fn sorted_desc(values : Array[Int32]) -> Array[Int32] {
  let acc = values.copy()
  // insertion sort: n <= 7
  for i in 1..<acc.length() {
    let key = acc[i]
    let mut j = i - 1
    while j >= 0 && acc[j] < key {
      acc[j + 1] = acc[j]
      j -= 1
    }
    acc[j + 1] = key
  }
  acc
}

///|
/// All k-element index combinations of 0..n-1, in lexicographic order.
fn combinations(n : Int32, k : Int32) -> Array[Array[Int32]] {
  let acc : Array[Array[Int32]] = []
  let cur : Array[Int32] = []
  fn rec(start : Int32) -> Unit {
    if cur.length() == k {
      acc.push(cur.copy())
      return
    }
    if start >= n {
      return
    }
    for i in start..<n {
      cur.push(i)
      rec(i + 1)
      let _ = cur.pop()
    }
  }

  rec(0)
  acc
}
