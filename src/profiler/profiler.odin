package profiler

import "core:slice"
import "core:simd/x86"
import "core:fmt"
import "core:strings"

ProfileAnchor :: struct {
    tsc_elapsed_root: u64,
    tsc_elapsed: u64,
    tsc_children: u64,
    bytes: u64,
    label: string,
}


Profiler :: struct {
    has_profiling_started: bool,
    tsc_start: u64,
    anchors: [1024]ProfileAnchor,
    anchors_count: u32
}

ProfileBlock :: struct {
    tsc_start: u64,
    tsc_old_elapsed_root: u64,
    anchor_id: u32,
    parent_id: u32,
    bytes: u64,
    label: string,
}

@(private)
g_parent_id: u32 = 0
@(private)
profiler := Profiler{
    has_profiling_started = false,
    tsc_start = 0,
    anchors = {},
    anchors_count = 0,
}

IS_PROFILING :: true

begin_profiling :: proc() {
    profiler.has_profiling_started = true
    profiler.tsc_start = x86._rdtsc()
}

/*
Starts up a profile block.
@param - Arbitrary label
@param - Anchor ID. THIS ONE IS SPECIFICALLY IMPORTANT. YOU CANNOT PASS JUST A REGULAR POINTER TO A NUMBER
Please use a static local variable to initialize a number before calling this function and pass the number's pointer
into the Anchor ID param!

for ex.
`@static idx: u32 = 0`
`file_read := profiler.begin_block("File Read", &idx);`
*/
begin_block :: proc(label: string, idx: ^u32) -> ProfileBlock {

    when IS_PROFILING {
        if (idx^ == 0) {
            profiler.anchors_count += 1;
            idx^ = profiler.anchors_count;
        }

        block := ProfileBlock{
            label = label,
            anchor_id = idx^,
            parent_id = g_parent_id,
            tsc_old_elapsed_root = profiler.anchors[idx^].tsc_elapsed_root
        };

        g_parent_id = idx^;

        block.tsc_start = x86._rdtsc();
        return block;
    }

}

end_block :: #force_inline proc(block: ^ProfileBlock) {
    end_block_with_bytes(block, 0)
}

end_block_with_bytes :: proc(block: ^ProfileBlock, bytes: u64) {
    when IS_PROFILING {
        tsc_end := x86._rdtsc();
        elapsed := tsc_end - block.tsc_start;

        g_parent_id = block.parent_id;

        anchor := &profiler.anchors[block.anchor_id];
        
        anchor.bytes = bytes;
        anchor.tsc_elapsed += elapsed;
        anchor.tsc_elapsed_root = block.tsc_old_elapsed_root + elapsed;
        anchor.label = block.label;
        profiler.anchors[g_parent_id].tsc_children += elapsed;
    }
}

end_profiling :: proc() {
    total_end := x86._rdtsc()
    total_tsc_elapsed: u64 = total_end - profiler.tsc_start

    assert(profiler.has_profiling_started, "You haven't started profiling!")

    cpu_freq := estimate_cpu_freq()
    total_cpu_ms := 1000 * f64(total_tsc_elapsed) / f64(cpu_freq)

    fmt.printfln("\nTotal Time - CPU: %.5f ms", total_cpu_ms)

    when IS_PROFILING {
        unprofiled_cpu_ms: f64 = total_cpu_ms
        unprofiled_tsc_elapsed: u64 = total_tsc_elapsed
        unprofiled_portion: f64 = 1.0

        max_count := profiler.anchors_count

        // This is to account also the last anchor which was measured
        // If some kind of block exists, then the real starting anchor is at
        // profiler.anchors[1]. The root is at anchors[0] which is an
        // unprofiled section.
        if profiler.anchors_count + 1 < len(profiler.anchors) {
            max_count = profiler.anchors_count + 1
        }

        for i in 0..<max_count {
            if (profiler.anchors[i].tsc_elapsed > 0) {

                anchor := &profiler.anchors[i]
                anchor_tsc_elapsed := anchor.tsc_elapsed - anchor.tsc_children

                anchor_cpu_ms: f64 = 1000 * f64(anchor_tsc_elapsed) /
                    f64(cpu_freq)
                anchor_portion: f64 = f64(anchor_tsc_elapsed) /
                    f64(total_tsc_elapsed)

                fmt.printf("\t%s | %.5f ms (%d cycles), %.5f MB/s (%.4f %%", 
                    anchor.label,
                    anchor_cpu_ms,
                    anchor_tsc_elapsed,
                    f64(anchor.bytes) / anchor_cpu_ms / 1000.0,
                    100.0 * anchor_portion
                );

                if (anchor.tsc_elapsed_root != anchor_tsc_elapsed) {
                    fmt.printf(", %.4f %% w/children", 100.0 *
                        f64(anchor.tsc_elapsed_root) / f64(total_tsc_elapsed));
                }

                fmt.print(")\n");

                unprofiled_cpu_ms -= anchor_cpu_ms;
                unprofiled_tsc_elapsed -= anchor_tsc_elapsed;
                unprofiled_portion -= anchor_portion;
            }

        }
        fmt.println("\t---------------------");
        fmt.printfln("\n\tUnprofiled | Elapsed %.5f ms (%d cycles) (%.4f %%)\n",
            unprofiled_cpu_ms, unprofiled_tsc_elapsed, unprofiled_portion * 100.0);
    }

}


