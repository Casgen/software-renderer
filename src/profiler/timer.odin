package profiler

import "core:simd/x86"
import "core:sys/posix"
import "core:fmt"
import "core:strings"

OS_TIMER_FREQ :: 1_000_000

Timer :: struct {
    os_start, os_end: u64,
    cpu_start, cpu_end: u64,
    label: string
}

TimerResult :: struct {
    os_elapsed, cpu_elapsed: u64,
    cpu_freq: u64,
    duration_ms: f32,
    label: string
}

timer_start :: proc(label: string) -> Timer {
    return Timer{
        os_start = read_os_timer(),
        cpu_start = x86._rdtsc(),
        label = strings.clone(label)
    }
}

timer_end :: proc(timer: ^Timer) -> TimerResult {

    os_elapsed := read_os_timer() - timer.os_start
    cpu_elapsed := x86._rdtsc() - timer.cpu_start

    result: TimerResult

    if os_elapsed == 0 {
        result = {
            os_elapsed = 0,
            cpu_elapsed = 0,
            cpu_freq = 0,
            label = timer.label,
            duration_ms = 0
        }
    } else {
        result = {
            os_elapsed = os_elapsed,
            cpu_elapsed = cpu_elapsed,
            cpu_freq = OS_TIMER_FREQ * cpu_elapsed / os_elapsed,
            label = timer.label,
            duration_ms = f32(result.os_elapsed) / f32(result.cpu_freq) * 1000.0
        }
    }
    return result
}

timer_fmt_result :: #force_inline proc(timer_result: ^TimerResult) -> string {
    return fmt.aprintf(
        "'%s'\n\tCpu Freq: %d | OS Elapsed: %.10f ms (%d ticks) | CPU Elapsed %d",
        timer_result.label, timer_result.cpu_freq, timer_result.duration_ms,
        timer_result.os_elapsed, timer_result.cpu_elapsed
    )
}

timer_destroy :: proc(timer: ^Timer) {
    delete(timer.label)
    timer.cpu_start = 0
    timer.os_end = 0
    timer.os_start = 0
    timer.label = ""
}

estimate_cpu_freq :: proc() -> u64 {
    elapsed, end: u64 = 0, 0

    wait_time : u64 : OS_TIMER_FREQ / 10

    cpu_start := x86._rdtsc()
    start := read_os_timer()

    for elapsed < wait_time {
        end = read_os_timer()
        elapsed = end - start
    }

    cpu_end := x86._rdtsc()
    cpu_elapsed := cpu_end - cpu_start

    if elapsed != 0 do return OS_TIMER_FREQ * cpu_elapsed / elapsed

    return 0
}

read_os_timer :: proc() -> u64 {
    timeval: posix.timeval
    posix.gettimeofday(&timeval, nil)

    return OS_TIMER_FREQ * u64(timeval.tv_sec) + u64(timeval.tv_usec)
}
