package main

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:testing"
import "odinysynth"

main :: proc() {
    using odinysynth

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    file, err1 := os.open("GeneralUser GS MuseScore v1.442.sf2", os.O_RDONLY)
    if err1 != os.ERROR_NONE {
        panic("OOPS!")
    }
    defer os.close(file)

    reader := io.Reader { stream = os.stream_from_handle(file) }

    soundfont, err2 := new_soundfont(reader)

    settings := new_synthesizer_settings(44100)
    synthesizer, err3 := new_synthesizer(&soundfont, &settings)
    for ch := 0; ch < 16; ch += 1 {
        fmt.println(synthesizer.channels[ch].is_percussion_channel)
    }
    destroy(&synthesizer)

    fmt.println(get_attack_volume_envelope(&soundfont.instruments[0].regions[0]))
    fmt.println("OK!")

    destroy(&soundfont)

    for _, leak in track.allocation_map {
    fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
    }
    for bad_free in track.bad_free_array {
        fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
    }
}
