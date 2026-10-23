// moonqipai module configuration
name = "wbgxiaosu/moonqipai"

version = "0.3.0"

readme = "README.md"

repository = "https://github.com/wbgxiaosu/moonqipai"

license = "Apache-2.0"

keywords = [
  "board-game",
  "card-game",
  "go",
  "weiqi",
  "baduk",
  "xiangqi",
  "chess",
  "poker",
  "rules-engine",
  "sgf",
  "gtp",
]

preferred_target = "wasm-gc"

description = "Unified board & card game rules foundation for MoonBit: Go, Xiangqi, Chess, Gomoku, Othello, Blackjack, Five-card Draw and UNO behind one interface, with shared GameInfo/Rng abstractions"

import {
  "L76148/moonchess@0.1.1",
  "wbgxiaosu/moonbaduk@0.1.0",
  "wbgxiaosu/xiangqi@0.2.3",
}
