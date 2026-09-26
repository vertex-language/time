package time

/// A moment on the wall clock: what a file's modification time is, and
/// what a log line or a certificate's expiry is stamped with.
///
/// It is whole seconds since 1970-01-01T00:00:00Z plus the nanoseconds
/// past them, always 0 to 999999999, so a moment before 1970 is a negative
/// second and a positive fraction. There are no time zones and no leap
/// seconds here: it prints as UTC, in RFC 3339.
///
/// The wall clock can be set, and then it jumps. To time something or keep
/// a deadline, use `Instant`, which never does.
///
///     let now = time.Timestamp.Now()
///     print(now)                               // 2026-09-16T23:04:05.123456789Z
///     print(now - modified > .Hours(24))
public struct Timestamp: Hashable, Comparable, CustomStringConvertible {
    /// Whole seconds since the Unix epoch.
    public let UnixSeconds: int64
    /// Nanoseconds past `UnixSeconds`, from 0 to 999999999.
    public let Nanoseconds: int32

    /// The moment `unixSeconds` seconds and `nanoseconds` nanoseconds after
    /// the Unix epoch. Nanoseconds outside a second carry into the seconds,
    /// and may be negative.
    public init(unixSeconds: int64, nanoseconds: int64 = 0) {
        UnixSeconds = unixSeconds + floorDiv(nanoseconds, nanosPerSecond)
        Nanoseconds = int32(floorMod(nanoseconds, nanosPerSecond))
    }

    /// 1970-01-01T00:00:00Z.
    public static let UnixEpoch = Timestamp(unixSeconds: 0)

    /// Now, on the wall clock.
    public static func Now() -> Timestamp {
        var nanos: int32 = 0
        let secs = wallClock(&nanos)
        return Timestamp(unixSeconds: secs, nanoseconds: int64(nanos))
    }

    /// The moment a count of milliseconds since the Unix epoch names, as
    /// JavaScript and Java keep time.
    public static func UnixMilliseconds(_ ms: int64) -> Timestamp {
        return Timestamp(unixSeconds: floorDiv(ms, 1000),
                         nanoseconds: floorMod(ms, 1000) * nanosPerMillisecond)
    }

    /// A moment in UTC by its calendar date and clock time, in the
    /// proleptic Gregorian calendar. Fields out of range carry, so
    /// month 13 is January of the next year.
    public static func UTC(_ year: int64, _ month: int64, _ day: int64,
                           _ hour: int64 = 0, _ minute: int64 = 0, _ second: int64 = 0,
                           nanosecond: int64 = 0) -> Timestamp {
        let y = year + floorDiv(month - 1, 12)
        let m = floorMod(month - 1, 12) + 1
        let days = daysFromCivil(y, m, 1) + day - 1
        return Timestamp(unixSeconds: days * 86400 + hour * 3600 + minute * 60 + second,
                         nanoseconds: nanosecond)
    }

    /// Milliseconds since the Unix epoch, rounded toward negative infinity.
    public func AsUnixMilliseconds() -> int64 {
        return UnixSeconds * 1000 + int64(Nanoseconds) / nanosPerMillisecond
    }

    public static func + (t: Timestamp, d: Duration) -> Timestamp {
        return Timestamp(unixSeconds: t.UnixSeconds + d.nanos / nanosPerSecond,
                         nanoseconds: int64(t.Nanoseconds) + d.nanos % nanosPerSecond)
    }

    public static func - (t: Timestamp, d: Duration) -> Timestamp {
        return Timestamp(unixSeconds: t.UnixSeconds - d.nanos / nanosPerSecond,
                         nanoseconds: int64(t.Nanoseconds) - d.nanos % nanosPerSecond)
    }

    /// How far apart two moments are. It traps where that is more than a
    /// `Duration` holds, about 292 years.
    public static func - (a: Timestamp, b: Timestamp) -> Duration {
        return Duration(nanos: (a.UnixSeconds - b.UnixSeconds) * nanosPerSecond
                            + int64(a.Nanoseconds) - int64(b.Nanoseconds))
    }

    public static func < (a: Timestamp, b: Timestamp) -> bool {
        if a.UnixSeconds != b.UnixSeconds {
            return a.UnixSeconds < b.UnixSeconds
        }
        return a.Nanoseconds < b.Nanoseconds
    }

    /// RFC 3339 in UTC: "2026-09-16T23:04:05Z", with the fraction of a
    /// second where there is one, its trailing zeros left off.
    public var description: string {
        let days = floorDiv(UnixSeconds, 86400)
        let secs = floorMod(UnixSeconds, 86400)
        let (y, m, d) = civilFromDays(days)
        var text = y < 0 ? "-" + padded(-y, 4) : padded(y, 4)
        text += "-" + padded(m, 2) + "-" + padded(d, 2)
        text += "T" + padded(secs / 3600, 2) + ":" + padded(secs / 60 % 60, 2) + ":" + padded(secs % 60, 2)
        text += fraction(uint64(Nanoseconds), digits: 9)
        return text + "Z"
    }
}

// daysFromCivil and civilFromDays convert between a proleptic Gregorian
// date and days since 1970-01-01, for any date an int64 holds. They are
// Howard Hinnant's algorithms: a year is counted from March, so the leap
// day falls at its end, and years group into 400-year eras of 146097 days.
func daysFromCivil(_ year: int64, _ month: int64, _ day: int64) -> int64 {
    let y = month <= 2 ? year - 1 : year
    let era = floorDiv(y, 400)
    let yoe = y - era * 400
    let doy = (153 * (month > 2 ? month - 3 : month + 9) + 2) / 5 + day - 1
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
    return era * 146097 + doe - 719468
}

func civilFromDays(_ days: int64) -> (int64, int64, int64) {
    let z = days + 719468
    let era = floorDiv(z, 146097)
    let doe = z - era * 146097
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
    let mp = (5 * doy + 2) / 153
    let day = doy - (153 * mp + 2) / 5 + 1
    let month = mp < 10 ? mp + 3 : mp - 9
    let year = yoe + era * 400 + (month <= 2 ? 1 : 0)
    return (year, month, day)
}
