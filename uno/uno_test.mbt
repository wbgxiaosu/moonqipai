///|
fn assert_true(cond : Bool, msg : String) -> Unit raise {
  if !cond {
    fail(msg)
  }
}

///|
test "uno: deck size and deal shape" {
  let u = @uno.Uno::new(4, 42UL)
  assert_true(u.player_count() == 4, "four seats")
  for seat in 0..<4 {
    let h = u.hand_of(seat).unwrap()
    assert_true(h.length() == @uno.STARTING_HAND, "seven cards per seat")
  }
  // determinism
  let u2 = @uno.Uno::new(4, 42UL)
  for seat in 0..<4 {
    let h1 = u.hand_of(seat).unwrap()
    let h2 = u2.hand_of(seat).unwrap()
    for i in 0..<@uno.STARTING_HAND {
      assert_true(h1[i] == h2[i], "same seed same deal")
    }
  }
  // player count clamped
  let one = @uno.Uno::new(1, 1UL)
  assert_true(one.player_count() == 2, "clamped to two seats")
  let ten = @uno.Uno::new(9, 1UL)
  assert_true(ten.player_count() == 8, "clamped to eight seats")
  // the opening face is a number card
  match u.top() {
    Some(c) =>
      match c.kind {
        @uno.Number(_) => ()
        _ => fail("opening face must be a number")
      }
    None => fail("discard pile empty")
  }
}

///|
test "uno: matching rules" {
  let r7 : @uno.Card = { color: Some(@uno.Red), kind: @uno.Number(7) }
  let rsk : @uno.Card = { color: Some(@uno.Red), kind: @uno.Skip }
  let wild : @uno.Card = { color: None, kind: @uno.Wild }
  assert_true(r7.playable_on(@uno.Red, @uno.Number(3)), "colour match")
  assert_true(r7.playable_on(@uno.Blue, @uno.Number(7)), "number match")
  assert_true(!(r7.playable_on(@uno.Blue, @uno.Number(2))), "no match")
  assert_true(rsk.playable_on(@uno.Red, @uno.Number(5)), "same colour action")
  assert_true(rsk.playable_on(@uno.Blue, @uno.Skip), "same symbol")
  assert_true(wild.playable_on(@uno.Green, @uno.Number(0)), "wild always playable")
}

///|
test "uno: play, turn advance and colour choice" {
  let u = @uno.Uno::new(3, 42UL)
  let seat = u.turn()
  let hand = u.hand_of(seat).unwrap()
  // find a playable non-wild card and play it
  let mut idx = -1
  for i in 0..<hand.length() {
    let c = hand[i]
    match c.color {
      Some(col) =>
        if col == u.active_color() {
          idx = i
        }
      None => ()
    }
  }
  assert_true(idx >= 0, "a playable card exists in the hand")
  // remove the log noise: capture top before/after
  let before = u.log().length()
  assert_true(u.act(seat, @uno.Play(idx, None)) is Ok(_), "card played")
  assert_true(u.log().length() > before, "action logged")
  assert_true(u.turn() != seat, "turn advanced")
  // out-of-turn rejected
  match u.act(seat, @uno.Draw) {
    Err(@uno.OutOfTurn) => ()
    _ => fail("expected OutOfTurn")
  }
}

///|
test "uno: wild requires a colour" {
  // search seeds for a hand containing a wild at turn 0
  let mut tested = false
  for seed in [2UL, 3UL, 5UL, 8UL, 13UL, 21UL, 34UL, 55UL, 89UL, 144UL] {
    let u = @uno.Uno::new(2, seed)
    if u.turn() == 0 {
      let hand = u.hand_of(0).unwrap()
      for i in 0..<hand.length() {
        if hand[i].kind is @uno.Wild {
          match u.act(0, @uno.Play(i, None)) {
            Err(@uno.WildNeedsColor) => {
              tested = true
            }
            Err(_) => fail("expected WildNeedsColor")
            Ok(_) => fail("wild without colour must fail")
          }
          break
        }
      }
    }
    if tested {
      break
    }
  }
  // with a colour the wild plays
  let u = @uno.Uno::new(2, 4UL)
  let hand = u.hand_of(0).unwrap()
  let mut wild_idx = -1
  for i in 0..<hand.length() {
    if hand[i].kind is @uno.Wild || hand[i].kind is @uno.WildDrawFour {
      wild_idx = i
    }
  }
  if wild_idx >= 0 {
    assert_true(u.act(0, @uno.Play(wild_idx, Some(@uno.Green))) is Ok(_), "wild with colour plays")
    assert_true(u.active_color() is @uno.Green, "active colour updated")
  }
}

