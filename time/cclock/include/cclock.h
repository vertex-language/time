// cclock: the operating system's clocks, as a C ABI the time target calls.
//
// Three things only: the wall clock, a monotonic clock, and a sleep that
// stops the thread. Nothing here knows about tasks. A sleep that parks a
// task instead is the Vertex runtime's, and the time target calls that.
#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// cclock_wall is the wall clock: whole seconds since 1970-01-01T00:00:00Z,
// returned, and the nanoseconds past them, 0 to 999999999, written to
// nanos. It is the clock a file's modification time is on, and it can
// jump when the system's time is set.
int64_t cclock_wall(int32_t* nanos);

// cclock_monotonic is nanoseconds on a clock that never goes backwards,
// from an unspecified start. It is the clock the Vertex runtime keeps its
// sleeping tasks on:
//   Darwin:  CLOCK_UPTIME_RAW (stops while the machine sleeps)
//   Linux:   CLOCK_MONOTONIC
//   Windows: QueryPerformanceCounter
int64_t cclock_monotonic(void);

// cclock_sleep stops the calling thread for at least nanoseconds. A signal
// does not cut it short. Zero or less returns at once.
void cclock_sleep(int64_t nanoseconds);

#ifdef __cplusplus
}
#endif
