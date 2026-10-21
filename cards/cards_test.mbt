///|
/// Black-box tests for the cards package: card parsing, deterministic
/// shuffling, dealing and poker hand evaluation.

///|
fn assert_eq_actual(a : String, b : String, msg : String) -> Unit raise {
  if a != b {
    fail("\{msg}: expected \{b}, got \{a}")
  }
}

///|
fn assert_true_msg(cond : Bool, msg : String) -> Unit raise {
  if !cond {
    fail(msg)
  }
}

///|
test "cards: parse single cards and card lists" {
  let c = @cards.Card::parse("As").unwrap()
  assert_eq_actual(c.text(), "As", "ace of spades")
  let c2 = @cards.Card::parse("td").unwrap()
  assert_eq_actual(c2.text(), "Td", "ten of diamonds")
  let c3 = @cards.Card::parse("2C").unwrap()
  assert_eq_actual(c3.text(), "2c", "lowercase input normalised")
  assert_true_msg(@cards.Card::parse("Ax") is None, "bad suit rejected")
  assert_true_msg(@cards.Card::parse("A") is None, "too short rejected")
  let many = @cards.Card::parse_many("As Kd 9c Th 2h").unwrap()
  assert_eq_actual(many.length().to_string(), "5", "five cards parsed")
  assert_true_msg(
    @cards.Card::parse_many("As Xx") is None,
    "bad list rejected",
  )
}

///|
test "cards: standard deck has 52 unique cards" {
  let d = @cards.Deck::standard52()
  assert_eq_actual(d.remaining().to_string(), "52", "fresh deck size")
  let dealt = d.deal(52)
  assert_eq_actual(dealt.length().to_string(), "52", "full deal")
  for i in 0..<52 {
    for j in (i + 1)..<52 {
      if dealt[i] == dealt[j] {
        fail("duplicate card \{dealt[i].text()}")
      }
    }
  }
  assert_eq_actual(d.remaining().to_string(), "0", "deck exhausted")
}

///|
test "cards: shuffle is deterministic by seed and complete" {
  let a = @cards.Deck::shuffled(42UL)
  let b = @cards.Deck::shuffled(42UL)
  let da = a.deal(52)
  let db = b.deal(52)
  for i in 0..<52 {
    if da[i] != db[i] {
      fail("same seed must reproduce the same order at \{i}")
    }
  }
  let c = @cards.Deck::shuffled(43UL)
  let dc = c.deal(52)
  let mut differences = 0
  for i in 0..<52 {
    if da[i] != dc[i] {
      differences += 1
    }
  }
  assert_true_msg(
    differences >= 40,
    "different seed should yield a very different order, got \{differences}",
  )
  for i in 0..<52 {
    for j in (i + 1)..<52 {
      if da[i] == da[j] {
        fail("shuffled deck lost uniqueness at \{i},\{j}")
      }
    }
  }
}

///|
test "cards: dealing respects order and shortage" {
  let d = @cards.Deck::shuffled(7UL)
  let first = d.deal(5)
  let second = d.deal(5)
  assert_true_msg(
    first.length() == 5 && second.length() == 5,
    "expected two full deals of five",
  )
  for a in first {
    for b in second {
      if a == b {
        fail("same card dealt twice: \{a.text()}")
      }
    }
  }
  let rest = d.deal(60)
  assert_eq_actual(rest.length().to_string(), "42", "shortage yields the remainder")
  d.reset()
  assert_eq_actual(d.remaining().to_string(), "52", "reset restores the deck")
}

///|
fn ev(text : String) -> @cards.HandValue raise {
  match @cards.Card::parse_many(text) {
    Some(cards) =>
      match @cards.evaluate_five(cards) {
        Some(hv) => hv
        None => fail("evaluation failed for \{text}")
      }
    None => fail("parse failed for \{text}")
  }
}

///|
test "cards: five-card hand categories" {
  assert_eq_actual(
    ev("As Ks Qs Js Ts").rank.name(),
    "straight flush",
    "royal flush",
  )
  assert_eq_actual(ev("As 2s 3s 4s 5s").rank.name(), "straight flush", "wheel SF")
  assert_eq_actual(ev("9c 9d 9h 9s 2c").rank.name(), "four of a kind", "quads")
  assert_eq_actual(ev("9c 9d 9h 2s 2c").rank.name(), "full house", "full house")
  assert_eq_actual(ev("Ah Jh 9h 5h 2h").rank.name(), "flush", "flush")
  assert_eq_actual(ev("Ac Kd Qh Js Td").rank.name(), "straight", "broadway")
  assert_eq_actual(ev("Ad 2c 3h 4s 5d").rank.name(), "straight", "wheel")
  assert_eq_actual(ev("7c 7d 7h Ks 2c").rank.name(), "three of a kind", "trips")
  assert_eq_actual(ev("7c 7d Kh Ks 2c").rank.name(), "two pair", "two pair")
  assert_eq_actual(ev("7c 7d Kh 9s 2c").rank.name(), "one pair", "pair")
  assert_eq_actual(ev("7c 3d Kh 9s 2c").rank.name(), "high card", "high card")
}

///|
test "cards: hand comparisons" {
  let quad_kings = ev("Kc Kd Kh Ks 2c")
  let quad_nines = ev("9c 9d 9h 9s Ac")
  assert_true_msg(quad_kings.beats(quad_nines), "KKKK > 9999")
  assert_true_msg(
    ev("9c 9d 9h 2s 2c").beats(ev("Ah Jh 9h 5h 2h")),
    "FH > flush",
  )
  assert_true_msg(
    ev("Ac Kd Qh Js Td").beats(ev("7c 7d 7h Ks 2c")),
    "straight > trips",
  )
  assert_true_msg(
    ev("2c 3d 4h 5s 6d").beats(ev("Ad 2c 3h 4s 5d")),
    "2-6 > A-5",
  )
  assert_true_msg(
    ev("Ah Jh 9h 5h 2h").beats(ev("Kh Qh 9h 5h 2h")),
    "A-high flush",
  )
  assert_eq_actual(
    ev("Ah Jh 9h 5h 2h").compare(ev("As Js 9s 5s 2s")).to_string(),
    "0",
    "flush tie",
  )
}

///|
test "cards: best-of-seven evaluation" {
  let seven = @cards.Card::parse_many("9c 9d 9h 9s Ac Kd Qh").unwrap()
  let hv = @cards.evaluate_best(seven).unwrap()
  assert_eq_actual(hv.rank.name(), "four of a kind", "quads from seven")
  let flush_seven = @cards.Card::parse_many("Ah Jh 9h 5h 2h Kd Kc").unwrap()
  let hv2 = @cards.evaluate_best(flush_seven).unwrap()
  assert_eq_actual(hv2.rank.name(), "flush", "flush selected from seven")
  let sf_seven = @cards.Card::parse_many("As 2s 3s 4s 5s Kd Kc").unwrap()
  let hv3 = @cards.evaluate_best(sf_seven).unwrap()
  assert_eq_actual(hv3.rank.name(), "straight flush", "wheel SF from seven")
  assert_true_msg(@cards.evaluate_best([]) is None, "empty rejected")
}
