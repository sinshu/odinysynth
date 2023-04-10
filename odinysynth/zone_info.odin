package odinysynth

import "core:io"

Zone_Info :: struct {
    generator_index: u16,
    modulator_index: u16,
    generator_count: u16,
    modulator_count: u16,
}

@(private)
new_zone_info :: proc(r: io.Reader) -> (Zone_Info, Error) {
    result: Zone_Info = {}
    err: Error = nil

    result.generator_index, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    result.modulator_index, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    return result, nil
}

@(private)
read_zone_infos_from_chunk :: proc(r: io.Reader, size: int) -> ([]Zone_Info, Error) {
    result: []Zone_Info = nil
    err: Error = nil

    defer {
        if err != nil {
            if result != nil {
                delete(result)
            }
        }
    }

    if size % 4 != 0 {
        err = Odinysynth_Error.Invalid_Soundfont
        return nil, err
    }

    count := size / 4
    result = make([]Zone_Info, count)

    for i := 0; i < count; i += 1 {
        result[i], err = new_zone_info(r)
        if err != nil {
            return nil, err
        }
    }

    for i := 0; i < count - 1; i += 1 {
        result[i].generator_count = result[i + 1].generator_index - result[i].generator_index;
        result[i].modulator_count = result[i + 1].modulator_index - result[i].modulator_index;
    }

    return result, nil
}
