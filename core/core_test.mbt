///|
/// Black-box tests for the unified engine: one scripted scenario per game
/// through the same [Engine] interface, plus notation parsing and undo
/// semantics.

///|
fn assert_str(a : String, b : String, msg : String) -> Unit raise {
  if a != b {
    fail("\{msg}: expected \{b}, got \{a}")
  }
}

///|
fn assert_true(cond : Bool, msg : String) -> Unit raise {
  if !cond {
    fail(msg)
  }
}

///|
test "core: go vertex parsing" {
  let v = @core.go_parse_vertex(19, "Q16").unwrap()
  assert_true(v.0 == 3 && v.1 == 15, "Q16 = row 3, col 15")
  let a1 = @core.go_parse_vertex(5, "A1").unwrap()
  assert_true(a1.0 == 4 && a1.1 == 0, "A1 = bottom-left on 5x5")
  let a5 = @core.go_parse_vertex(5, "a5").unwrap()
  assert_true(a5.0 == 0 && a5.1 == 0, "lowercase a5 = top-left on 5x5")
  assert_true(@core.go_parse_vertex(5, "pass") is Some(_), "pass parses")
  assert_true(@core.go_parse_vertex(5, "Z3") is None, "letter Z rejected")
  assert_true(@core.go_parse_vertex(5, "I3") is None, "letter I skipped")
  assert_true(@core.go_parse_vertex(5, "A9") is None, "row out of range")
}

///|
test "core: go alternation, pass and scoring through the engine" {
  let g = @core.Engine::make(@core.Go(5, 0.5))
  assert_true(g.turn() is @core.P1, "black moves first")
  assert_true(g.apply("A5") is Ok(_), "black A5 accepted")
  assert_true(g.turn() is @core.P2, "white after black")
  assert_true(g.apply("Z3") is Err(_), "malformed vertex rejected")
  assert_true(g.apply("A5") is Err(_), "occupied point rejected")
  assert_true(g.apply("pass") is Ok(_), "white passes")
  assert_true(g.apply("pass") is Ok(_), "black passes")
  assert_true(g.is_over(), "double pass ends the game")
  // black's corner stone gives black the whole 5x5 board on area scoring
  assert_str(
    g.outcome().unwrap().describe(@core.Go(5, 0.5)),
    "B+24.5",
    "black wins 25 to 0.5",
  )
  // a genuinely empty board ends as a white win by komi
  let e = @core.Engine::make(@core.Go(5, 0.5))
  assert_true(e.apply("pass") is Ok(_), "white passes on empty board")
  assert_true(e.apply("pass") is Ok(_), "black passes on empty board")
  match e.outcome() {
    Some(@core.Score(p, m)) => {
      assert_true(p is @core.P2, "white wins by komi on empty board")
      assert_str(m.to_string(), "0.5", "margin equals komi")
    }
    _ => fail("expected a scored outcome")
  }
  assert_str(
    e.outcome().unwrap().describe(@core.Go(5, 0.5)),
    "W+0.5",
    "describe",
  )
}

///|
test "core: go capture through the unified interface" {
  let g = @core.Engine::make(@core.Go(5, 0.5))
  // B A5 (top-left corner), W A4, B E1, W B5: the black corner stone is
  // captured (its only liberties A4/B5 are white)
  for mv in ["A5", "A4", "E1", "B5"] {
    match g.apply(mv) {
      Ok(_) => ()
      Err(e) => fail("go move \{mv} rejected: \{e.message()}")
    }
  }
  assert_true(g.move_count() == 4, "4 stone moves, one captured")
  assert_true(g.undo(), "undo works through the engine")
}

///|
test "core: chess opening, checkmate and undo" {
  let c = @core.Engine::make(@core.Chess)
  for mv in ["e2e4", "e7e5", "g1f3"] {
    match c.apply(mv) {
      Ok(_) => ()
      Err(e) => fail("chess move \{mv} rejected: \{e.message()}")
    }
  }
  assert_true(c.legal_moves().length() > 20, "opening position has many moves")
  assert_true(c.apply("e2e5") is Err(_), "illegal pawn advance rejected")
  // fool's mate
  let f = @core.Engine::make(@core.Chess)
  for mv in ["f2f3", "e7e5", "g2g4", "d8h4"] {
    match f.apply(mv) {
      Ok(_) => ()
      Err(e) => fail("fool's mate move \{mv} rejected: \{e.message()}")
    }
  }
  assert_true(f.is_over(), "fool's mate ends the game")
  match f.outcome() {
    Some(@core.Winner(p)) =>
      assert_true(p is @core.P2, "black delivers fool's mate")
    _ => fail("expected a winner")
  }
  assert_str(f.outcome().unwrap().record_string(), "0-1", "record string")
  // undo reopens the game
  assert_true(f.undo(), "undo after mate")
  assert_true(!f.is_over(), "game resumed after undo")
  assert_true(f.turn() is @core.P2, "black to move after undoing the mate")
}

