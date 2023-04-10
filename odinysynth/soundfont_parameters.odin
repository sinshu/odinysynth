package odinysynth

import "core:io"

@(private)
Soundfont_Parameters :: struct {
    wave_data: []i16,
    sample_headers: []Sample_Header,
    instruments: []Instrument,
    instrument_regions: []Instrument_Region,
}

@(private)
new_soundfont_parameters :: proc(r: io.Reader) -> (Soundfont_Parameters, Error) {
    preset_infos: []Preset_Info = nil
    preset_bag: []Zone_Info = nil
    preset_generators: []Generator = nil
    instrument_infos: []Instrument_Info = nil
    instrument_bag: []Zone_Info = nil
    instrument_generators: []Generator = nil
    instrument_zones: []Zone = nil
    instrument_regions: []Instrument_Region = nil
    instruments: []Instrument = nil
    sample_headers: []Sample_Header = nil
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
        if instrument_zones != nil {
            delete(instrument_zones)
        }

        if err != nil {
            if instrument_regions != nil {
                delete(sample_headers)
            }
            if instruments != nil {
                delete(instruments)
            }
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

    instrument_zones, err = create_zones(instrument_bag[:], instrument_generators[:])
    if err != nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }

    instrument_regions, err = create_instrument_regions(instrument_infos[:], instrument_zones[:], sample_headers[:])
    if err != nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }

    instruments, err = create_instruments(instrument_infos[:], instrument_zones[:], instrument_regions[:])
    if err != nil {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, nil
    }

    result: Soundfont_Parameters = {}
    result.sample_headers = sample_headers
    result.instruments = instruments
    result.instrument_regions = instrument_regions
    return result, nil
}
