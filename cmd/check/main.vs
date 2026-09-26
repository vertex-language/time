// time checked against itself, and against dates worked out by hand.
//
// The program exits with the number of checks that did not pass, so 0 is
// the only good answer. Run it with
//
//     vsc run check
package main

import "time"

var failures = 0

func check(_ ok: bool, _ what: string) {
    if ok {
        print("ok    \(what)")
    } else {
        print("FAIL  \(what)")
        failures += 1
    }
}

func same(_ got: string, _ want: string, _ what: string) {
    check(got == want, got == want ? what : "\(what): got \(got), want \(want)")
}

func durations() {
    same(time.Duration.Zero.description, "0s", "zero prints as 0s")
    same(time.Duration.Nanoseconds(1).description, "1ns", "a nanosecond")
    same(time.Duration.Microseconds(1100).description, "1.1ms", "1100µs is 1.1ms")
    same(time.Duration.Nanoseconds(1500).description, "1.5µs", "1500ns is 1.5µs")
    same(time.Duration.Milliseconds(2500).description, "2.5s", "2500ms is 2.5s")
    same(time.Duration.Seconds(90).description, "1m30s", "90s is 1m30s")
    same(time.Duration.Hours(1).description, "1h0m0s", "an hour prints every unit below it")
    same((time.Duration.Hours(1) + .Minutes(2) + .Milliseconds(3500)).description, "1h2m3.5s", "hours, minutes and a fraction")
    same((-time.Duration.Milliseconds(1)).description, "-1ms", "negative")
    same(time.Duration.Nanoseconds(int64.min).description, "-2562047h47m16.854775808s", "int64's minimum")
    same(time.Duration.Nanoseconds(int64.max).description, "2562047h47m16.854775807s", "int64's maximum")

    check(time.Duration.Seconds(1) == .Milliseconds(1000), "units agree")
    check(time.Duration.Milliseconds(250) * 4 == .Seconds(1), "multiply")
    check(time.Duration.Seconds(1) / 4 == .Milliseconds(250), "divide")
    check(time.Duration.Milliseconds(999) < .Seconds(1), "compare")
    check(time.Duration.Milliseconds(-1500).AsMilliseconds() == -1500, "AsMilliseconds")
    check(time.Duration.Microseconds(-1999).AsMilliseconds() == -1, "AsMilliseconds truncates toward zero")
    check(time.Duration.Milliseconds(1500).AsSeconds() == 1.5, "AsSeconds keeps the fraction")
    check(time.Duration.Seconds(-3).Abs() == .Seconds(3), "Abs")
}

func parses(_ text: string, _ want: time.Duration) {
    do {
        let got = try time.Duration.Parse(text)
        check(got == want, got == want ? "parse \"\(text)\"" : "parse \"\(text)\": got \(got), want \(want)")
    } catch {
        check(false, "parse \"\(text)\" threw")
    }
}

func rejects(_ text: string) {
    do {
        let got = try time.Duration.Parse(text)
        check(false, "parse \"\(text)\" should fail, got \(got)")
    } catch time.TimeError.invalidDuration(_) {
        check(true, "rejects \"\(text)\"")
    } catch {
        check(false, "parse \"\(text)\" threw something else")
    }
}

func parsing() {
    parses("0", .Zero)
    parses("300ms", .Milliseconds(300))
    parses("-1.5h", -(time.Duration.Minutes(90)))
    parses("+2h45m", .Minutes(165))
    parses("1h2m3.5s", .Hours(1) + .Minutes(2) + .Milliseconds(3500))
    parses("1µs", .Microseconds(1))
    parses("1μs", .Microseconds(1))
    parses("1us", .Microseconds(1))
    parses(".5s", .Milliseconds(500))
    parses("1.s", .Seconds(1))
    parses("0.000000001s", .Nanoseconds(1))
    parses("9223372036854775807ns", .Nanoseconds(int64.max))
    parses("-9223372036854775808ns", .Nanoseconds(int64.min))
    for d in [time.Duration.Nanoseconds(123456789012), .Hours(-7), .Microseconds(42)] {
        parses(d.description, d)
    }
    rejects("")
    rejects("-")
    rejects("5")
    rejects("1d")
    rejects(".s")
    rejects("9223372036854775808ns")
    rejects("3000000h")
}