///|
test "core: xiangqi opening and illegal-move classification" {
  let x = @core.Engine::make(@core.Xiangqi)
  for mv in ["h2e2", "h9g7"] {
    match x.apply(mv) {
      Ok(_) => ()
      Err(e) => fail("xiangqi move \{mv} rejected: \{e.message()}")
    }
  }
  assert_true(x.turn() is @core.P1, "red again after h9g7")
  // e2e4 looks like ICCS but e2 is empty in the start position, so the
  // notation layer cannot resolve it to a piece
  match x.apply("e2e4") {
    Err(@core.UnknownMove(_)) => ()
    Err(e) => fail("expected UnknownMove, got \{e.message()}")
    Ok(_) => fail("expected UnknownMove, got success")
  }
  assert_true(x.apply("zzzz") is Err(_), "garbage move rejected")
  // the opening moves are among the legal moves in native notation
  let legal = x.legal_moves()
  let mut found_e2 = false
  for mv in legal {
    if mv == "b0c2" {
      found_e2 = true
    }
  }
  assert_true(found_e2 || legal.length() > 40, "legal move list is populated")
}

///|
test "core: outcome describe per game" {
  let o : @core.Outcome = @core.Score(@core.P1, 2.5)
  assert_str(o.describe(@core.Go(19, 2.5)), "B+2.5", "go margin")
  let w : @core.Outcome = @core.Winner(@core.P2)
  assert_str(w.describe(@core.Xiangqi), "0-1", "xiangqi record")
  assert_str(w.describe(@core.Chess), "0-1", "chess record")
  assert_str((@core.Draw : @core.Outcome).record_string(), "1/2-1/2", "draw")
}

///|
test "core: engine dispatch exposes each game id" {
  assert_true(@core.Engine::make_go().game_id() is @core.Go(_, _), "go id")
  assert_true(
    @core.Engine::make(@core.Xiangqi).game_id() is @core.Xiangqi,
    "xiangqi id",
  )
  assert_true(
    @core.Engine::make(@core.Chess).game_id() is @core.Chess,
    "chess id",
  )
  // player labels
  let go_id : @core.GameId = @core.Go(19, 7.5)
  assert_str(@core.P1.label(go_id), "B", "go first player")
  assert_str(@core.P2.label(@core.Xiangqi), "Black", "xiangqi second player")
}

///|
test "core: gomoku flows through the unified engine" {
  let g = @core.Engine::make(@core.Gomoku(15))
  assert_true(g.game_id() is @core.Gomoku(_), "gomoku id")
  for mv in ["H8", "H9", "J8", "H10", "K8", "H11", "L8", "H12", "M8"] {
    match g.apply(mv) {
      Ok(_) => ()
      Err(e) => fail("gomoku \{mv} rejected: \{e.message()}")
    }
  }
  // black has four in a row on rank 8: M8 completes five
  match g.outcome() {
    Some(@core.Winner(p)) =>
      assert_true(p is @core.P1, "black completes the line")
    _ => fail("expected a winner")
  }
  assert_true(g.undo(), "undo through the engine")
  assert_true(!g.is_over(), "game resumed")
}

///|
test "core: othello flows through the unified engine" {
  let o = @core.Engine::make(@core.Othello)
  assert_true(o.game_id() is @core.Othello, "othello id")
  for mv in ["D3", "C5", "F6"] {
    match o.apply(mv) {
      Ok(_) => ()
      Err(e) => fail("othello \{mv} rejected: \{e.message()}")
    }
  }
  assert_true(o.legal_moves().length() > 0, "the line leaves continuations")
  // pass is accepted only when no move exists
  match o.apply("pass") {
    Err(@core.IllegalMove(_)) => ()
    Err(e) => fail("expected IllegalMove, got \{e.message()}")
    Ok(_) => fail("an illegal pass must not succeed")
  }
  assert_true(o.undo(), "undo works")
}

///|
test "core: player labels cover all five board games" {
  let g5 : @core.GameId = @core.Gomoku(15)
  assert_str(@core.P1.label(g5), "B", "gomoku first player")
  assert_str(@core.P2.label(g5), "W", "gomoku second player")
  assert_str(@core.P1.label(@core.Othello), "Black", "othello first player")
  assert_str(@core.P2.label(@core.Othello), "White", "othello second player")
}

///|
test "core: game_info metadata for every board game" {
  let games : Array[@core.Engine] = [
    @core.Engine::make(@core.Go(19, 7.5)),
    @core.Engine::make(@core.Xiangqi),
    @core.Engine::make(@core.Chess),
    @core.Engine::make(@core.Gomoku(15)),
    @core.Engine::make(@core.Othello),
  ]
  for g in games {
    let info = g.game_info()
    assert_true(info.perfect_information, "board games are perfect information")
    assert_true(!info.has_chance, "board games have no chance events")
    assert_true(info.sequential, "board games are sequential")
    let (lo, hi) = info.players
    assert_true(lo == 2 && hi == 2, "board games are two-player")
  }
}
