# time

[![package: vs-package](https://img.shields.io/badge/package-vs--package-f4f4f5?style=flat-square&labelColor=e4e4e7&color=18181b)](https://github.com/vertex-language)
[![time: duration | timestamp | instant](https://img.shields.io/badge/time-duration%20%7C%20timestamp%20%7C%20instant-f4f4f5?style=flat-square&labelColor=e4e4e7&color=18181b)](https://github.com/vertex-language/time)
[![runtime: async](https://img.shields.io/badge/runtime-async-f4f4f5?style=flat-square&labelColor=e4e4e7&color=18181b)](https://github.com/vertex-language)

Time library providing durations, wall and monotonic clocks, and blocking and asynchronous timers.

---

## Packages

- **`time`**: Durations, timestamps, instants and sleeping (`time.Duration`, `time.Timestamp`, `time.Instant`, `time.Sleep`, `time.TimeError`).

---

## Quick Start

Run any entry point with:

```bash
vsc run main.vs
```

```swift
package main

import "time"

func main() async -> int32 {
    let start = time.Instant.Now()
    print("it is \(time.Timestamp.Now())")      // 2026-09-16T23:55:28.127491Z

    do {
        try await time.Sleep(.Milliseconds(250))
        let timeout = try time.Duration.Parse("1m30s")
        print("slept \(start.Elapsed()), timeout \(timeout)")   // slept 260.13375ms, timeout 1m30s
    } catch let e as time.TimeError {
        print(e.Message)
        return 1
    } catch {
        return 1
    }
    return 0
}
```

---

## Types

| Type | What it is | Clock | Use it for |
|---|---|---|---|
| `Duration` | a signed length of time, to the nanosecond | none | timeouts, intervals, arithmetic |
| `Timestamp` | a moment on the wall clock | `CLOCK_REALTIME` | file times, logs, anything saved or shown |
| `Instant` | a moment on the monotonic clock | the runtime's | measuring, deadlines |

- **`Duration`**: `Nanoseconds`, `Microseconds`, `Milliseconds`, `Seconds`, `Minutes`, `Hours`, `Zero`, `Parse` and `Abs`, plus `+`, `-`, `* int64`, `/ int64` and comparison. Printed in Go's format (`1h2m3.5s`, `1.5ms`, `0s`), which `Parse` reads back.
- **`Timestamp`**: `Now`, `UnixEpoch`, `UnixMilliseconds`, `UTC(year, month, day, ...)`, `UnixSeconds` and `Nanoseconds`, plus `± Duration` and `Timestamp - Timestamp`. Printed as RFC 3339 in UTC.
- **`Instant`**: `Now` and `Elapsed`, plus `± Duration` and `Instant - Instant`. It has no description, because it means nothing outside the process.
- **`Sleep`**: `Sleep(_:)` and `Sleep(until:)`, each in two forms under one name. In an `async` function the async form suspends the task and needs `await`; anywhere else the blocking form blocks the thread.

All three types are `Hashable` and `Comparable`. The wall clock can jump, so there is no `Timestamp - Instant`: the compiler keeps the two clocks apart.

Calendars, time zones and timestamp formatting beyond `description` are not here on purpose.

---

## Layout

```
time          Vertex: Duration, Timestamp, Instant, Sleep, TimeError
  cclock/     C: the wall clock, the monotonic clock, a thread sleep
```

`cclock` is three functions, built from `package.vs` on Darwin (`clock_gettime`, `CLOCK_UPTIME_RAW`, `nanosleep`), Linux (`CLOCK_MONOTONIC`) and Windows (`GetSystemTimePreciseAsFileTime`, `QueryPerformanceCounter`, `Sleep`; written, not yet built).

---

## Running

Execute examples or the test suite directly with `vsc`:

```bash
# Run all checks: durations, dates worked out by hand, arithmetic and sleeps
vsc run check

# Time a few sleeps, blocking and asynchronous
vsc run stopwatch
```

`check` is 70 checks and exits with the number that failed. The expected values were verified against the same sources compiled with `swiftc`.

---

## License

[MIT](LICENSE)
