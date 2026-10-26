# Changelog

All notable changes to moonqipai. This project follows a features-first changelog; every version is published on [mooncakes.io](https://mooncakes.io/docs/#/wbgxiaosu/moonqipai).

## 0.3.3 — 2026-10-26

- Checkers test coverage completed: a two-segment jump chain (including the mid-chain `MustContinueJump` rejection), a crowned king stepping backwards, and a full elimination win — every headline rule of the engine now has a dedicated test (61 tests in total per `moon test`).

## 0.3.2 — 2026-10-23

- Documentation and metadata sync: description now lists Checkers; README adds an installation section and the verified consumer-side `moon.pkg` import configuration.
- New: [ACCEPTANCE.md](ACCEPTANCE.md) maps the acceptance criteria to verifiable evidence; [docs/RULES_REFERENCES.md](docs/RULES_REFERENCES.md) names every referenced specification, algorithm and dependency with concrete sources and licences.

## 0.3.1 — 2026-10-23

- All nine components now expose `game_info()`: the board-game `Engine` returns unified metadata per game, while blackjack, five-card draw and uno each describe their player range, hidden information and chance involvement.

## 0.3.0 — 2026-10-23

- New original engines: **uno** (108-card deck, action-card effect chains, draw-window discipline, 2–8 players) and **checkers** (English draughts: mandatory captures, jump chains, crowning, blockade endings).
- Gomoku and Othello join the unified `core.Engine` facade — one interface now covers all five board games (Go, Xiangqi, chess, Gomoku, Othello), with `GameId` variants `Gomoku(size)` and `Othello`.

## 0.2.0 — 2026-10-23

- New original engines: **gomoku** (free-style, 2–26 boards, four-direction line scan, undo), **othello** (eight-direction bracketing flips, forced pass, majority scoring), **blackjack** (soft-ace counting, 3:2 naturals, dealer stands on 17, hole-card hidden until settlement) and **five-card draw** (2–6 players, betting rounds, discards, showdown).
- `core` adds `GameInfo` (OpenSpiel-style structural metadata) and a seeded `Rng` (splitmix64 + Fisher–Yates), making all chance-driven games reproducible from a seed.

## 0.1.0 — 2026-10-21

- Initial release: unified rules foundation with Go, Xiangqi and International chess delegated to their published mooncakes rule cores behind adapter engines, plus the `cards` utilities (52-card deck, seeded shuffle, 5–7-card hand evaluation).
