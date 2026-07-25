package profiler

import "core:fmt"
import "core:sys/linux"
import "core:simd/x86"
import "../constants"


RepetitionTesterState :: enum {
    Unitialized,
    Running,
    Completed,
    Errored,
}

RepetitionResult :: struct {
    time: u64,
    maj_page_faults, min_page_faults: int,
}

RepetitionTester :: struct {
    min_result, max_result: RepetitionResult,

    last_record_tsc: u64,
    time_limit: u64,
    start_tsc: u64,

    new_record_occured: bool,

    begin_count, end_count: u64,

    start_maj_page_faults, start_min_page_faults: int,

    temp_bytes: u64,
    accumulative_bytes: u64,
    accumulative_time: u64,
    accumulative_maj_page_faults: int,
    accumulative_min_page_faults: int,

    state: RepetitionTesterState,
}

rep_test_create :: proc (time_limit: u64, label: string) -> RepetitionTester {
    fmt.printfln("------- RepetitionTesting -------- %s", label);

    return {
        min_result = { time = 0xFFFFFFFFFFFFFFFF },
        max_result = { time = 0 },

        last_record_tsc = 0,
        time_limit = time_limit * estimate_cpu_freq(),
        start_tsc = 0,

        new_record_occured = false,

        begin_count = 0,
        end_count = 0,

        start_maj_page_faults = 0,
        start_min_page_faults = 0,

        temp_bytes = 0,
        accumulative_bytes = 0,
        accumulative_time = 0,
        accumulative_maj_page_faults = 0,
        accumulative_min_page_faults = 0,

        state = .Unitialized
    }
}

rep_test_begin :: proc(rep_tester: ^RepetitionTester) {
    rep_tester.begin_count += 1;

    metrics := get_program_metrics()
    rep_tester.start_maj_page_faults = metrics.majflt_word
    rep_tester.start_min_page_faults = metrics.minflt_word

    rep_tester.start_tsc = x86._rdtsc()
}

rep_test_end :: proc(rep_tester: ^RepetitionTester) {
    end_time := x86._rdtsc()
    metrics := get_program_metrics()

    rep_tester.end_count += 1
    elapsed_time := end_time - rep_tester.start_tsc
    rep_tester.accumulative_time += elapsed_time

    maj_page_faults := metrics.majflt_word - rep_tester.start_maj_page_faults
    min_page_faults := metrics.minflt_word - rep_tester.start_min_page_faults

    if (rep_tester.max_result.time < elapsed_time) {
        rep_tester.max_result.time = elapsed_time
        rep_tester.max_result.maj_page_faults = maj_page_faults
        rep_tester.max_result.min_page_faults = min_page_faults
    }

    if (rep_tester.min_result.time > elapsed_time) {
        rep_tester.min_result.time = elapsed_time
        rep_tester.last_record_tsc = end_time
        rep_tester.min_result.maj_page_faults = maj_page_faults
        rep_tester.min_result.min_page_faults = min_page_faults
        print_new_record(rep_tester)
    }

    rep_tester.temp_bytes = 0
    rep_tester.accumulative_maj_page_faults += maj_page_faults
    rep_tester.accumulative_min_page_faults += min_page_faults
}

rep_test_add_bytes :: proc {
    rep_test_add_bytes_u64,
    rep_test_add_bytes_int,
}

rep_test_add_bytes_u64 :: proc(rep_tester: ^RepetitionTester,
    bytes_count: u64) {
    rep_tester.temp_bytes += bytes_count
    rep_tester.accumulative_bytes += bytes_count
}

rep_test_add_bytes_int :: proc(rep_tester: ^RepetitionTester,
    bytes_count: int) {
    assert(bytes_count >= 0)
    rep_tester.temp_bytes += u64(bytes_count)
    rep_tester.accumulative_bytes += u64(bytes_count)
}

rep_test_is_testing :: proc(rep_tester: ^RepetitionTester) -> bool {

    current_tsc := x86._rdtsc()
    #partial switch rep_tester.state {
        case .Running:
            if rep_tester.begin_count != rep_tester.end_count {
                rep_tester.state = .Errored
                fmt.eprintf(`The amount of beginnings and endings of timing 
                    do not match! %d != %d`, rep_tester.begin_count,
                    rep_tester.end_count)
                return false
            }

            elapsed := i64(current_tsc) - i64(rep_tester.last_record_tsc)
            if (elapsed > i64(rep_tester.time_limit)) {
                rep_tester.state = .Completed
                return false
            }

            return true
        case .Unitialized:
            rep_tester.state = .Running
            return true
        case: return false
    }

    return false
}

