package odinysynth

import "core:fmt"
import "core:io"

@(private)
Soundfont_Parameters :: struct {
    sample_headers: [dynamic]Sample_Header
}

@(private)
new_soundfont_parameters :: proc(r: io.Reader) -> (Soundfont_Parameters, Error) {
    result: Soundfont_Parameters = {}
    err: Error = nil

    sample_headers: [dynamic]Sample_Header = nil

    defer {

        if err != nil {
            if sample_headers != nil {
                delete(sample_headers)
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
    if list_type != "pdta" {
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
        case "shdr":
            sample_headers, err = read_sample_headers_from_chunk(r, int(size))
        case:
            fmt.printf("%s\n", string(id[:]))
            discard_data(r, int(size))
        }
        if err != nil {
            return {}, err
        }

        pos += size
    }

    if sample_headers == nil {
        return {}, Odinysynth_Error.Invalid_Soundfont
    }

    result.sample_headers = sample_headers

    return result, nil
}
