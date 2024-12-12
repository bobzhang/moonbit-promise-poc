///|
/// Q? what does pub/priv typealias mean?
/// Do we have abstract typealias?
type Resolver[V] Promise[V]

///|
/// Invairant:
/// the input may not be pending
/// A handler is a new abstraction: a function that takes a non-pending state
/// It will be used to fullfill or reject the promise when their state 
/// is ready to switch away from pending.
/// Only pending promises can have handlers waiting in the list
/// Once a promise is fullfilled or rejected, the handlers list is cleared
typealias Handler[V] = (State[V]) -> Unit

///|
fn write_once[V](self : Resolver[V], state : State[V]) -> Unit {
  guard let Pending = self._.state
  self._.state = state
}

///|
fn fullfill_or_reject[V](self : Resolver[V], state : State[V]) -> Unit {
  guard let Fullfilled(_) | Rejected(_) = state
  let handlers = self._.handlers
  self._.handlers = []
  self.write_once(state)
  for handler in handlers {
    handler(state)
  }
}

///|
pub fn reject[V](self : Resolver[V], error : Error) -> Unit {
  self.fullfill_or_reject(Rejected(error))
}

///|
pub fn fullfill[V](self : Resolver[V], value : V) -> Unit {
  self.fullfill_or_reject(Fullfilled(value))
}
