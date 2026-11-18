///|
suberror TestError {
  Failed
}

///|
fn fulfilled(value : Int32) -> Promise[Int32] {
  let (p, r) = make()
  r.fullfill(value)
  p
}

///|
fn rejected() -> Promise[Int32] {
  let (p, r) = make()
  r.reject(Failed)
  p
}

///|
fn expect_value(p : Promise[Int32], expected : Int32) -> Unit raise {
  match p.state() {
    Fullfilled(value) => assert_eq(value, expected)
    _ => fail("expected fulfilled promise")
  }
}

///|
fn expect_rejected(p : Promise[Int32]) -> Unit raise {
  match p.state() {
    Rejected(Failed) => ()
    _ => fail("expected rejection with original error")
  }
}

///|
test "then on settled promises is synchronous" {
  let values = []
  let p = fulfilled(3).then(value => {
    values.push(value)
    fulfilled(value + 1)
  })
  expect_value(p, 4)
  assert_eq(values, [3])
  let p = rejected().then(value => {
    values.push(value)
    fulfilled(value)
  })
  expect_rejected(p)
  assert_eq(values, [3])
}

///|
test "pending callbacks run in registration order after state is set" {
  let (p, r) = make()
  let values = []
  let first = p.then(value => {
    values.push(value)
    // Reentrant registration sees the settled state immediately.
    p.then(other => {
      values.push(other + 10)
      fulfilled(other + 1)
    })
  })
  let second = p.then(value => {
    values.push(value + 20)
    fulfilled(value + 2)
  })
  assert_true(first.state() is Pending)
  assert_true(second.state() is Pending)
  r.fullfill(3)
  assert_eq(values, [3, 13, 23])
  expect_value(first, 4)
  expect_value(second, 5)
  assert_eq(p.handlers.length(), 0)
}

///|
test "rejection propagates to pending chains without callbacks" {
  let (p, r) = make()
  let calls = []
  let next = p.then(value => {
    calls.push(value)
    fulfilled(value)
  })
  r.reject(Failed)
  expect_rejected(p)
  expect_rejected(next)
  assert_eq(calls.length(), 0)
  assert_eq(p.handlers.length(), 0)
}

///|
test "pending chain adopts already rejected callback result" {
  let (p, r) = make()
  let next = p.then(_ => rejected())
  r.fullfill(1)
  expect_rejected(next)
}

///|
test "pending chain adopts later fulfillment" {
  let (p, r) = make()
  let (inner, inner_resolver) = make()
  let next = p.then(_ => inner)
  r.fullfill(1)
  assert_true(next.state() is Pending)
  inner_resolver.fullfill(7)
  expect_value(next, 7)
}

///|
test "pending chain adopts later rejection" {
  let (p, r) = make()
  let (inner, inner_resolver) = make()
  let next = p.then(_ => inner)
  r.fullfill(1)
  assert_true(next.state() is Pending)
  inner_resolver.reject(Failed)
  expect_rejected(next)
}

///|
test "panic duplicate fulfillment" {
  let (_, r) = make()
  r.fullfill(1)
  r.fullfill(2)
}

///|
test "panic rejection after fulfillment" {
  let (_, r) = make()
  r.fullfill(1)
  r.reject(Failed)
}

///|
test "panic fulfillment after rejection" {
  let (_, r) = make()
  r.reject(Failed)
  r.fullfill(1)
}
