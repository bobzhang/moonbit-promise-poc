///|
/// Abstract capability to settle the associated promise.
struct Resolver[V](Promise[V])

///|
/// Invariant:
/// the input may not be pending
/// A handler is a new abstraction: a function that takes a non-pending state
/// It will be used to fullfill or reject the promise when their state
/// is ready to switch away from pending.
/// Only pending promises can have handlers waiting in the list
/// Once a promise is fullfilled or rejected, the handlers list is cleared
type Handler[V] = (State[V]) -> Unit

///|
fn[V] Resolver::write_once(self : Resolver[V], state : State[V]) -> Unit {
  guard self.0.state is Pending else { abort("promise is already settled") }
  self.0.state = state
}

///|
fn[V] Resolver::fullfill_or_reject(
  self : Resolver[V],
  state : State[V],
) -> Unit {
  guard state is (Fullfilled(_) | Rejected(_)) else {
    abort("cannot settle a promise as pending")
  }
  let handlers = self.0.handlers
  self.0.handlers = []
  self.write_once(state)
  for handler in handlers {
    handler(state)
  }
}

///|
pub fn[V] Resolver::reject(self : Resolver[V], error : Error) -> Unit {
  self.fullfill_or_reject(Rejected(error))
}

///|
pub fn[V] Resolver::fullfill(self : Resolver[V], value : V) -> Unit {
  self.fullfill_or_reject(Fullfilled(value))
}
