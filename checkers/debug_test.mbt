///|
test "debug: replay to move 7" {
  let c = @checkers.Checkers::new()
  let steps : Array[@checkers.Move] = [
    { from: 23, to: 30, captures: [], },
    { from: 44, to: 37, captures: [], },
    { from: 30, to: 44, captures: [37], },
    { from: 51, to: 37, captures: [44], },
    { from: 17, to: 24, captures: [], },
    { from: 60, to: 51, captures: [], },
    { from: 24, to: 33, captures: [], },
  ]
  for k, m in steps {
    let r = c.play(m)
    match r {
      Ok(_) => println("step \{k}: \{m.from}->\{m.to} ok")
      Err(e) => {
        println("step \{k} ERR: \{@checkers.CheckersError::message(e)}")
        break
      }
    }
  }
  println(c.render())
  for lm in c.legal_moves() {
    println("legal \{lm.from}->\{lm.to} caps=\{lm.captures.length()}")
  }
}
