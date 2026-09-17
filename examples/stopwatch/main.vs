// Times a blocking sleep, then two tasks sleeping at once.
//
//     vsc run stopwatch
package main

import "time"

func nap() {
    // A synchronous function: this Sleep is the blocking one.
    time.Sleep(.Milliseconds(50))
}

func main() async -> int32 {
    print("it is \(time.Timestamp.Now())")

    var start = time.Instant.Now()
    nap()
    print("a blocking 50ms sleep took \(start.Elapsed())")

    // Two tasks each sleep 100ms. They overlap, so the pair takes 100ms,
    // not 200.
    start = time.Instant.Now()
    let a = Task { () async -> Void in try? await time.Sleep(.Milliseconds(100)) }
    let b = Task { () async -> Void in try? await time.Sleep(.Milliseconds(100)) }
    await a.value
    await b.value
    print("two 100ms sleeps side by side took \(start.Elapsed())")
    return 0
}
