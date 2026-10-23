///|
fn assert_true(cond : Bool, msg : String) -> Unit raise {
  if !cond {
    fail(msg)
  }
}

///|
test "fivedraw: deal shape and hidden hands" {
  let p = @fivedraw.DrawPoker::new(4, 42UL)
  assert_true(p.player_count() == 4, "four seats")
  assert_true(p.phase() is @fivedraw.DealBetting, "starts in deal betting")
  assert_true(p.pot() == 4, "four antes")
  for seat in 0..<4 {
    let h = p.hand_of(seat).unwrap()
    assert_true(h.length() == 5, "five cards per seat")
  }
  // determinism
  let p2 = @fivedraw.DrawPoker::new(4, 42UL)
  for seat in 0..<4 {
    let h1 = p.hand_of(seat).unwrap()
    let h2 = p2.hand_of(seat).unwrap()
    for i in 0..<5 {
      assert_true(h1[i] == h2[i], "same seed same deal")
    }
  }
  // players clamp to 2..=6
  let one = @fivedraw.DrawPoker::new(1, 1UL)
  assert_true(one.player_count() == 2, "clamped to two seats")
  let seven = @fivedraw.DrawPoker::new(9, 1UL)
  assert_true(seven.player_count() == 6, "clamped to six seats")
}

///|
test "fivedraw: betting round completes with checks and calls" {
  let p = @fivedraw.DrawPoker::new(3, 7UL)
  // ante level is 1; players may raise or call
  assert_true(p.bet_level() == @fivedraw.ANTE, "ante level")
  // seat 0 raises to 6 (ante 1 + min raise 5)
  assert_true(p.bet(0, @fivedraw.Raise(6)) is Ok(_), "p0 raises")
  assert_true(p.turn() == 1, "p1 next")
  // out-of-turn action rejected
  match p.bet(2, @fivedraw.Call) {
    Err(@fivedraw.OutOfTurn) => ()
    _ => fail("expected OutOfTurn")
  }
  // everyone calls: p1, p2 must act, then p0 already acted
  assert_true(p.bet(1, @fivedraw.Call) is Ok(_), "p1 calls")
  assert_true(p.bet(2, @fivedraw.Call) is Ok(_), "p2 calls")
  assert_true(p.phase() is @fivedraw.Draw, "round ends into the draw phase")
  assert_true(p.pot() == 3 + 3 * 5, "antes plus three raises of five")
}

///|
test "fivedraw: fold can end the hand uncontested" {
  let p = @fivedraw.DrawPoker::new(2, 5UL)
  assert_true(p.bet(0, @fivedraw.Raise(6)) is Ok(_), "p0 raises")
  assert_true(p.bet(1, @fivedraw.Fold) is Ok(_), "p1 folds")
  assert_true(p.is_over(), "one player left: hand over")
  assert_true(p.winner() == 0, "p0 wins uncontested")
  assert_true(p.chips_of(0) == 100 - @fivedraw.ANTE + p.pot() - 5, "pot collected")
}

///|
test "fivedraw: draw phase replaces cards then showdown" {
  let p = @fivedraw.DrawPoker::new(2, 11UL)
  // check both players through the deal betting round
  assert_true(p.bet(0, @fivedraw.Call) is Ok(_), "p0 calls")
  assert_true(p.bet(1, @fivedraw.Call) is Ok(_), "p1 calls")
  assert_true(p.phase() is @fivedraw.Draw, "draw phase")
  // p0 discards two cards, p1 stands pat
  assert_true(p.discard(0, [0, 4]) is Ok(_), "p0 draws two")
  assert_true(p.discard(1, []) is Ok(_), "p1 stands pat")
  assert_true(p.phase() is @fivedraw.PostDrawBetting, "post-draw betting")
  // bets reset to zero in the post-draw round
  assert_true(p.bet_level() == 0, "no outstanding bet")
  // check-check reaches showdown
  assert_true(p.bet(0, @fivedraw.Check) is Ok(_), "p0 checks")
  assert_true(p.bet(1, @fivedraw.Check) is Ok(_), "p1 checks")
  assert_true(p.is_over(), "showdown reached")
  assert_true(p.winner() >= 0, "a winner was decided")
  // the winner collected the pot (two antes, no raises)
  let w = p.winner()
  assert_true(p.chips_of(w) == 100 - @fivedraw.ANTE + 2, "winner holds stake plus pot")
}

///|
test "fivedraw: discard validation" {
  let p = @fivedraw.DrawPoker::new(2, 13UL)
  // draw-phase actions rejected during betting
  match p.discard(0, [0]) {
    Err(@fivedraw.WrongPhase) => ()
    _ => fail("expected WrongPhase")
  }
  assert_true(p.bet(0, @fivedraw.Call) is Ok(_), "call through")
  assert_true(p.bet(1, @fivedraw.Call) is Ok(_), "call through")
  // too many discards
  match p.discard(0, [0, 1, 2, 3]) {
    Err(@fivedraw.BadDiscards) => ()
    _ => fail("expected BadDiscards")
  }
  // out-of-range index
  match p.discard(0, [9]) {
    Err(@fivedraw.BadDiscards) => ()
    _ => fail("expected BadDiscards")
  }
  // out of turn
  match p.discard(1, [0]) {
    Err(@fivedraw.OutOfTurn) => ()
    _ => fail("expected OutOfTurn")
  }
  // valid discard drew replacement cards: hand size stays five
  assert_true(p.discard(0, [0, 1, 2]) is Ok(_), "p0 draws three")
  assert_true(p.hand_of(0).unwrap().length() == 5, "hand restored to five")
}

///|
test "fivedraw: full six-player hand reaches a showdown" {
  let p = @fivedraw.DrawPoker::new(6, 99UL)
  // everyone calls the ante
  for seat in 0..<6 {
    assert_true(p.bet(seat, @fivedraw.Call) is Ok(_), "p\{seat} calls")
  }
  assert_true(p.phase() is @fivedraw.Draw, "into the draw")
  // everyone discards nothing
  for seat in 0..<6 {
    assert_true(p.discard(seat, []) is Ok(_), "p\{seat} stands pat")
  }
  assert_true(p.phase() is @fivedraw.PostDrawBetting, "post-draw betting")
  // everyone checks
  for seat in 0..<6 {
    assert_true(p.bet(seat, @fivedraw.Check) is Ok(_), "p\{seat} checks")
  }
  assert_true(p.is_over(), "hand over")
  assert_true(p.winner() >= 0, "showdown produced a winner")
  assert_true(p.pot() == 6, "pot was paid out")
}

///|
test "fivedraw: game_info metadata" {
  let p = @fivedraw.DrawPoker::new(5, 1UL)
  let info = p.game_info()
  let (lo, hi) = info.players
  assert_true(lo == 2 && hi == 6, "draw poker seats 2..=6")
  assert_true(!info.perfect_information, "hands are hidden")
  assert_true(info.has_chance, "shuffled deck")
}
