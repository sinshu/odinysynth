package odinysynth

import "core:io"

@(private)
Preset_Info :: struct {
    name: [20]u8,
    patch_number: u16,
    bank_number: u16,
    zone_start_index: u16,
    zone_end_index: u16,
    library: i32,
    genre: i32,
    morphology: i32,
}

@(private)
new_preset_info :: proc(r: io.Reader) -> (Preset_Info, Error) {
    result: Preset_Info = {}
    err: Error = nil

    err = read_fixed_length_string(r, result.name[:])
    if err != nil {
        return {}, err
    }

    result.patch_number, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    result.bank_number, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    result.zone_start_index, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    result.library, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    result.genre, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    result.morphology, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    return result, nil
}

@(private)
read_preset_infos_from_chunk :: proc(r: io.Reader, size: int) -> ([]Preset_Info, Error) {
    result: []Preset_Info = nil
    err: Error = nil

    defer {
        if err != nil {
            if result != nil {
                delete(result)
            }
        }
    }

    if size % 38 != 0 {
        err = Odinysynth_Error.Invalid_Soundfont
        return nil, err
    }

    count := size / 38

    if count <= 1 {
        err = Odinysynth_Error.Invalid_Soundfont
        return nil, err
    }

    result = make([]Preset_Info, count)

    for i := 0; i < count; i += 1 {
        result[i], err = new_preset_info(r)
        if err != nil {
            return nil, err
        }
    }

    for i := 0; i < count - 1; i += 1 {
        result[i].zone_end_index = result[i + 1].zone_start_index;
    }

    return result, nil
}
