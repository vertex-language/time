package time

// Nanoseconds in each unit, as the int64 every count here is.
let nanosPerMicrosecond: int64 = 1_000
let nanosPerMillisecond: int64 = 1_000_000
let nanosPerSecond: int64 = 1_000_000_000
let nanosPerMinute: int64 = 60 * nanosPerSecond
let nanosPerHour: int64 = 60 * nanosPerMinute

// floorDiv and floorMod divide rounding toward negative infinity, so a
// time before 1970 still has its nanoseconds counted forwards from the
// second before it: -0.5s is second -1 plus 500000000 ns.
func floorDiv(_ a: int64, _ b: int64) -> int64 {
    let q = a / b
    return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q
}

func floorMod(_ a: int64, _ b: int64) -> int64 {
    let r = a % b
    return (r != 0 && (r < 0) != (b < 0)) ? r + b : r
}

// padded is n in decimal, with leading zeros to at least width digits.
func padded(_ n: int64, _ width: int) -> string {
    var text = "\(n)"
    while text.count < width {
        text = "0" + text
    }
    return text
}
