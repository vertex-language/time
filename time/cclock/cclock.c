// cclock: see include/cclock.h.
#include "cclock.h"

#ifdef _WIN32

#include <windows.h>

// FILETIME counts 100 ns ticks from 1601-01-01; the Unix epoch is this
// many ticks later.
#define EPOCH_TICKS 116444736000000000LL

int64_t cclock_wall(int32_t* nanos) {
    FILETIME ft;
    GetSystemTimePreciseAsFileTime(&ft);
    int64_t ticks = ((int64_t)ft.dwHighDateTime << 32 | ft.dwLowDateTime) - EPOCH_TICKS;
    int64_t secs = ticks / 10000000;
    int64_t rem = ticks % 10000000;
    if (rem < 0) {
        rem += 10000000;
        secs -= 1;
    }
    *nanos = (int32_t)(rem * 100);
    return secs;
}

int64_t cclock_monotonic(void) {
    LARGE_INTEGER count, frequency;
    QueryPerformanceCounter(&count);
    QueryPerformanceFrequency(&frequency);
    int64_t c = count.QuadPart, f = frequency.QuadPart;
    return c / f * 1000000000LL + c % f * 1000000000LL / f;
}

void cclock_sleep(int64_t nanoseconds) {
    if (nanoseconds <= 0) {
        return;
    }
    // Sleep takes milliseconds: round up, so it is never short.
    int64_t ms = (nanoseconds + 999999) / 1000000;
    while (ms > 0) {
        DWORD step = ms > 0x7fffffff ? 0x7fffffff : (DWORD)ms;
        Sleep(step);
        ms -= step;
    }
}

#else

#include <errno.h>
#include <time.h>

int64_t cclock_wall(int32_t* nanos) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    *nanos = (int32_t)ts.tv_nsec;
    return (int64_t)ts.tv_sec;
}

int64_t cclock_monotonic(void) {
#ifdef __APPLE__
    return (int64_t)clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + ts.tv_nsec;
#endif
}

void cclock_sleep(int64_t nanoseconds) {
    if (nanoseconds <= 0) {
        return;
    }
    struct timespec request, remaining;
    request.tv_sec = (time_t)(nanoseconds / 1000000000LL);
    request.tv_nsec = (long)(nanoseconds % 1000000000LL);
    while (nanosleep(&request, &remaining) != 0 && errno == EINTR) {
        request = remaining;
    }
}

#endif
