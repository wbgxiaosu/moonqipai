# Acceptance Evidence Map

This document maps the hackathon acceptance criteria to concrete evidence in this repository, so reviewers can verify each item directly.

| # | Criterion | Evidence |
|---|---|---|
| 1 | MoonBit as the main implementation language, moonc ≥ 0.10.14 | All functional code is `.mbt` (MoonBit); no implementation in any other language. CI installs the current official stable toolchain and prints `moon version --all` (see workflow logs); the toolchain used for development is moonc v0.10.16 / moon 0.1.20261020. |
| 2 | Public GitHub repository with clear commit history | <https://github.com/wbgxiaosu/moonqipai> — commits are split by feature (one engine/abstraction per commit) with descriptive messages; no empty or duplicated commits. |
| 3 | Clear source structure; declared core features work | One package per game: `gomoku/`, `othello/`, `checkers/`, `blackjack/`, `fivedraw/`, `uno/`, `cards/`, shared abstractions in `core/`, unified facade engines in `core/*.mbt`, runnable demo in `cmd/main/`. All nine declared components are implemented and exercised by the test suite (57 tests). |
| 4 | README with goals, installation, usage, reproducible examples | `README.md` — goals (reusable rules infrastructure), installation (`moon add wbgxiaosu/moonqipai`), usage snippets, and a runnable example reproduced by `moon run cmd/main` (commands verified locally; output shown in the README section below). |
| 5 | CI covering check, build, test | `.github/workflows/ci.yml` runs `moon check`, `moon build` and `moon test` (plus `moon fmt --check`) on the wasm, wasm-gc and native backends on every push and PR. |
| 6 | At least one runnable example / minimal usage sample | `cmd/main/main.mbt` drives every game family through the public API. Reproduce with: `moon run cmd/main`. Expected output includes `chess legal moves: 29`, `othello legal moves: 4`, `five-card draw winner: seat 0, pot 3`, `hand 9c 9d 9h 2s 2c = full house`. |
| 7 | Complete tests covering core functionality paths | 57 black-box tests across all nine components: legal-move generation and apply for every board game, complete card-game hand flows (betting rounds → draw → showdown; UNO action chains), hidden-information views, GameInfo consistency, seeded-reproducibility of chance games. Run with `moon test`. |
| 8 | Published to mooncakes.io | <https://mooncakes.io/docs/#/wbgxiaosu/moonqipai> — current release 0.3.1. Install with `moon add wbgxiaosu/moonqipai`. |
| 9 | OSI-approved open-source licence; upstream compliance | [LICENSE](LICENSE) — Apache License 2.0 (OSI-approved). All three package dependencies are Apache-2.0 and used unmodified; every referenced specification/algorithm is named with source and licence in [docs/RULES_REFERENCES.md](docs/RULES_REFERENCES.md). |

## Reproduction script

```bash
git clone https://github.com/wbgxiaosu/moonqipai
cd moonqipai
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash   # or the Windows installer
moon check && moon test && moon run cmd/main
```

Expected: check passes with zero warnings, 57/57 tests pass, and the demo prints one line per game family.
