package time

/// A moment on the monotonic clock: for measuring how long something took
/// and for deadlines, never for telling the time.
///
/// It never goes backwards, and setting the system's time does not move
/// it. It has no meaning outside this process: it counts from an
/// unspecified start, so it cannot be printed, saved, or compared with a
/// `Timestamp`. The clock is the one the runtime keeps sleeping tasks on.
///
///     let start = time.Instant.Now()
///     work()
///     print("took \(start.Elapsed())")
public struct Instant: Hashable, Comparable {
    let nanos: int64

    init(nanos: int64) {
        self.nanos = nanos
    }

    /// Now, on the monotonic clock.
    public static func Now() -> Instant {
        return Instant(nanos: monotonicClock())
    }

    /// How long ago this was.
    public func Elapsed() -> Duration {
        return Instant.Now() - self
    }

    public static func + (i: Instant, d: Duration) -> Instant { return Instant(nanos: i.nanos + d.nanos) }
    public static func - (i: Instant, d: Duration) -> Instant { return Instant(nanos: i.nanos - d.nanos) }
    public static func - (a: Instant, b: Instant) -> Duration { return Duration(nanos: a.nanos - b.nanos) }
    public static func < (a: Instant, b: Instant) -> bool { return a.nanos < b.nanos }
}
