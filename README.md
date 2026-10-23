# moonqipai

Unified board & card game rules foundation for MoonBit: **seven games behind shared abstractions** — Go, Xiangqi (Chinese chess), International Chess, Gomoku, Othello, Blackjack and Five-card Draw.

This is a reusable infrastructure library, not a game. It gives tool builders — GUI clients, tournament servers, teaching software, AI harnesses, data pipelines — one consistent model for rules adjudication, legal-action enumeration, undo, hidden-information views and result reporting across games.

## Game coverage

| Game | Package | Implementation | Type |
|---|---|---|---|
| Go (Weiqi/Baduk) | `core` engine | delegated to [wbgxiaosu/moonbaduk](https://mooncakes.io/docs/#/wbgxiaosu/moonbaduk) | turn-based, perfect info |
| Xiangqi (Chinese chess) | `core` engine | delegated to [wbgxiaosu/xiangqi](https://mooncakes.io/docs/#/wbgxiaosu/xiangqi) | turn-based, perfect info |
| International chess | `core` engine | delegated to [L76148/moonchess](https://mooncakes.io/docs/#/L76148/moonchess) | turn-based, perfect info |
| Gomoku (free-style) | `gomoku` | **original** — 2..=26 boards, four-direction line scan, undo | turn-based, perfect info |
| Othello (Reversi) | `othello` | **original** — eight-direction bracketing flips, pass flow, majority scoring | turn-based, perfect info |
| Blackjack | `blackjack` | **original** — seeded shoe, dealer hole card hidden, 3:2 naturals, dealer-stands-on-17 | chance + hidden info |
| Five-card draw | `fivedraw` | **original** — 2..=6 players, two betting rounds, discards, showdown | chance + hidden info + multi-player |
| Generic poker evaluation | `cards` | **original** — 52-card deck, seeded splitmix64 shuffle, 5..7-card hand evaluation | utilities |

Four of the seven games (plus the poker utilities) are original code written for this project; the three classical board-game rule cores are delegated to published mooncakes packages instead of being reimplemented.

## Shared abstractions

- **`core.Engine`** — one facade for the five board games: `apply` / `legal_moves` / `undo` / `turn` / `is_over` / `outcome` / `render`, with per-game native notation (GTP vertices, ICCS, UCI, coordinates).
- **`core.GameInfo`** — structural metadata in the spirit of OpenSpiel's game type: player-count range, perfect/imperfect information, chance involvement, sequential turns. Tools branch on this instead of hard-coding rules.
- **`core.Rng`** — seeded splitmix64 source; every chance-driven game is fully reproducible from its seed.
- **Hidden information** — engines only expose what the acting player may see: blackjack hides the dealer hole card until settlement, five-card draw exposes hands solely through `hand_of(seat)` for the seat's owner and publishes a textual action log for everyone else.
- **`Outcome`** — normalised terminal results with record strings ("1-0") and game-conventional margins ("B+24.5"), plus structured settlement (payout multipliers in blackjack, pot collection in five-card draw).

## Usage

```moonbit
// one interface for all board games
let c : @core.Engine = @core.Engine::make(@core.Chess)
let _ = c.apply("e2e4")
let moves : Array[String] = c.legal_moves()

// original gomoku
let g : @gomoku.Gomoku = @gomoku.Gomoku::standard()
let _ = g.play(7, 7)

// blackjack with a reproducible shoe
let bj : @blackjack.Blackjack = @blackjack.Blackjack::new(42UL)
let _ = bj.act(@blackjack.Hit)

// complete five-card draw hand, 2..=6 players
let p : @fivedraw.DrawPoker = @fivedraw.DrawPoker::new(4, 7UL)
let _ = p.bet(0, @fivedraw.Call)
```

See `cmd/main` for a runnable example of every game family. The example binary is documentation only — the deliverable is the library.

## Building and testing

```bash
moon check
moon test
moon run cmd/main
```

CI runs `moon check` and `moon test` on the wasm, wasm-gc and native backends.

## Roadmap

- Unified engine integration for gomoku/othello into `core.Engine` (they are standalone engines today);
- more card games on the shared betting skeleton (stud, hearts);
- simultaneous-action and repeated-play metadata extensions to `GameInfo`.

## Scope statement

moonqipai is an original MoonBit codebase. The Go, Xiangqi and chess rule cores are delegated to the published mooncakes packages listed above (moonbaduk and xiangqi by the same author; moonchess by L76148, Apache-2.0) — moonqipai's contribution is the unified engine layer, the normalised outcome model, the GameInfo/Rng abstractions, the poker utilities and four fully original game engines (gomoku, othello, blackjack, five-card draw). Rules semantics follow the public SGF FF[4], GTP v2, ICCS, UCI, FIDE/Xiangqi rule documents and standard casino rules.