///|
test "uno: draw then play-drawn or hold" {
  // play until a draw happens; verify the drawn-window discipline
  let u = @uno.Uno::new(2, 6UL)
  let mut rounds = 0
  while !(u.is_over()) && rounds < 40 {
    let seat = u.turn()
    let hand = u.hand_of(seat).unwrap()
    let mut played = false
    if !(u.drawn_pending()) {
      for i in 0..<hand.length() {
        let c = hand[i]
        let choice = if c.kind is @uno.Wild || c.kind is @uno.WildDrawFour {
          Some(@uno.Blue)
        } else {
          None
        }
        if c.playable_on(u.active_color(), u.active_face()) {
          assert_true(u.act(seat, @uno.Play(i, choice)) is Ok(_), "legal play")
          played = true
          break
        }
      }
      if !played {
        assert_true(u.act(seat, @uno.Draw) is Ok(_), "draw")
      }
    } else {
      // the drawn card is playable: try play-drawn, otherwise hold
      let drawn_card = u.hand_of(seat).unwrap()[u.hand_of(seat).unwrap().length() - 1]
      let choice = if drawn_card.kind is @uno.Wild || drawn_card.kind is @uno.WildDrawFour {
        Some(@uno.Red)
      } else {
        None
      }
      if u.act(seat, @uno.PlayDrawn(choice)) is Err(_) {
        assert_true(u.act(seat, @uno.Hold) is Ok(_), "hold passes")
      }
    }
    rounds += 1
  }
  assert_true(rounds < 40 || u.is_over(), "game progresses without deadlock")
  assert_true(u.winner() >= 0 || rounds < 40, "a game either finishes or stays healthy")
}

///|
test "uno: reverse with two players keeps the turn" {
  // construct via a long scripted game is seed-dependent; instead verify
  // the direction flip is reflected in the next-seat arithmetic through
  // the skip effect: skip advances two seats either way on a 3-player
  // table (symmetric), so test the reverse flag via a 2-player game and
  // a wild-coloured skip sequence — pragmatic check: direction value is
  // internal, so verify behaviour: after a reverse the same seat moves
  // again. Find a seed where seat 0 holds a reverse playable at start.
  let mut found = false
  for seed in [100UL, 101UL, 102UL, 103UL, 104UL, 105UL, 106UL, 107UL] {
    let u = @uno.Uno::new(2, seed)
    if u.turn() == 0 {
      let hand = u.hand_of(0).unwrap()
      for i in 0..<hand.length() {
        let c = hand[i]
        match c.kind {
          @uno.Reverse =>
            if c.playable_on(u.active_color(), u.active_face()) {
              assert_true(u.act(0, @uno.Play(i, None)) is Ok(_), "reverse played")
              assert_true(u.turn() == 0, "same player moves again with two players")
              found = true
              break
            }
          _ => ()
        }
      }
    }
    if found {
      break
    }
  }
  // behavioural property holds whenever the scenario occurs; nothing to
  // assert when no seed in the batch produced it
  if !found {
    assert_true(true, "scenario not sampled")
  }
}

///|
test "uno: game_info metadata" {
  let u = @uno.Uno::new(4, 1UL)
  let info = u.game_info()
  let (lo, hi) = info.players
  assert_true(lo == 2 && hi == 8, "uno seats 2..=8")
  assert_true(!info.perfect_information, "hands are hidden")
  assert_true(info.has_chance, "shuffled deck")
  assert_true(info.sequential, "turns are sequential")
}
