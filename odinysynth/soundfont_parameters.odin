package odinysynth

import "core:fmt"
import "core:io"

@(private)
Soundfont_Parameters :: struct {
    sample_headers: [dynamic]Sample_Header
}

@(private)
new_soundfont_parameters :: proc(r: io.Reader) -> (Soundfont_Parameters, Error) {
    preset_infos: [dynamic]Preset_Info = nil
    preset_bag: [dynamic]Zone_Info = nil
    preset_generators: [dynamic]Generator = nil
    instrument_infos: [dynamic]Instrument_Info = nil
    instrument_bag: [dynamic]Zone_Info = nil
    instrument_generators: [dynamic]Generator = nil
    sample_headers: [dynamic]Sample_Header = nil
    err: Error = nil

    defer {
        if preset_infos != nil {
            delete(preset_infos)
        }
        if preset_bag != nil {
            delete(preset_bag)
        }
        if preset_generators != nil {
            delete(preset_generators)
        }
        if instrument_infos != nil {
            delete(instrument_infos)
        }
        if instrument_bag != nil {
            delete(instrument_bag)
        }
        if instrument_generators != nil {
            delete(instrument_generators)
        }

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
        case "phdr":
            preset_infos, err = read_preset_infos_from_chunk(r, int(size))
        case "pbag":
            preset_bag, err = read_zone_infos_from_chunk(r, int(size))
        case "pmod":
            err = discard_data(r, int(size))
        case "pgen":
            preset_generators, err = read_generators_from_chunk(r, int(size))
        case "inst":
            instrument_infos, err = read_instrument_infos_from_chunk(r, int(size))
        case "ibag":
            instrument_bag, err = read_zone_infos_from_chunk(r, int(size))
        case "imod":
            err = discard_data(r, int(size))
        case "igen":
            instrument_generators, err = read_generators_from_chunk(r, int(size))
        case "shdr":
            sample_headers, err = read_sample_headers_from_chunk(r, int(size))
        case:
            err = Odinysynth_Error.Invalid_Soundfont
        }
        if err != nil {
            return {}, err
        }

        pos += size
    }

    if preset_infos == nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }
    if preset_bag == nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }
    if preset_generators == nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }
    if instrument_infos == nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }
    if instrument_bag == nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }
    if instrument_generators == nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }
    if sample_headers == nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }

    result: Soundfont_Parameters = {}
    result.sample_headers = sample_headers

    for h in instrument_infos {
        fmt.printf("%s\n", h.name)
    }

    return result, nil
}
