package odinysynth

import "core:io"

@(private)
Instrument_Info :: struct {
    name: [20]u8,
    zone_start_index: u16,
    zone_end_index: u16,
}

@(private)
new_instrument_info :: proc(r: io.Reader) -> (Instrument_Info, Error) {
    result: Instrument_Info = {}
    err: Error = nil

    err = read_fixed_length_string(r, result.name[:])
    if err != nil {
        return {}, err
    }

    result.zone_start_index, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    return result, nil
}

@(private)
read_instrument_infos_from_chunk :: proc(r: io.Reader, size: int) -> ([]Instrument_Info, Error) {
    result: []Instrument_Info = nil
    err: Error = nil

    defer {
        if err != nil {
            if result != nil {
                delete(result)
            }
        }
    }

    if size % 22 != 0 {
        err = Odinysynth_Error.Invalid_Soundfont
        return nil, err
    }

    count := size / 22

    if count <= 1 {
        err = Odinysynth_Error.Invalid_Soundfont
        return nil, err
    }

    result, err = make([]Instrument_Info, count)
    if err != nil {
        return nil, err
    }

    for i := 0; i < count; i += 1 {
        result[i], err = new_instrument_info(r)
        if err != nil {
            return nil, err
        }
    }

    for i := 0; i < count - 1; i += 1 {
        result[i].zone_end_index = result[i + 1].zone_start_index
    }

    return result, nil
}
