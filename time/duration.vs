package time

/// A length of time, signed, to the nanosecond.
///
/// It is held as a count of nanoseconds in an int64, as Go's is, which
/// spans about 292 years either way. Arithmetic past that traps, as int64
/// arithmetic does.
///
///     let timeout = time.Duration.Seconds(5)
///     let backoff = time.Duration.Milliseconds(250) * 4
///     print(timeout + backoff)             // 6s
public struct Duration: Hashable, Comparable, CustomStringConvertible {
    let nanos: int64

    init(nanos: int64) {
        self.nanos = nanos
    }

    /// No time at all.
    public static let Zero = Duration(nanos: 0)

    public static func Nanoseconds(_ n: int64) -> Duration { return Duration(nanos: n) }
    public static func Microseconds(_ n: int64) -> Duration { return Duration(nanos: n * nanosPerMicrosecond) }
    public static func Milliseconds(_ n: int64) -> Duration { return Duration(nanos: n * nanosPerMillisecond) }
    public static func Seconds(_ n: int64) -> Duration { return Duration(nanos: n * nanosPerSecond) }
    public static func Minutes(_ n: int64) -> Duration { return Duration(nanos: n * nanosPerMinute) }
    public static func Hours(_ n: int64) -> Duration { return Duration(nanos: n * nanosPerHour) }

    /// The whole length in nanoseconds.
    public func AsNanoseconds() -> int64 { return nanos }
    /// The length in whole microseconds, truncated toward zero.
    public func AsMicroseconds() -> int64 { return nanos / nanosPerMicrosecond }
    /// The length in whole milliseconds, truncated toward zero.
    public func AsMilliseconds() -> int64 { return nanos / nanosPerMillisecond }
    /// The length in seconds, with the fraction.
    public func AsSeconds() -> double {
        let whole = nanos / nanosPerSecond
        let part = nanos % nanosPerSecond
        return double(whole) + double(part) / 1e9
    }

    /// The same length, made positive.
    public func Abs() -> Duration { return nanos < 0 ? Duration(nanos: -nanos) : self }

    public static func + (a: Duration, b: Duration) -> Duration { return Duration(nanos: a.nanos + b.nanos) }
    public static func - (a: Duration, b: Duration) -> Duration { return Duration(nanos: a.nanos - b.nanos) }
    public static prefix func - (d: Duration) -> Duration { return Duration(nanos: -d.nanos) }
    public static func * (d: Duration, n: int64) -> Duration { return Duration(nanos: d.nanos * n) }
    public static func * (n: int64, d: Duration) -> Duration { return Duration(nanos: n * d.nanos) }
    public static func / (d: Duration, n: int64) -> Duration { return Duration(nanos: d.nanos / n) }
    public static func < (a: Duration, b: Duration) -> bool { return a.nanos < b.nanos }

    /// The length the way Go writes one: "1h2m3.5s", "1.5ms", "300ns",
    /// "0s". `Parse` reads it back.
    public var description: string {
        if nanos == 0 {
            return "0s"
        }
        // The magnitude as a uint64, which holds even int64's minimum.
        let u = nanos < 0 ? 0 &- uint64(bitPattern: nanos) : uint64(nanos)
        var text = ""
        if u < 1_000 {
            text = "\(u)ns"
        } else if u < 1_000_000 {
            text = "\(u / 1_000)" + fraction(u % 1_000, digits: 3) + "µs"
        } else if u < 1_000_000_000 {
            text = "\(u / 1_000_000)" + fraction(u % 1_000_000, digits: 6) + "ms"
        } else {
            let secs = u / 1_000_000_000
            let seconds = "\(secs % 60)" + fraction(u % 1_000_000_000, digits: 9) + "s"
            if secs >= 3600 {
                text = "\(secs / 3600)h\(secs / 60 % 60)m" + seconds
            } else if secs >= 60 {
                text = "\(secs / 60)m" + seconds
            } else {
                text = seconds
            }
        }
        return nanos < 0 ? "-" + text : text
    }

