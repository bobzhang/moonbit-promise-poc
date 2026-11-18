///|
test "hello" {
  if @lib.hello() != "Hello, world!" {
    fail("@lib.hello() != \"Hello, world!\"")
  }
}

///|
test "public promise and resolver share settlement" {
  let (promise, resolver) = @lib.make()
  let values = []
  let _ = promise
    .then(value => {
      values.push(value)
      let (next, resolve_next) = @lib.make()
      resolve_next.fullfill(value + 1)
      next
    })
    .then(value => {
      values.push(value)
      let (next, resolve_next) = @lib.make()
      resolve_next.fullfill(())
      next
    })
  resolver.fullfill(3)
  assert_eq(values, [3, 4])
}
