// The clocks on Darwin, Linux and Android: see clock.cpp.
module;
#include <errno.h>
#include <stdint.h>
#include <time.h>
module time;

int64_t wallClock(int32_t* nanos) noexcept {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    *nanos = (int32_t)ts.tv_nsec;
    return (int64_t)ts.tv_sec;
}

int64_t monotonicClock() noexcept {
#ifdef __APPLE__
    return (int64_t)clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
#else
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + ts.tv_nsec;
#endif
}

void sleepThread(int64_t nanoseconds) noexcept {
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
