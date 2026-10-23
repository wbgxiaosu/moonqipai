///|
/// Describes the structural properties of a game, in the spirit of
/// OpenSpiel's game-type metadata. Tooling uses this to decide how to
/// render, log or simulate a game without knowing its rules.
pub(all) struct GameInfo {
  /// Number of sides that participate: (min, max). Fixed games have
  /// min == max; e.g. Go is (2, 2), five-card draw poker is (2, 6).
  players : (Int, Int)
  /// Whether every participant sees the full position (Go, Gomoku,
  /// Othello, Xiangqi, chess) or some information is hidden (poker,
  /// blackjack).
  perfect_information : Bool
  /// Whether randomness influences the game state (card shuffles, dice).
  has_chance : Bool
  /// Whether the participants move strictly in turn (false for Go-style
  /// turn games, true would indicate simultaneous-move games).
  sequential : Bool
} derive(Eq, Debug)

///|
pub extend GameInfo with Eq::{equal, not_equal}

///|
pub extend GameInfo with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// A uniform pseudo-random source: splitmix64 over a UInt64 seed. The
/// same seed reproduces the same sequence on every backend, which makes
/// chance-driven games fully reproducible and testable.
pub struct Rng {
  priv mut state : UInt64
}

///|
/// Creates a random source from a seed.
pub fn Rng::new(seed : UInt64) -> Rng {
  { state: seed }
}

///|
/// Produces the next uniform UInt64 and advances the state.
pub fn Rng::next_u64(self : Rng) -> UInt64 {
  let z = self.state + 0x9E3779B97F4A7C15UL
  self.state = z
  let mut r = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9UL
  r = (r ^ (r >> 27)) * 0x94D049BB133111EBUL
  r = r ^ (r >> 31)
  r
}

///|
/// Produces the next uniform value in `0 ..< bound` (must be positive).
pub fn Rng::below(self : Rng, bound : Int) -> Int {
  (self.next_u64() % (bound.to_uint64())).to_int()
}

///|
/// Shuffles a mutable array in place with the Fisher-Yates scheme.
pub fn[R] Rng::shuffle(self : Rng, items : Array[R]) -> Unit {
  let n = items.length()
  for k in 0..<(n - 1) {
    let i = n - 1 - k
    let j = self.below(i + 1)
    let tmp = items[i]
    items[i] = items[j]
    items[j] = tmp
  }
}

///|
/// The structural profile of each board game behind the unified engine.
pub fn Engine::game_info(self : Engine) -> GameInfo {
  match self.game_id() {
    Go(_, _) =>
      { players: (2, 2), perfect_information: true, has_chance: false, sequential: true }
    Xiangqi =>
      { players: (2, 2), perfect_information: true, has_chance: false, sequential: true }
    Chess =>
      { players: (2, 2), perfect_information: true, has_chance: false, sequential: true }
    Gomoku(_) =>
      { players: (2, 2), perfect_information: true, has_chance: false, sequential: true }
    Othello =>
      { players: (2, 2), perfect_information: true, has_chance: false, sequential: true }
  }
}
