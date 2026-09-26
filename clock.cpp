// The operating system's clocks, for package time.
//
// Three things only: the wall clock, a monotonic clock, and a sleep that
// stops the thread. Nothing here knows about tasks. A sleep that parks a
// task instead is the Vertex runtime's, and the time package calls that.
module;
#include <stdint.h>
export module time;

// wallClock is the wall clock: whole seconds since 1970-01-01T00:00:00Z,
// returned, and the nanoseconds past them, 0 to 999999999, written to
// nanos. It is the clock a file's modification time is on, and it can
// jump when the system's time is set.
export int64_t wallClock(int32_t* nanos) noexcept;

// monotonicClock is nanoseconds on a clock that never goes backwards,
// from an unspecified start. It is the clock the Vertex runtime keeps its
// sleeping tasks on:
//   Darwin:  CLOCK_UPTIME_RAW (stops while the machine sleeps)
//   Linux:   CLOCK_MONOTONIC
//   Windows: QueryPerformanceCounter
export int64_t monotonicClock() noexcept;

// sleepThread stops the calling thread for at least nanoseconds. A signal
// does not cut it short. Zero or less returns at once.
export void sleepThread(int64_t nanoseconds) noexcept;
