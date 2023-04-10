package odinysynth

import "core:io"

Soundfont :: struct {
    wave_data: [dynamic]i16,
    sample_headers: [dynamic]Sample_Header,
    instruments: [dynamic]Instrument,
    instrument_regions: [dynamic]Instrument_Region,
}

new_soundfont :: proc(r: io.Reader) -> (Soundfont, Error) {
    wave_data: [dynamic]i16 = nil
    sample_headers: [dynamic]Sample_Header = nil
    instruments: [dynamic]Instrument = nil
    instrument_regions: [dynamic]Instrument_Region = nil
    err: Error = nil

    defer {
        if err != nil {
            if wave_data != nil {
                delete(wave_data)
            }
            if sample_headers != nil {
                delete(sample_headers)
            }
            if instruments != nil {
                delete(instruments)
            }
            if instrument_regions != nil {
                delete(instrument_regions)
            }
        }
    }

    chunk_id: [4]u8
    chunk_id, err = read_four_cc(r)
    if err != nil {
        return {}, err
    }
    if chunk_id != "RIFF" {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, err
    }

    size: i32
    size, err = read_i32(r)
    if err != nil {
        return {}, err
    }

    form_type: [4]u8
    form_type, err = read_four_cc(r)
    if err != nil {
        return {}, err
    }
    if form_type != "sfbk" {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, err
    }

    err = skip_soundfont_info(r)
    if err != nil {
        return {}, err
    }

    sample_data: Soundfont_Sample_Data
    sample_data, err = new_soundfont_sample_data(r)
    wave_data = sample_data.samples

    parameters: Soundfont_Parameters
    parameters, err = new_soundfont_parameters(r)
    sample_headers = parameters.sample_headers
    instruments = parameters.instruments
    instrument_regions = parameters.instrument_regions

    result: Soundfont = {}
    result.wave_data = wave_data
    result.sample_headers = sample_headers
    result.instruments = instruments
    result.instrument_regions = instrument_regions
    return result, nil
}

destroy_soundfont :: proc(soundfont: Soundfont) {
    delete(soundfont.wave_data)
    delete(soundfont.sample_headers)
    delete(soundfont.instruments)
    delete(soundfont.instrument_regions)
}

@(private)
skip_soundfont_info :: proc(r: io.Reader) -> Error {
    err: Error = nil

    chunk_id: [4]u8
    chunk_id, err = read_four_cc(r)
    if err != nil {
        return err
    }
    if chunk_id != "LIST" {
        err = Odinysynth_Error.Invalid_Soundfont
        return err
    }

    size: i32
    size, err = read_i32(r)
    if err != nil {
        return err
    }
    return discard_data(r, int(size))
}
