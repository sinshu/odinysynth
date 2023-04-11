package main

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:testing"
import "odinysynth"

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    file, err1 := os.open("GeneralUser GS MuseScore v1.442.sf2", os.O_RDONLY)
    if err1 != os.ERROR_NONE {
        panic("OOPS!")
    }
    defer os.close(file)

    reader := io.Reader { stream = os.stream_from_handle(file) }

    soundfont, err2 := odinysynth.new_soundfont(reader)

    cnt := 0
    for inst in soundfont.instruments {
        fmt.printf("%s\n", inst.name)
        for reg in inst.regions {
            fmt.printf("    %s\n", reg.sample.name)
        }
        cnt += 1
        if cnt == 3 {
            break
        }
    }

    odinysynth.destroy_soundfont(&soundfont)

    for _, leak in track.allocation_map {
    fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
    }
    for bad_free in track.bad_free_array {
        fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
    }
}
