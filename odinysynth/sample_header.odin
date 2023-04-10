package odinysynth

import "core:io"

Sample_Header :: struct {
    name: [20]u8,
    start: i32,
    end: i32,
    start_loop: i32,
    end_loop: i32,
    sample_rate: i32,
    original_pitch: u8,
    pitch_correction: i8,
    link: u16,
    sample_type: u16,
}

@(private)
new_sample_header :: proc(r: io.Reader) -> (Sample_Header, Error) {
    result: Sample_Header = {}
    err: Error = nil

    err = read_fixed_length_string(r, result.name[:])
    if err != nil {
        return {}, err
    }

    result.start, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    result.end, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    result.start_loop, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    result.end_loop, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    result.sample_rate, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    result.original_pitch, err = read_u8(r)
    if err != nil {
        return {}, err
    }

    result.pitch_correction, err = read_i8(r)
    if err != nil {
        return {}, err
    }

    result.link, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    result.sample_type, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    return result, nil
}

@(private)
read_sample_headers_from_chunk :: proc(r: io.Reader, size: int) -> ([dynamic]Sample_Header, Error) {
    result: [dynamic]Sample_Header = nil
    err: Error = nil

    defer {
        if err != nil {
            if result != nil {
                delete(result)
            }
        }
    }

    if size % 46 != 0 {
        err = Odinysynth_Error.Invalid_Soundfont
        return nil, err
    }

    count := size / 46 - 1
    result = make([dynamic]Sample_Header, count)

    for i := 0; i < count; i += 1 {
        result[i], err = new_sample_header(r)
        if err != nil {
            return nil, err
        }
    }

    // The last one is the terminator.
    terminator: Sample_Header = {}
    terminator, err = new_sample_header(r)
    if err != nil {
        return nil, err
    }

    return result, nil
}
