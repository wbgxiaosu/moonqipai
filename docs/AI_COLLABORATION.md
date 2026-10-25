# AI Collaboration & Authorship Statement

This project was developed by the participant (wbgxiaosu / 苏春昊) with AI coding assistance, in line with the hackathon rule that AI tools may be used for code generation, interface design and test completion, provided the participant controls and can explain the project's goals, technical path and quality boundaries. This document records how that division of work worked in practice.

## What the participant decided and owns

- **Project goal and scope.** The direction — a unified board & card game rules foundation for MoonBit, as reusable infrastructure rather than a game — was set by the participant, together with the deliberate choice *not* to reimplement the three classical board-game rule cores (Go, Xiangqi, chess) but to consume them as published mooncakes dependencies and invest original work in the unified abstractions and under-served games (Gomoku, Othello, Checkers, Blackjack, Five-card draw, UNO).
- **Technical path.** The four-layer architecture (per-game engines → unified `Engine` facade → structural `GameInfo` metadata → seeded `Rng` reproducibility) and the observer-semantics approach to hidden information were chosen through design discussions between the participant and the AI assistant, with the participant evaluating alternatives (e.g. one facade for board games only vs. forcing card games through the same interface; the facade covers the five board games, while card games share the `GameInfo`/`Rng` abstractions without pretending turn-based semantics apply to them).
- **Quality boundaries.** The participant defined the acceptance gates for every change: black-box tests only (no tests against implementation internals), zero warnings from `moon check`, all three backends (wasm, wasm-gc, native) green, every chance-driven game reproducible from a seed, and every public rule source named with a concrete citation in [RULES_REFERENCES.md](RULES_REFERENCES.md).
- **Reference and licence decisions.** Which specifications to cite (SGF FF[4], GTP v2, FIDE Laws 2023, ICCS, the 2020 Chinese Xiangqi rule book, the splitmix64 paper) and how to comply with upstream Apache-2.0 licences were reviewed and approved by the participant.

## How the work was done

- The AI assistant proposed and drafted engine implementations, tests and documentation; the participant reviewed behavior against the cited rule sources, drove bug-fixing iterations (for example, paired-rank counting in poker evaluation, dealer-hole-card settlement order in blackjack, pass-flow edge cases in Othello), and rejected designs that leaked game-specific details into the shared abstractions.
- Every commit is split by feature with a descriptive message; the full history is continuous and traceable on GitHub, and each version was published to mooncakes.io and verified by installing it into a separate consumer project.
- The participant can explain, and takes responsibility for, the overall architecture, the design trade-offs, the correctness of the rules implemented, and the compliance status of all dependencies.

## Where to look for evidence

| Claim | Evidence |
|---|---|
| Continuous, traceable development | Commit history on <https://github.com/wbgxiaosu/moonqipai> (feature-split commits) |
| Substantial new work this season | Changelog 0.2.0 → 0.3.2 in [CHANGELOG.md](../CHANGELOG.md) — six original engines, unified facade extensions, GameInfo/Rng, all committed in October 2026 |
| Quality gates actually enforced | `.github/workflows/ci.yml` — `moon fmt --check`, `moon check`, `moon build`, `moon test` on three backends |
| Rules provenance | [RULES_REFERENCES.md](RULES_REFERENCES.md) |
