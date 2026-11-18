///|
enum State[V] {
  Pending
  Fullfilled(V)
  Rejected(Error)
}

///|
struct Promise[V] {
  mut state : State[V]
  mut handlers : Array[Handler[V]]
}

///|
fn[V] Promise::enqueue(self : Promise[V], handler : Handler[V]) -> Unit {
  self.handlers.push(handler)
}

///|
pub fn[V] make() -> (Promise[V], Resolver[V]) {
  let p : Promise[V] = { state: Pending, handlers: [], }
  (p, Resolver(p))
}

///|
pub fn[V] Promise::state(self : Promise[V]) -> State[V] {
  self.state
}

///|
pub fn[A, B] Promise::then(
  self : Promise[A],
  callback : (A) -> Promise[B],
) -> Promise[B] {
  match self.state {
    Fullfilled(value) => callback(value)
    Rejected(error) => { state: Rejected(error), handlers: [], }
    Pending => {
      let (p, r) = make()
      self.enqueue(fn(state) {
        match state {
          Pending => abort("pending promise handler")
          Rejected(error) => r.reject(error)
          Fullfilled(value) => {
            let p = callback(value)
            match p.state {
              Fullfilled(value) => r.fullfill(value)
              Rejected(error) => r.reject(error)
              Pending =>
                p.enqueue(fn(state) {
                  match state {
                    Pending => abort("pending promise handler")
                    Rejected(error) => r.reject(error)
                    Fullfilled(value) => r.fullfill(value)
                  }
                })
            }
          }
        }
      })
      p
    }
  }
}