func timestamps() {
    same(time.Timestamp.UnixEpoch.description, "1970-01-01T00:00:00Z", "the epoch")
    same(time.Timestamp(unixSeconds: 1_000_000_000).description, "2001-09-09T01:46:40Z", "a billion seconds")
    same(time.Timestamp(unixSeconds: -1).description, "1969-12-31T23:59:59Z", "the second before the epoch")
    same(time.Timestamp(unixSeconds: 0, nanoseconds: -500_000_000).description, "1969-12-31T23:59:59.5Z", "half a second before it")
    same(time.Timestamp(unixSeconds: 951782400).description, "2000-02-29T00:00:00Z", "a leap day")
    same(time.Timestamp(unixSeconds: 4107542400).description, "2100-03-01T00:00:00Z", "2100 is not a leap year")
    same(time.Timestamp(unixSeconds: 1, nanoseconds: 120_000).description, "1970-01-01T00:00:01.00012Z", "a fraction with its zeros trimmed")

    let t = time.Timestamp(unixSeconds: 5, nanoseconds: -1)
    check(t.UnixSeconds == 4 && t.Nanoseconds == 999_999_999, "negative nanoseconds borrow a second")
    check(time.Timestamp.UTC(2026, 9, 16, 12, 30, 15) == time.Timestamp(unixSeconds: 1789561815), "UTC from a date")
    check(time.Timestamp.UTC(2025, 13, 1) == .UTC(2026, 1, 1), "month 13 carries into the next year")
    check(time.Timestamp.UTC(1, 1, 1).description == "0001-01-01T00:00:00Z", "year 1")
    check(time.Timestamp.UnixMilliseconds(-1).description == "1969-12-31T23:59:59.999Z", "milliseconds before the epoch")
    check(time.Timestamp.UnixMilliseconds(-1).AsUnixMilliseconds() == -1, "milliseconds round trip")

    let a = time.Timestamp(unixSeconds: 10, nanoseconds: 900_000_000)
    check(a + .Milliseconds(200) == time.Timestamp(unixSeconds: 11, nanoseconds: 100_000_000), "add carries")
    check(a - .Milliseconds(1000) == time.Timestamp(unixSeconds: 9, nanoseconds: 900_000_000), "subtract")
    check(a - (-time.Duration.Milliseconds(200)) == a + .Milliseconds(200), "subtract a negative")
    check((a + .Milliseconds(200)) - a == .Milliseconds(200), "difference")
    check(time.Timestamp(unixSeconds: -1, nanoseconds: 999_999_999) < .UnixEpoch, "compare across the epoch")

    var seen = Set<time.Timestamp>()
    seen.insert(a)
    seen.insert(time.Timestamp(unixSeconds: 11, nanoseconds: -100_000_000))
    check(seen.count == 1 && seen.contains(a + .Zero), "a Timestamp is Hashable: equal moments are one element")
    var byLength: [time.Duration: string] = [:]
    byLength[.Seconds(1)] = "one"
    byLength[.Milliseconds(1000)] = "same"
    check(byLength.count == 1 && byLength[.Seconds(1)] == "same", "a Duration is Hashable: equal lengths are one key")
    print([time.Duration.Milliseconds(1500), .Hours(2)])

    let now = time.Timestamp.Now()
    check(now > .UTC(2026, 1, 1) && now < .UTC(2100, 1, 1), "Now is a plausible date: \(now)")
}

func blocking() {
    let start = time.Instant.Now()
    time.Sleep(.Milliseconds(20))
    let took = start.Elapsed()
    check(took >= .Milliseconds(20), "a blocking sleep lasts at least as long: \(took)")
    let deadline = time.Instant.Now() + .Milliseconds(10)
    time.Sleep(until: deadline)
    check(time.Instant.Now() >= deadline, "a blocking sleep until a deadline reaches it")
}

func sleeping() async {
    let before = time.Instant.Now()
    check(time.Instant.Now() >= before, "the monotonic clock does not go backwards")

    // Blocking form, reached from synchronous code called by async code.
    blocking()

    // Three tasks each sleep 100ms. They overlap on one thread, so all
    // three are done in about 100ms; a blocking sleep would take 300.
    let start = time.Instant.Now()
    let a = Task { () async -> Void in try? await time.Sleep(.Milliseconds(100)) }
    let b = Task { () async -> Void in try? await time.Sleep(.Milliseconds(100)) }
    let c = Task { () async -> Void in try? await time.Sleep(.Milliseconds(100)) }
    await a.value
    await b.value
    await c.value
    let took = start.Elapsed()
    check(took >= .Milliseconds(100), "async sleeps last at least as long: \(took)")
    check(took < .Milliseconds(250), "async sleeps overlap rather than block: \(took)")

    do {
        let deadline = time.Instant.Now() + .Milliseconds(30)
        try await time.Sleep(until: deadline)
        check(time.Instant.Now() >= deadline, "an async sleep until a deadline reaches it")
        let t = time.Instant.Now()
        try await time.Sleep(.Milliseconds(-5))
        check(t.Elapsed() < .Milliseconds(5), "a negative sleep returns at once")
    } catch {
        check(false, "async sleep threw")
    }
}

func main() async -> int32 {
    durations()
    parsing()
    timestamps()
    await sleeping()
    print(failures == 0 ? "all passed" : "\(failures) failed")
    return int32(failures)
}
