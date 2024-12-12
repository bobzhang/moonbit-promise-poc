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
fn enqueue[V](self : Promise[V], handler : Handler[V]) -> Unit {
  self.handlers.push(handler)
}

///|
pub fn make[V]() -> (Promise[V], Resolver[V]) {
  let p : Promise[V] = { state: Pending, handlers: [] }
  (p, p)
}

///|
pub fn state[V](self : Promise[V]) -> State[V] {
  self.state
}

///|
pub fn then[A, B](
  self : Promise[A],
  callback : (A) -> Promise[B]
) -> Promise[B] {
  match self.state {
    Fullfilled(value) => callback(value)
    Rejected(error) => { state: Rejected(error), handlers: [] }
    Pending => {
      let (p, r) = make()
      self.enqueue(
        fn {
          Pending => ...
          Rejected(error) => r.reject(error)
          Fullfilled(value) => {
            let p = callback(value)
            match p.state {
              Fullfilled(value) => r.fullfill(value)
              Rejected(error) => r.reject(error)
              Pending =>
                p.enqueue(
                  fn {
                    Pending => ...
                    Rejected(error) => r.reject(error)
                    Fullfilled(value) => r.fullfill(value)
                  },
                )
            }
          }
        },
      )
      p
    }
  }
}
