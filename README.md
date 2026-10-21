# moonqipai

Unified board & card game rules foundation for MoonBit: **Go (Weiqi/Baduk), Xiangqi (Chinese chess), International Chess and generic poker** behind one engine interface.

This is a reusable infrastructure library, not a game. It gives tool builders — GUI clients, tournament servers, teaching software, AI harnesses, data pipelines — one consistent API for rules adjudication, legal-move enumeration, undo and result reporting across games.

## Components

| Package | What it provides | Backed by |
|---|---|---|
| `core` | Unified game model: `GameId`, `Player`, `Outcome`, `EngineError` and the `Engine` facade with `apply` / `legal_moves` / `undo` / `turn` / `is_over` / `outcome` / `render` | [wbgxiaosu/moonbaduk](https://mooncakes.io/docs/#/wbgxiaosu/moonbaduk) (Go), [wbgxiaosu/xiangqi](https://mooncakes.io/docs/#/wbgxiaosu/xiangqi) (Xiangqi), [L76148/moonchess](https://mooncakes.io/docs/#/L76148/moonchess) (chess) |
| `cards` | Original generic poker: 52-card deck, seeded deterministic shuffle, dealing, 5-card evaluation and best-of-5..7 comparison (high card → straight flush) | — (original) |

Each game keeps its native text notation through the unified interface:

- Go — GTP vertices (`Q16`, `pass`; the letter `i` is skipped)
- Xiangqi — ICCS coordinates (`h2e2`)
- Chess — UCI coordinates (`e2e4`, promotions as `e7e8q`)

## Usage

```moonbit
// one interface, four games
let c : @core.Engine = @core.Engine::make(@core.Chess)
let _ = c.apply("e2e4")
let moves : Array[String] = c.legal_moves()

let g : @core.Engine = @core.Engine::make(@core.Go(19, 7.5))
let _ = g.apply("Q16")
let _ = g.apply("pass")

// terminal result in game-conventional notation
let outcome : @core.Outcome? = c.outcome() // e.g. Winner(P2) → "0-1"

// poker
let deck : @cards.Deck = @cards.Deck::shuffled(42UL) // deterministic
let hand : Array[@cards.Card] = deck.deal(5)
let value : @cards.HandValue? = @cards.evaluate_five(hand)
```

See `cmd/main` for a runnable example. The example binary is documentation only — the deliverable is the library.

## Unified result strings

| Outcome | Go | Xiangqi / Chess |
|---|---|---|
| first player wins | `B+24.5` (margin) | `1-0` |
| second player wins | `W+7.5` (margin) | `0-1` |
| draw | `0` | `1/2-1/2` |

## Engine capabilities per game

| Capability | Go | Xiangqi | Chess |
|---|---|---|---|
| legal-move enumeration | ✓ | ✓ | ✓ |
| undo | ✓ | ✓ | ✓ |
| terminal-state detection | double pass | checkmate / stalemate (a loss) | checkmate / stalemate / fifty-move rule |
| scoring | Chinese area rules with komi | decisive only | decisive only |

Xiangqi repetition adjudication and chess threefold-repetition / insufficient-material draws are not yet wired through the unified interface; the underlying libraries expose the needed primitives (Zobrist hashing, position history) for a future version.

## Building and testing

```bash
moon check
moon test
moon run cmd/main
```

CI runs `moon check` and `moon test` on the wasm, wasm-gc and native backends.

## Scope statement

moonqipai is an original MoonBit codebase. The Go, Xiangqi and chess rule cores are delegated to the published mooncakes packages listed above (moonbaduk and xiangqi by the same author; moonchess by L76148, Apache-2.0) — moonqipai's contribution is the unified engine layer, the normalised outcome model and the poker module, all of which are new code written for this project. Rules semantics follow the public SGF FF[4], GTP v2, ICCS, UCI and FIDE/Xiangqi rule documents.
