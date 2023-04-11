package main

import "core:io"
import "core:os"
import "core:testing"
import "odinysynth"

@(test)
musescore_info_test :: proc(t: ^testing.T) {
    file, err1 := os.open("GeneralUser GS MuseScore v1.442.sf2", os.O_RDONLY)
    if err1 != os.ERROR_NONE {
        testing.fail(t)
    }
    defer os.close(file)

    reader := io.Reader { stream = os.stream_from_handle(file) }

    sf, err2 := odinysynth.new_soundfont(reader)
    if err2 != nil {
        testing.fail(t)
    }
    defer odinysynth.destroy_soundfont(&sf)

    if len(sf.wave_data) != 15513098 {
        testing.fail(t)
    }

    sum := 0
    for value in sf.wave_data {
        sum += int(value)
    }
    if sum != 101035585 {
        testing.fail(t)
    }
}
