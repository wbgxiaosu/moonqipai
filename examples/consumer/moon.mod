// consumer-side example: depends on the published mooncakes package;
// inside this workspace the dependency is redirected to the local
// source by moon.work, so CI verifies the current tree, not a stale release.
name = "wbgxiaosu/moonqipai-consumer-example"

version = "0.1.0"

license = "Apache-2.0"

preferred_target = "wasm-gc"

import {
  "wbgxiaosu/moonqipai@0.3.5",
}
