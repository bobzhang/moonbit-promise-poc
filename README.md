# Promise prototype in MoonBit

`make()` creates a promise and its resolver. The existing `then`, `state`,
`fullfill`, and `reject` methods retain their names; promise, resolver, and state
representations remain abstract outside the library.

Callbacks run synchronously, including callbacks registered on an already
fulfilled promise. A pending chain adopts the promise returned by its callback,
and rejection propagates without calling fulfillment callbacks.

A resolver may settle its promise once. Settling it again aborts, preserving the
original guard's invariant. This prototype does not implement JavaScript-style
microtasks or cycle rejection.

Run `moon check --target all --deny-warn` and `moon test --target all` to validate.
CI checks the rolling `latest` and `pre-release` toolchains every Friday and on
pushes and pull requests.