    /// Reads a duration written as Go writes one: an optional sign, then
    /// numbers each with a unit, such as "300ms", "-1.5h" or "2h45m".
    /// The units are ns, us (or µs), ms, s, m and h. A bare "0" is zero.
    public static func Parse(_ text: string) throws -> Duration {
        var bytes: [uint8] = []
        for b in text.utf8 {
            bytes.append(b)
        }
        var i = 0
        var negative = false
        if i < bytes.count && (bytes[i] == 45 || bytes[i] == 43) {   // '-', '+'
            negative = bytes[i] == 45
            i += 1
        }
        if i == bytes.count - 1 && bytes[i] == 48 {   // "0"
            return Zero
        }
        if i == bytes.count {
            throw TimeError.invalidDuration(text)
        }
        // The largest magnitude: int64's maximum, or one more for a
        // negative duration, which is int64's minimum.
        let limit: uint64 = negative ? 1 << 63 : (1 << 63) - 1
        var total: uint64 = 0
        while i < bytes.count {
            // The whole part.
            let start = i
            var whole: uint64 = 0
            var overflow = false
            while i < bytes.count && bytes[i] >= 48 && bytes[i] <= 57 {
                let digit = uint64(bytes[i] - 48)
                if whole > (limit - digit) / 10 {
                    overflow = true
                }
                whole = whole &* 10 &+ digit
                i += 1
            }
            let hadWhole = i > start
            // The fraction, as digits over a power of ten. Digits past
            // what a uint64 scale holds are below a nanosecond anyway.
            var part: uint64 = 0
            var scale: uint64 = 1
            var hadPart = false
            if i < bytes.count && bytes[i] == 46 {   // '.'
                i += 1
                let fracStart = i
                while i < bytes.count && bytes[i] >= 48 && bytes[i] <= 57 {
                    if scale < 1_000_000_000_000_000_000 {
                        part = part * 10 + uint64(bytes[i] - 48)
                        scale *= 10
                    }
                    i += 1
                }
                hadPart = i > fracStart
            }
            if overflow || !(hadWhole || hadPart) {
                throw TimeError.invalidDuration(text)
            }
            // The unit: every byte up to the next digit or '.'.
            let unitStart = i
            while i < bytes.count && bytes[i] != 46 && !(bytes[i] >= 48 && bytes[i] <= 57) {
                i += 1
            }
            guard let unit = unitNanos(bytes, from: unitStart, to: i) else {
                throw TimeError.invalidDuration(text)
            }
            if whole > limit / unit {
                throw TimeError.invalidDuration(text)
            }
            var v = whole * unit
            if part > 0 {
                // As Go does it: the fraction through a double.
                v += uint64(double(part) * (double(unit) / double(scale)))
            }
            if v > limit || total > limit - v {
                throw TimeError.invalidDuration(text)
            }
            total += v
        }
        if negative {
            return Duration(nanos: int64(bitPattern: 0 &- total))
        }
        return Duration(nanos: int64(total))
    }
}

// fraction is ".5" for 500 of 3 digits: the digits after a decimal point,
// with the zeros at the end left off, or nothing at all for 0.
func fraction(_ value: uint64, digits: int) -> string {
    if value == 0 {
        return ""
    }
    // The zeros at the end are dropped from the number before it is
    // written, rather than from the text after.
    var v = value
    var width = digits
    while v % 10 == 0 {
        v /= 10
        width -= 1
    }
    return "." + padded(int64(v), width)
}

// unitNanos is how many nanoseconds the unit written in bytes[from..<to]
// stands for, or nil where it is not one.
func unitNanos(_ bytes: [uint8], from: int, to: int) -> uint64? {
    var unit: [uint8] = []
    var i = from
    while i < to {
        unit.append(bytes[i])
        i += 1
    }
    // 'n','s' / 'u','s' / 0xC2 0xB5 's' (µ, micro sign) / 0xCE 0xBC 's'
    // (μ, Greek mu) / 'm','s' / 's' / 'm' / 'h'
    if unit == [110, 115] { return 1 }
    if unit == [117, 115] || unit == [0xC2, 0xB5, 115] || unit == [0xCE, 0xBC, 115] { return 1_000 }
    if unit == [109, 115] { return 1_000_000 }
    if unit == [115] { return 1_000_000_000 }
    if unit == [109] { return 60_000_000_000 }
    if unit == [104] { return 3_600_000_000_000 }
    return nil
}
