package odinysynth

import "core:fmt"
import "core:io"

Soundfont :: struct {
    wave_data: [dynamic]i16
}

new_soundfont :: proc(r: io.Reader) -> (Soundfont, Error) {
    result: Soundfont = {}
    err: Error = nil

    chunk_id: [4]u8
    chunk_id, err = read_four_cc(r)
    if err != nil {
        return {}, err
    }
    if chunk_id != "RIFF" {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, err
    }

    size: i32
    size, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    form_type: [4]u8
    form_type, err = read_four_cc(r)
    if err != nil {
        return {}, err
    }
    if form_type != "sfbk" {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, err
    }

    err = skip_soundfont_info(r)
    if err != nil {
        return {}, err
    }

    sample_data: Soundfont_Sample_Data
    sample_data, err = new_soundfont_sample_data(r)
    sum: int = 0
    for value in sample_data.samples {
        sum += int(value)
    }

    fmt.println(size)
    fmt.println(sum)

    result.wave_data = sample_data.samples

    return result, nil
}

destroy_soundfont :: proc(soundfont: Soundfont) {
    delete(soundfont.wave_data)
}

@(private)
skip_soundfont_info :: proc(r: io.Reader) -> Error {
    err: Error = nil

    chunk_id: [4]u8
    chunk_id, err = read_four_cc(r)
    if err != nil {
        return err
    }
    if chunk_id != "LIST" {
        err = Odinysynth_Error.Invalid_Soundfont
        return err
    }

    size: i32
    size, err = read_i32(r)
    if err != nil {
        return err
    }
    return discard_data(r, int(size))
}
