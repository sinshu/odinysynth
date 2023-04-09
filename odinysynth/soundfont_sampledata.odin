package odinysynth

import "core:io"
import "core:mem"

SoundFontSampleData :: struct {
    bits_per_sample: i32
    samples: [dynamic]i16
}

new_sound_font_sample_data :: proc(r: io.Reader) -> (SoundFontSampleData, Error) {
    result: SoundFontSampleData = {}
    n: int = 0
    err: Error = nil

    defer {
        if err != nil {
            if result.samples != nil {
                delete(result.samples)
            }
        }
    }

    chunk_id: [4]u8
    chunk_id, err = read_four_cc(r)
    if err != nil {
        return {}, err
    }
    if chunk_id != "LIST" {
        err = OdinySynth_Error.Invalid_SoundFont
        return {}, err
    }

    pos: i32 = 0

    end: i32
    end, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    list_type: [4]u8
    list_type, err = read_four_cc(r)
    if err != nil {
        return {}, err
    }
    if list_type != "sdta" {
        err = OdinySynth_Error.Invalid_SoundFont
        return {}, err
    }
    pos += 4

    for pos < end {
        id: [4]u8
        id, err = read_four_cc(r)
        if err != nil {
            return {}, err
        }
        pos += 4

        size: i32
        size, err = read_i32(r)
        if err != nil {
            return {}, err
        }
        pos += 4

        switch id {
        case "smpl":
            result.bits_per_sample = 16
            result.samples = make([dynamic]i16, size / 2)
            n, err = io.read_full(r, mem.slice_data_cast([]u8, result.samples[:]))
        case "sm24":
            // 24 bit audio is not supported.
            err = discard_data(r, int(size))
        case:
            err = OdinySynth_Error.Invalid_SoundFont
        }
        if err != nil {
            return {}, err
        }

        pos += size
    }

    if result.samples == nil {
        err = OdinySynth_Error.Invalid_SoundFont
        return {}, err
    }

    return result, nil
}
