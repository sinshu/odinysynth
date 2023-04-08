package odinysynth

import "core:fmt"
import "core:io"

SoundFont :: struct {
    wave_data: [dynamic]i16
}

new_sound_font :: proc(r: io.Reader) -> (SoundFont, io.Error) {
    chunk_id, err1 := read_four_cc(r)
    if err1 != nil {
        return SoundFont {}, err1
    }
    if chunk_id != "RIFF" {
        return SoundFont {}, io.Error.Unknown
    }

    size, err2 := read_i32(r)
    if err2 != nil {
        return SoundFont {}, io.Error.Unknown
    }

    form_type, err3 := read_four_cc(r)
    if err3 != nil {
        return SoundFont {}, io.Error.Unknown
    }
    if form_type != "sfbk" {
        return SoundFont {}, io.Error.Unknown
    }

    fmt.println(string(chunk_id[:]))
    fmt.println(size)
    fmt.println(string(form_type[:]))

    result := SoundFont {}

    return result, nil
}
