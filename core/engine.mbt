///|
/// The per-game running state. Go's engine is mutable in place; the xiangqi
/// and chess boards are immutable values, so each variant also carries the
/// snapshot stack used by [undo].
priv enum Inner {
  Go(@moonbaduk.Game)
  Xiangqi(@xiangqi.Board, Array[@xiangqi.Board])
  Chess(@moonchess.Position, Array[@moonchess.Position])
  Gomoku(@gomoku.Gomoku)
  Othello(@othello.Othello)
}

///|
/// A running game behind the unified interface. Each variant delegates to
/// the corresponding rules library: Go to `wbgxiaosu/moonbaduk`, Xiangqi to
/// `wbgxiaosu/xiangqi`, chess to `L76148/moonchess`, while Gomoku and
/// Othello are this project's own engines. All moves are given and
/// returned in the game's native text notation:
///
/// - Go: GTP vertices such as `Q16`, or `pass` (letter `i` is skipped)
/// - Xiangqi: ICCS coordinates such as `h2e2`
/// - Chess: UCI coordinates such as `e2e4`, promotions as `e7e8q`
/// - Gomoku: Go-style vertices such as `H8` (letter `i` is skipped)
/// - Othello: vertices such as `D3`, or `pass` when no move exists
pub struct Engine {
  priv mut inner : Inner
}

///|
/// Starts a new game in its standard initial position.
pub fn Engine::make(id : GameId) -> Engine {
  let inner = match id {
    Go(size, komi) => Inner::Go(@moonbaduk.Game::new(size, komi))
    Xiangqi => Inner::Xiangqi(@xiangqi.Board::initial(), [])
    Chess => Inner::Chess(@moonchess.Position::startpos(), [])
    Gomoku(size) => Inner::Gomoku(@gomoku.Gomoku::new(size))
    Othello => Inner::Othello(@othello.Othello::new())
  }
  { inner, }
}

///|
/// Starts a Go game with the default board size and komi.
pub fn Engine::make_go() -> Engine {
  let inner = Inner::Go(@moonbaduk.Game::new(DEFAULT_BOARD_SIZE, DEFAULT_KOMI))
  { inner, }
}

///|
/// Applies a text move in the game's native notation. Alternation is
/// enforced: the move is made by the side whose turn it is.
pub fn Engine::apply(self : Engine, mv : String) -> Result[Unit, EngineError] {
  if self.is_over() {
    return Err(GameOver)
  }
  match self.inner {
    Inner::Go(g) => go_apply(g, mv)
    Inner::Xiangqi(b, hist) => {
      let applied = xiangqi_apply(b, mv)
      match applied {
        Ok(nb) => {
          hist.push(b)
          self.inner = Inner::Xiangqi(nb, hist)
          Ok(())
        }
        Err(e) => Err(e)
      }
    }
    Inner::Chess(p, hist) => {
      let applied = chess_apply(p, mv)
      match applied {
        Ok(np) => {
          hist.push(p)
          self.inner = Inner::Chess(np, hist)
          Ok(())
        }
        Err(e) => Err(e)
      }
    }
    Inner::Gomoku(g) => gomoku_apply(g, mv)
    Inner::Othello(o) => othello_apply(o, mv)
  }
}

///|
/// All legal moves in the current position, in the game's native notation.
pub fn Engine::legal_moves(self : Engine) -> Array[String] {
  match self.inner {
    Inner::Go(g) => go_legal_moves(g)
    Inner::Xiangqi(b, _) => xiangqi_legal_moves(b)
    Inner::Chess(p, _) => chess_legal_moves(p)
    Inner::Gomoku(g) => gomoku_legal_moves(g)
    Inner::Othello(o) => othello_legal_moves(o)
  }
}

///|
/// Takes back the last move. Returns `false` when there is nothing to undo
/// (e.g. at the starting position).
pub fn Engine::undo(self : Engine) -> Bool {
  match self.inner {
    Inner::Go(g) => g.undo()
    Inner::Xiangqi(_, hist) =>
      if hist.length() > 0 {
        let prev = hist.pop().unwrap()
        self.inner = Inner::Xiangqi(prev, hist)
        true
      } else {
        false
      }
    Inner::Chess(_, hist) =>
      if hist.length() > 0 {
        let prev = hist.pop().unwrap()
        self.inner = Inner::Chess(prev, hist)
        true
      } else {
        false
      }
    Inner::Gomoku(g) => g.undo()
    Inner::Othello(o) => o.undo()
  }
}

///|
/// The side to move, normalised as `P1` (first mover) or `P2`.
pub fn Engine::turn(self : Engine) -> Player {
  match self.inner {
    Inner::Go(g) =>
      match g.turn() {
        @moonbaduk.Black => P1
        @moonbaduk.White => P2
        @moonbaduk.Empty => P1 // unreachable in a running game
      }
    Inner::Xiangqi(b, _) => if b.side() is @xiangqi.Red { P1 } else { P2 }
    Inner::Chess(p, _) => if p.turn() is @moonchess.White { P1 } else { P2 }
    Inner::Gomoku(g) => if g.turn() is @gomoku.Black { P1 } else { P2 }
    Inner::Othello(o) => if o.turn() is @othello.Black { P1 } else { P2 }
  }
}

///|
/// Whether the game has reached a terminal state.
pub fn Engine::is_over(self : Engine) -> Bool {
  self.outcome() is Some(_)
}

///|
/// The terminal result, or `None` while the game is still running.
pub fn Engine::outcome(self : Engine) -> Outcome? {
  match self.inner {
    Inner::Go(g) => go_outcome(g)
    Inner::Xiangqi(b, _) => xiangqi_outcome(b)
    Inner::Chess(p, _) => chess_outcome(p)
    Inner::Gomoku(g) => gomoku_outcome(g)
    Inner::Othello(o) => othello_outcome(o)
  }
}

///|
/// The game id behind this engine.
pub fn Engine::game_id(self : Engine) -> GameId {
  match self.inner {
    Inner::Go(g) => Go(g.size(), g.komi())
    Inner::Xiangqi(_, _) => Xiangqi
    Inner::Chess(_, _) => Chess
    Inner::Gomoku(g) => Gomoku(g.size())
    Inner::Othello(_) => Othello
  }
}

///|
/// An ASCII rendering of the current position, useful for logs and REPLs.
pub fn Engine::render(self : Engine) -> String {
  match self.inner {
    Inner::Go(g) => g.board().render()
    Inner::Xiangqi(b, _) => b.render_board()
    Inner::Chess(p, _) => p.to_ascii()
    Inner::Gomoku(g) => g.render()
    Inner::Othello(o) => o.render()
  }
}

///|
/// The number of moves played so far. For Go this counts stone placements
/// and passes by replaying the undo stack is not possible, so it reports
/// the number of stones currently on the board plus captured stones as an
/// approximation; for xiangqi and chess it is the exact move count.
pub fn Engine::move_count(self : Engine) -> Int {
  match self.inner {
    Inner::Go(g) => {
      let (b, w) = g.captures()
      let mut stones = 0
      let board = g.board()
      let n = g.size()
      for r in 0..<n {
        for c in 0..<n {
          if !(board.get(r, c) is @moonbaduk.Empty) {
            stones += 1
          }
        }
      }
      stones + b + w
    }
    Inner::Xiangqi(_, hist) => hist.length()
    Inner::Chess(_, hist) => hist.length()
    Inner::Gomoku(g) => g.stone_count()
    Inner::Othello(o) => o.counts().0 + o.counts().1
  }
}
