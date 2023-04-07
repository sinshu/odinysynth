package main

import "core:fmt"
import "core:io"
import "core:os"
import "odinysynth"

main :: proc() {
	file, err := os.open("TimGM6mb.sf2", os.O_RDONLY)
    if err != os.ERROR_NONE {
        panic("OOPS!")
    }
    defer os.close(file)

	reader := io.Reader { stream = os.stream_from_handle(file) }

    buffer, err2 := odinysynth.read_four_cc(reader)

    str := string(buffer[:])
    fmt.println(str)
}
