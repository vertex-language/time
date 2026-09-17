package time

// Sleep has two forms with one name, as every operation that can take real
// time does in Vertex's bedrock packages. In an async function the async
// form is the one chosen, and it needs `await`: it parks the task, and
// every other task runs meanwhile. Anywhere else the blocking form is the
// one chosen, and it stops the thread, which is all a synchronous caller
// could have had happen anyway. Blocking by accident in async code is a
// compile error, not a stalled executor.
//
//     func main() {                            // synchronous: blocks
//         time.Sleep(.Milliseconds(10))
//     }
//     func poll() async throws {               // async: parks the task
//         try await time.Sleep(.Milliseconds(10))
//     }

/// Stops the thread for at least `duration`. Zero or less returns at once.
public func Sleep(_ duration: Duration) {
    cclock_sleep(duration.nanos)
}

/// Suspends the task for at least `duration`, and every other task runs
/// meanwhile. Zero or less still lets the others run first.
///
/// It throws where Swift's `Task.sleep` does, for cancellation, so that a
/// caller written today does not change when cancellation arrives.
public func Sleep(_ duration: Duration) async throws {
    let nanos = duration.nanos > 0 ? uint64(duration.nanos) : 0
    try await Task.sleep(nanoseconds: nanos)
}

/// Stops the thread until at least `deadline`.
public func Sleep(until deadline: Instant) {
    cclock_sleep((deadline - Instant.Now()).nanos)
}

/// Suspends the task until at least `deadline`.
public func Sleep(until deadline: Instant) async throws {
    try await Sleep(deadline - Instant.Now())
}
