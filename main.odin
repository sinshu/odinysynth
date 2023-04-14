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

    file, err1 := os.open("TimGM6mb.sf2", os.O_RDONLY)
    if err1 != os.ERROR_NONE {
        panic("OOPS!")
    }
    defer os.close(file)

    reader := io.Reader { stream = os.stream_from_handle(file) }

    soundfont, err2 := new_soundfont(reader)


    settings := new_synthesizer_settings(44100)
    synthesizer, err3 := new_synthesizer(&soundfont, &settings)
    note_on(&synthesizer, 0, 60, 100)
    note_on(&synthesizer, 0, 64, 100)
    note_on(&synthesizer, 0, 67, 100)

    left := make([]f32, 3 * settings.sample_rate)
    right := make([]f32, 3 * settings.sample_rate)
    synthesizer_render(&synthesizer, left, right)

    max_value: f32 = 0
    for i := 0; i < len(left); i += 1 {
        if abs(left[i]) > max_value {
            max_value = abs(left[i])
        }
        if abs(right[i]) > max_value {
            max_value = abs(right[i])
        }
    }
    a := 0.99 / max_value

    pcm, _ := os.open("out.pcm", os.O_CREATE)
    for i := 0; i < len(left); i += 1 {
        left_i16 := i16(32768.0 * a * left[i])
        right_i16 := i16(32768.0 * a * right[i])
        buf: [4]u8
        buf[0] = u8(left_i16)
        buf[1] = u8(left_i16 >> 8)
        buf[2] = u8(right_i16)
        buf[3] = u8(right_i16 >> 8)
        os.write(pcm, buf[:])
    }
    defer os.close(pcm)

    delete(left)
    delete(right)
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
