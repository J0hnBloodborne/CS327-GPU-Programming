#pragma once
#include <cstdio>
#include <chrono>
#include <utility>

using Clock = std::chrono::steady_clock;

template <typename Func, typename... Args>
double time_function(Func&& func, Args&&... args) {
    auto t0 = Clock::now();
    std::forward<Func>(func)(std::forward<Args>(args)...);
    auto t1 = Clock::now();
    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    printf("Time: %.3f ms\n", ms);
    return ms;
}