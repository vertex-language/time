// The clocks on Windows: see clock.cpp.
module;
#include <stdint.h>
#include <windows.h>
module time;

// FILETIME counts 100 ns ticks from 1601-01-01; the Unix epoch is this
// many ticks later.
constexpr int64_t epochTicks = 116444736000000000LL;

int64_t wallClock(int32_t* nanos) noexcept {
    FILETIME ft;
    GetSystemTimePreciseAsFileTime(&ft);
    int64_t ticks = ((int64_t)ft.dwHighDateTime << 32 | ft.dwLowDateTime) - epochTicks;
    int64_t secs = ticks / 10000000;
    int64_t rem = ticks % 10000000;
    if (rem < 0) {
        rem += 10000000;
        secs -= 1;
    }
    *nanos = (int32_t)(rem * 100);
    return secs;
}

int64_t monotonicClock() noexcept {
    LARGE_INTEGER count, frequency;
    QueryPerformanceCounter(&count);
    QueryPerformanceFrequency(&frequency);
    int64_t c = count.QuadPart, f = frequency.QuadPart;
    return c / f * 1000000000LL + c % f * 1000000000LL / f;
}

void sleepThread(int64_t nanoseconds) noexcept {
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
