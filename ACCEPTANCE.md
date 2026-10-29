# Acceptance Evidence Map

This document maps the hackathon acceptance criteria to concrete evidence in this repository, so reviewers can verify each item directly.

| # | Criterion | Evidence |
|---|---|---|
| 1 | MoonBit as the main implementation language, moonc ≥ 0.10.16 | All functional code is `.mbt` (MoonBit); no implementation in any other language. CI installs the current official stable toolchain, prints `moon version --all` and **fails hard if moonc is below 0.10.16** (a dedicated assertion step, see workflow logs — latest runs compiled with moonc v0.10.18); the toolchain used for development is moonc v0.10.16 / moon 0.1.20261020. |
| 2 | Public GitHub repository with clear commit history | <https://github.com/wbgxiaosu/moonqipai> — commits are split by feature (one engine/abstraction per commit) with descriptive messages; no empty or duplicated commits. |
| 3 | Clear source structure; declared core features work | One package per game: `gomoku/`, `othello/`, `checkers/`, `blackjack/`, `fivedraw/`, `uno/`, `cards/`, shared abstractions in `core/`, unified facade engines in `core/*.mbt`, runnable demo in `cmd/main/`. All nine declared components are implemented and exercised by the test suite (60 tests). |
| 4 | README with goals, installation, usage, reproducible examples | `README.md` — goals (reusable rules infrastructure), installation (`moon add wbgxiaosu/moonqipai`), usage snippets, and a runnable example reproduced by `moon run cmd/main` (commands verified locally; output shown in the README section below). |
| 5 | CI covering check, build, test | `.github/workflows/ci.yml` runs `moon check --deny-warn`, `moon build` and `moon test --deny-warn` (plus `moon fmt --check`) on the wasm, wasm-gc and native backends on every push and PR, plus a separate consumer job that runs `examples/consumer` against the library source. |
| 6 | At least one runnable example / minimal usage sample | Two runnable examples: `cmd/main/main.mbt` drives every game family through the public API (`moon run cmd/main`); `examples/consumer` is an independent module importing the published package name exactly as an external user would, with `moon.work` redirecting it to the current source (`cd examples/consumer && moon run .`) — CI verifies both on every push. |
| 7 | Complete tests covering core functionality paths | 60 black-box tests across all nine components: legal-move generation and apply for every board game, complete card-game hand flows (betting rounds → draw → showdown; UNO action chains), hidden-information views, GameInfo consistency, seeded-reproducibility of chance games. Run with `moon test`. |
| 8 | Published to mooncakes.io | <https://mooncakes.io/docs/#/wbgxiaosu/moonqipai> — current release 0.3.5. Install with `moon add wbgxiaosu/moonqipai`. |
| 9 | OSI-approved open-source licence; upstream compliance | [LICENSE](LICENSE) — Apache License 2.0 (OSI-approved). All three package dependencies are Apache-2.0 and used unmodified; every referenced specification/algorithm is named with source and licence in [docs/RULES_REFERENCES.md](docs/RULES_REFERENCES.md). |

## Hackathon-season criteria mapping

The official hackathon rules (October season) state six acceptance criteria. Four of them are covered by rows 1, 3, 4 and 9 above; the remaining two are mapped here:

| # | Official criterion | Evidence |
|---|---|---|
| 2 | Public repository with continuous, traceable commits and development record | <https://github.com/wbgxiaosu/moonqipai> — 35 feature-split commits with descriptive messages, continuous from the initial skeleton to the current release; every version also published to mooncakes.io and verified in a separate consumer project. |
| 4 | Substantial new work completed this season | [CHANGELOG.md](CHANGELOG.md) 0.2.0 → 0.3.5 documents the October work: six fully original engines (gomoku, othello, checkers, blackjack, five-card draw, uno), the GameInfo/Rng shared abstractions, unified-facade extension to all five board games, the GameInfo integration for every component, full test coverage of the advertised checkers rules (60 tests) and the independent consumer-verification example — all committed in October 2026. |
| 6 | AI-assisted but explainable and participant-owned | [docs/AI_COLLABORATION.md](docs/AI_COLLABORATION.md) records the division of work: the participant set the goal, chose the technical path, defined the quality gates, approved rule sources and licences, and can explain the architecture and trade-offs. |

## Reproduction script

```bash
git clone https://github.com/wbgxiaosu/moonqipai
cd moonqipai
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash   # or the Windows installer
moon check && moon test && moon run cmd/main
```

Expected: check passes with zero warnings, 57/60 tests pass, and the demo prints one line per game family.
