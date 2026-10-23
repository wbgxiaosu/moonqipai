///|
fn assert_true(cond : Bool, msg : String) -> Unit raise {
  if !cond {
    fail(msg)
  }
}

///|
test "gomoku: horizontal five wins" {
  let g = @gomoku.Gomoku::standard()
  // black builds a horizontal five on row 7; white answers elsewhere
  for i in 0..<5 {
    assert_true(g.play(7, i) is Ok(_), "black \{i}")
    if i < 4 {
      assert_true(g.play(0, i + 1) is Ok(_), "white \{i}")
    }
  }
  // after black's fifth stone the game ends before white replies
  assert_true(g.winner() is Black, "black completed the line")
  assert_true(g.is_over(), "game over")
  assert_true(g.play(3, 3) is Err(_), "no moves after a win")
}

///|
test "gomoku: vertical and diagonal detection" {
  // vertical: B r0c0, W r9c9, B r1c0, W r9c8, B r2c0, W r9c7, B r3c0,
  // W r9c6, B r4c0 wins on the 5th
  let g = @gomoku.Gomoku::standard()
  let seq : Array[(Int, Int, Int, Int)] = [
    (0, 0, 9, 9),
    (1, 0, 9, 8),
    (2, 0, 9, 7),
    (3, 0, 9, 6),
  ]
  for m in seq {
    let (br, bc, wr, wc) = m
    assert_true(g.play(br, bc) is Ok(_), "black move")
    assert_true(g.play(wr, wc) is Ok(_), "white move")
  }
  assert_true(g.play(4, 0) is Ok(_), "black completes vertical five")
  assert_true(g.winner() is Black, "vertical line wins")
  // diagonal on a fresh board
  let d = @gomoku.Gomoku::standard()
  for i in 0..<4 {
    assert_true(d.play(i, i) is Ok(_), "black diagonal")
    assert_true(d.play(14, 14 - i) is Ok(_), "white counter")
  }
  assert_true(d.play(4, 4) is Ok(_), "black completes the diagonal")
  assert_true(d.winner() is Black, "diagonal line wins")
}

///|
test "gomoku: alternation, occupancy and bounds" {
  let g = @gomoku.Gomoku::new(9)
  assert_true(g.turn() is Black, "black first")
  assert_true(g.play(4, 4) is Ok(_), "centre")
  assert_true(g.turn() is White, "white second")
  match g.play(4, 4) {
    Err(@gomoku.Occupied) => ()
    _ => fail("expected Occupied")
  }
  match g.play(9, 0) {
    Err(@gomoku.OutOfBounds) => ()
    _ => fail("expected OutOfBounds")
  }
  match g.play(0, 9) {
    Err(@gomoku.OutOfBounds) => ()
    _ => fail("expected OutOfBounds")
  }
  assert_true(g.legal_moves().length() == 80, "80 empty points on 9x9")
}

///|
test "gomoku: draw on a full board" {
  // 5x5 board can hold 25 stones without any five-in-a-row? No: on 5x5
  // any placement pattern eventually lines up; use a 5x5 with an
  // interleaved pattern that avoids five — impossible on 5x5 with
  // alternating colours, so test the draw path on a synthetic 3x3:
  // 9 stones, max line length 3, board fills with no winner.
  let g = @gomoku.Gomoku::new(3)
  for m in [(0, 0), (0, 1), (1, 0), (0, 2), (2, 0), (1, 1), (1, 2), (2, 2), (2, 1)] {
    let (r, c) = m
    assert_true(g.play(r, c) is Ok(_), "move \{r},\{c}")
  }
  assert_true(g.is_over(), "board full ends the game")
  assert_true(g.winner() is Empty, "no line means a draw")
}

///|
test "gomoku: undo restores turn and winner" {
  let g = @gomoku.Gomoku::standard()
  for i in 0..<4 {
    assert_true(g.play(7, i) is Ok(_), "black \{i}")
    assert_true(g.play(0, i + 1) is Ok(_), "white \{i}")
  }
  assert_true(g.play(7, 4) is Ok(_), "winning move")
  assert_true(g.winner() is Black, "black won")
  assert_true(g.undo(), "undo the winning move")
  assert_true(g.winner() is Empty, "winner cleared")
  assert_true(g.turn() is Black, "black to move again")
  assert_true(g.stone_count() == 8, "eight stones remain")
  assert_true(g.play(7, 4) is Ok(_), "the winning move replays")
  assert_true(g.winner() is Black, "black wins again")
  // undo all the way to the start
  while g.undo() {
    ()
  }
  assert_true(g.stone_count() == 0, "empty board")
  assert_true(g.turn() is Black, "black first again")
}

///|
test "gomoku: render includes header and stones" {
  let g = @gomoku.Gomoku::new(5)
  let _ = g.play(0, 0)
  let r = g.render()
  assert_true(r.contains("X"), "black stone rendered")
  assert_true(r.contains("a"), "column header rendered")
}
