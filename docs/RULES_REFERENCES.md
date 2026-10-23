# Rules & Algorithm References

Every external specification, rule set, algorithm and third-party dependency used by moonqipai is listed here with its concrete source, scope of use and licence. No reference in this project is vague: if a semantic detail was taken from a published document, that document is named and linked below; if a component is original, the rules it implements are identified as public-domain game rules with the sources the implementation was checked against.

**Nothing in this repository copies third-party code.** The only code-level dependencies are the MoonBit packages declared in `moon.mod` (see "Package dependencies" below). All other references describe *specifications and algorithms*, which are ideas, not code, and are implemented from scratch in this project.

## Board-game rules

### Go (Weiqi / Baduk) — delegated to wbgxiaosu/moonbaduk

- Rule core: [wbgxiaosu/moonbaduk](https://github.com/wbgxiaosu/moonbaduk) 0.1.0 (own work, Apache-2.0), published on [mooncakes.io](https://mooncakes.io/docs/#/wbgxiaosu/moonbaduk). moonqipai does not reimplement or modify Go rules; it delegates through an adapter.
- SGF serialization and coordinate vocabulary follow **SGF FF[4]** — the Smart Game Format specification, maintained at <https://www.red-bean.com/sgf/> (property definitions and coordinate system sections).
- Text-protocol notation follows **GTP v2** — the Go Text Protocol version 2 specification (Gunnar Farnebäck), <https://www.lysator.liu.se/~gunnar/gtp/gtp2-spec-draft2/gtp2-spec.html>; the protocol is also documented at Sensei's Library, <https://senseis.xmp.net/?GoTextProtocol>. moonqipai/moonbaduk use GTP vertex strings (e.g. `Q16`, letters skip `i`) as their native move notation.
- Scope of use: move notation format only. Territory scoring, ko, suicide and life-and-death semantics live entirely in moonbaduk and are not redefined here.

### Xiangqi (Chinese chess) — delegated to wbgxiaosu/xiangqi

- Rule core: [wbgxiaosu/xiangqi](https://github.com/wbgxiaosu/xiangqi) 0.2.3 (own work, Apache-2.0), published on [mooncakes.io](https://mooncakes.io/docs/#/wbgxiaosu/xiangqi). Not reimplemented here.
- Move notation follows **ICCS coordinate notation** (Internet Chinese Chess Server coordinates, file–rank pairs such as `h3-e3`), the de-facto standard for computer Xiangqi; see the [Xiangqi notation overview on Wikipedia](https://en.wikipedia.org/wiki/Xiangqi#Notation).
- Chinese rules background (piece movement, palace/river constraints, perpetual-check restrictions): 《中国象棋竞赛规则（2020 版）》，国家体育总局审定，人民体育出版社。 This edition is the current official Chinese Xiangqi rule book.
- Scope of use: notation only; rules semantics stay in the xiangqi package.

### International chess — delegated to L76148/moonchess

- Rule core: [L76148/moonchess](https://mooncakes.io/docs/#/L76148/moonchess) 0.1.1 (Apache-2.0), third-party. moonqipai consumes it as a library dependency and does not reimplement chess rules.
- **FIDE Laws of Chess**, effective 1 January 2023 edition, published by the International Chess Federation at <https://handbook.fide.com/chapter/LawsOfChess> — the authoritative rule source the moonchess engine's semantics are measured against. moonqipai does not modify or reinterpret them.
- Move notation follows **UCI** (Universal Chess Interface) coordinate strings such as `e2e4`; the interface is documented in the Chess Programming Wiki's UCI entry, <https://www.chessprogramming.org/UCI>.
- Scope of use: move notation only.

### Gomoku (free-style) — original engine in `gomoku/`

- Game: free-style five-in-a-row (no opening restrictions, overlines win), as described at <https://en.wikipedia.org/wiki/Gomoku>.
- Scope of use: the winning condition (five or more in a row in any of four directions) and the draw condition (full board). All scanning, undo and board-size logic (2..=26) is original code.

### Othello (Reversi) — original engine in `othello/`

- Game: classic 8×8 Reversi with bracketing flips, forced pass and majority scoring, as described at <https://en.wikipedia.org/wiki/Reversi>.
- Scope of use: the standard 8×8 initial placement and the flip/pass/scoring mechanics. All engine code is original.

### Checkers (English draughts) — original engine in `checkers/`

- Game: English draughts on 8×8 with mandatory captures, multi-jump chains, crowning and kings moving one square diagonally, as described at <https://en.wikipedia.org/wiki/English_draughts>.
- Scope of use: the rules listed above. The mandatory-capture enforcement, jump-chain search and crowning implementation are original code.

## Card-game rules

### Blackjack — original engine in `blackjack/`

- Rules implemented (all standard casino rules, cross-checked against <https://en.wikipedia.org/wiki/Blackjack>):
  - ace counts 11 unless it would bust (soft/hard totals);
  - a natural pays **3 : 2**;
  - dealer stands on all 17s (including soft 17);
  - the dealer's second card is hidden until the player's hand is settled.
- Scope of use: the four rule bullets above. The shoe model, seeded shuffling, hidden-card observer API and settlement types are original code. The engine implements no casino-proprietary variation and uses no branded material.

### Five-card draw — original engine in `fivedraw/`

- Rules implemented (cross-checked against <https://en.wikipedia.org/wiki/Five-card_draw>): five cards per player, a betting round (check/call/raise/fold), a single draw of up to three cards, a second betting round, showdown with side-pot-free pot award.
- Scope of use: hand-flow structure. Betting bookkeeping, seat-hidden hands and showdown logic are original code.

### UNO — original engine in `uno/`

- Rules implemented (cross-checked against the standard 108-card game described at <https://en.wikipedia.org/wiki/Uno_(card_game)>): 108-card deck, skip/reverse/draw-two/wild/wild-draw-four effects, colour choice on wilds, one-card call window discipline, draw-pile reshuffle, 2..=8 players.
- Scope of use: public-domain description of the card game's mechanics. The card representation, effect chain, draw-window state machine and hidden-hand model are original code. "UNO" is used nominatively to identify the game's rules; this project is unaffiliated with Mattel and reproduces no branded artwork or text.

### Poker hand evaluation — original in `cards/`

- Ranking model: the standard 5-card hand categories (high card … straight flush), cross-checked against <https://en.wikipedia.org/wiki/List_of_poker_hands>; 7-card selection follows the "best five of seven" convention.
- Scope of use: category ordering and comparison semantics. All counting and comparison code is original.

## Algorithms

### splitmix64 — `core.Rng`

- Algorithm: Guy L. Steele Jr., Doug Lea, Christine H. Flood, *"Fast Splittable Pseudorandom Number Generators"*, OOPSLA 2014; canonical single-file reference implementation by Sebastiano Vigna at <https://xorshift.di.unimi.it/splitmix64.c> (public domain dedication).
- Scope of use: the mixing function's arithmetic structure (constants `0x9E3779B97F4A7C15`, `0xBF58476D1CE4E5B9`, `0x94D049BB133111EB`). Written from scratch in MoonBit; no code copied.
- Fisher–Yates shuffling follows the modern (Durstenfeld/Knuth) form, Algorithm P in Donald E. Knuth, *The Art of Computer Programming*, Vol. 2, §3.4.2.

### GameInfo metadata — inspired by OpenSpiel

- Inspiration: the game-type metadata model of [OpenSpiel](https://github.com/google-deepmind/open_spiel) (Apache-2.0), which characterizes games by player range, information completeness and chance involvement.
- Scope of use: the *idea* of structural game metadata. `core.GameInfo` is an original MoonBit struct with its own field set; no OpenSpiel code or API surface is copied.

## Package dependencies (code-level)

| Package | Version | Author | Licence | Role |
|---|---|---|---|---|
| wbgxiaosu/moonbaduk | 0.1.0 | wbgxiaosu (this project's author) | Apache-2.0 | Go rules core |
| wbgxiaosu/xiangqi | 0.2.3 | wbgxiaosu | Apache-2.0 | Xiangqi rules core |
| L76148/moonchess | 0.1.1 | L76148 | Apache-2.0 | Chess rules core |

All three are Apache-2.0 and consumed as unmodified library dependencies, satisfying the requirement that derived or consumed work respect upstream licences.
