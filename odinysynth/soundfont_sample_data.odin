package odinysynth

import "core:io"
import "core:mem"

@(private)
Soundfont_Sample_Data :: struct {
    bits_per_sample: i32
    samples: []i16
}

@(private)
new_soundfont_sample_data :: proc(r: io.Reader) -> (Soundfont_Sample_Data, Error) {
    samples: []i16 = nil
    bits_per_sample: i32 = 0
    err: Error = nil

    defer {
        if err != nil {
            if samples != nil {
                delete(samples)
            }
        }
    }

    chunk_id: [4]u8
    chunk_id, err = read_four_cc(r)
    if err != nil {
        return {}, err
    }
    if chunk_id != "LIST" {
        err = Odinysynth_Error.Invalid_Soundfont
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
        err = Odinysynth_Error.Invalid_Soundfont
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
            bits_per_sample = 16
            samples, err = make([]i16, size / 2)
            if err != nil {
                return {}, err
            }
            n: int
            n, err = io.read_full(r, mem.slice_data_cast([]u8, samples[:]))
            if err != nil {
                return {}, err
            }
        case "sm24":
            // 24 bit audio is not supported.
            err = discard_data(r, int(size))
            if err != nil {
                return {}, err
            }
        case:
            err = Odinysynth_Error.Invalid_Soundfont
            if err != nil {
                return {}, err
            }
        }

        pos += size
    }

    if samples == nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, err
    }

    result: Soundfont_Sample_Data = {}
    result.bits_per_sample = bits_per_sample
    result.samples = samples
    return result, nil
}
