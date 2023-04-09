package odinysynth

import "core:fmt"
import "core:io"

SoundFont :: struct {
    wave_data: [dynamic]i16
}

new_sound_font :: proc(r: io.Reader) -> (SoundFont, io.Error) {
    result := SoundFont {}
    err: io.Error = nil

    chunk_id: [4]u8
    chunk_id, err = read_four_cc(r)
    if err != nil {
        return result, err
    }
    if chunk_id != "RIFF" {
        return result, io.Error.Unknown
    }

    size: i32
    size, err = read_i32(r)
    if err != nil {
        return result, err
    }

    form_type: [4]u8
    form_type, err = read_four_cc(r)
    if err != nil {
        return result, err
    }
    if form_type != "sfbk" {
        return result, io.Error.Unknown
    }

    err = skip_sound_font_info(r)
    if err != nil {
        return result, err
    }

    sample_data: SoundFontSampleData
    sample_data, err = new_sound_font_sample_data(r)
    sum: int = 0
    for value in sample_data.samples {
        sum += int(value)
    }

    fmt.println(size)
    fmt.println(sum)

    return result, nil
}

skip_sound_font_info :: proc(r: io.Reader) -> io.Error {
    err: io.Error = nil

    chunk_id: [4]u8
    chunk_id, err = read_four_cc(r)
    if err != nil {
        return err
    }
    if chunk_id != "LIST" {
        return io.Error.Unknown
    }

    size: i32
    size, err = read_i32(r)
    if err != nil {
        return err
    }
    return discard_data(r, int(size))
}