print_new_record :: proc(rep_tester: ^RepetitionTester) {

    cpu_freq := f64(estimate_cpu_freq())
    min_time := f64(rep_tester.min_result.time) / cpu_freq
    bytes := f64(rep_tester.temp_bytes) / constants.MegaByte

    fmt.printfln(`New Record! Record time: %.4f s (), %.4f MB/s
    Page faults:
        - Major %d (%.4f) flts/s
        - Minor %d (%.4f) flts/s`,
        min_time,
        bytes / min_time,
        rep_tester.min_result.maj_page_faults,
        f64(rep_tester.min_result.maj_page_faults) / min_time,
        rep_tester.min_result.min_page_faults,
        f64(rep_tester.min_result.min_page_faults) / min_time)
}

rep_test_print_results :: proc(rep_tester: ^RepetitionTester) {
    cpu_freq := f64(estimate_cpu_freq())

    min_time := f64(rep_tester.min_result.time) / cpu_freq
    max_time := f64(rep_tester.max_result.time) / cpu_freq
    avg_time := (f64(rep_tester.accumulative_time) /
        f64(rep_tester.end_count)) / cpu_freq

    bytes := f64(rep_tester.accumulative_bytes) / f64(rep_tester.end_count) /
        (constants.MegaByte)

    avg_maj_faults := u64(f64(rep_tester.accumulative_maj_page_faults) /
        f64(rep_tester.end_count))
    avg_min_faults := u64(f64(rep_tester.accumulative_min_page_faults) /
        f64(rep_tester.end_count))

    fmt.println("\n------------------ Final Results ------------------------")
    fmt.printfln(`Min time: %.4f, %.4f MB/s
    Min Page faults:
        - Major %d (%.4f) flts/s
        - Minor %d (%.4f) flts/s`,
        min_time,
        bytes / min_time,
        rep_tester.min_result.maj_page_faults,
        f64(rep_tester.min_result.maj_page_faults) / min_time,
        rep_tester.min_result.min_page_faults,
        f64(rep_tester.min_result.min_page_faults) / min_time, flush = false)

    fmt.printfln(`Max time: %.4f, %.4f MB/s
    Max Page faults:
        - Major %d (%.4f) flts/s
        - Minor %d (%.4f) flts/s`,
        max_time,
        bytes / max_time,
        rep_tester.max_result.maj_page_faults,
        f64(rep_tester.max_result.maj_page_faults) / max_time,
        rep_tester.max_result.min_page_faults,
        f64(rep_tester.max_result.min_page_faults) / max_time, flush = false)

    fmt.printfln(`Avg time: %.4f, %.4f MB/s
        Avg Page faults:
        - Major %d (%.4f) flts/s
        - Minor %d (%.4f) flts/s`,
        avg_time,
        bytes / avg_time,
        avg_maj_faults,
        f64(avg_maj_faults) / avg_time,
        avg_min_faults,
        f64(avg_min_faults) / avg_time, flush = true)
}


@private
get_program_metrics :: proc() -> linux.RUsage {
    resource_info: linux.RUsage = {
        utime = linux.Time_Val{ seconds = 0, microseconds = 0 },
        stime = linux.Time_Val{ seconds = 0, microseconds = 0 },
        maxrss_word = 0,
        ixrss_word = 0,
        idrss_word = 0,
        majflt_word = 0,
        minflt_word = 0,
        oublock_word = 0,
        inblock_word = 0,
        nswap_word = 0,
        nsignals_word = 0,
        nvcsw_word = 0,
        msgsnd_word = 0,
        msgrcv_word = 0,
        nivcsw_word = 0,
        isrss_word = 0
    }

    err := linux.getrusage(linux.RUsage_Who.SELF, &resource_info)
    if err != linux.Errno.NONE {
        fmt.eprintf("Failed to obtain RUsage! {}", err)
    }

    return resource_info
}
