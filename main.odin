package main

import "core:fmt"
import "core:io"
import "core:os"
import "odinysynth"

main :: proc() {
	file, err1 := os.open("TimGM6mb.sf2", os.O_RDONLY)
    if err1 != os.ERROR_NONE {
        panic("OOPS!")
    }
    defer os.close(file)

	reader := io.Reader { stream = os.stream_from_handle(file) }

    sound_font, err2 := odinysynth.new_sound_font(reader)
}
