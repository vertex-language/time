package time

// Nanoseconds in each unit, as the int64 every count here is.
let nanosPerMicrosecond: int64 = 1_000
let nanosPerMillisecond: int64 = 1_000_000
let nanosPerSecond: int64 = 1_000_000_000
let nanosPerMinute: int64 = 60 * nanosPerSecond
let nanosPerHour: int64 = 60 * nanosPerMinute

// padded is n in decimal, with leading zeros to at least width digits.
func padded(_ n: int64, _ width: int) -> string {
    var text = "\(n)"
    while text.count < width {
        text = "0" + text
    }
    return text
}
