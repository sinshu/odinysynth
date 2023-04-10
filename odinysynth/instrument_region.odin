package odinysynth

import "core:io"

Instrument_Region :: struct {
    sample: ^Sample_Header,
    gs: [Generator_Type.Count]i16,
}

instrument_region_contains_global_zone :: proc(zones: []Zone) -> bool {
    if len(zones[0].generators) == 0 {
        return true
    }

    if zones[0].generators[len(zones[0].generators) - 1].generator_type != u16(Generator_Type.Sample_ID) {
        return true
    }

    return false
}

instrument_region_count_regions :: proc(infos: []Instrument_Info, all_zones: []Zone) -> int {
    // The last one is the terminator.
    instrument_count := len(infos) - 1

    sum: int = 0

    for instrument_index: int = 0; instrument_index < instrument_count; instrument_index += 1 {
        info := infos[instrument_index]
        zones := all_zones[info.zone_start_index:info.zone_end_index]

        // Is the first one the global zone?
        if instrument_region_contains_global_zone(zones) {
            // The first one is the global zone.
            sum += len(zones) - 1
        } else {
            // No global zone.
            sum += len(zones)
        }
    }

    return sum
}

instrument_region_set_parameter :: proc(gs: ^[Generator_Type.Count]i16, generator: Generator) {
    index := int(generator.generator_type)

    // Unknown generators should be ignored.
    if index < len(gs) {
        gs[index] = generator.value
    }
}

new_instrument_region :: proc(global: ^Zone, local: ^Zone, samples: []Sample_Header) -> (Instrument_Region, Error) {
    err: Error = nil

    gs: [Generator_Type.Count]i16 = {}
    gs[Generator_Type.Initial_Filter_Cutoff_Frequency] = 13500
    gs[Generator_Type.Delay_Modulation_Lfo] = -12000
    gs[Generator_Type.Delay_Vibrato_Lfo] = -12000
    gs[Generator_Type.Delay_Modulation_Envelope] = -12000
    gs[Generator_Type.Attack_Modulation_Envelope] = -12000
    gs[Generator_Type.Hold_Modulation_Envelope] = -12000
    gs[Generator_Type.Decay_Modulation_Envelope] = -12000
    gs[Generator_Type.Release_Modulation_Envelope] = -12000
    gs[Generator_Type.Delay_Volume_Envelope] = -12000
    gs[Generator_Type.Attack_Volume_Envelope] = -12000
    gs[Generator_Type.Hold_Volume_Envelope] = -12000
    gs[Generator_Type.Decay_Volume_Envelope] = -12000
    gs[Generator_Type.Release_Volume_Envelope] = -12000
    gs[Generator_Type.Key_Range] = 0x7F00
    gs[Generator_Type.Velocity_Range] = 0x7F00
    gs[Generator_Type.Key_Number] = -1
    gs[Generator_Type.Velocity] = -1
    gs[Generator_Type.Scale_Tuning] = 100
    gs[Generator_Type.Overriding_Root_Key] = -1

    for value in global.generators {
        instrument_region_set_parameter(&gs, value)
    }

    for value in local.generators {
        instrument_region_set_parameter(&gs, value)
    }

    id := int(gs[Generator_Type.Sample_ID])
    if id >= len(samples) {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, err
    }
    sample := &samples[id]

    result: Instrument_Region = {}
    result.sample = sample
    result.gs = gs
    return result, nil
}

create_instrument_regions :: proc(infos: []Instrument_Info, all_zones: []Zone, samples: []Sample_Header) -> ([dynamic]Instrument_Region, Error) {
    result: [dynamic]Instrument_Region = nil
    err: Error = nil

    defer {
        if err != nil {
            if result != nil {
                delete(result)
            }
        }
    }

    // The last one is the terminator.
    instrument_count := len(infos) - 1

    result = make([dynamic]Instrument_Region, instrument_region_count_regions(infos, all_zones))

    region_index := 0
    for instrument_index := 0; instrument_index < instrument_count; instrument_index += 1 {
        info := infos[instrument_index]
        zones := all_zones[info.zone_start_index:info.zone_end_index]

        // Is the first one the global zone?
        if instrument_region_contains_global_zone(zones) {
            // The first one is the global zone.
            for i := 0; i < len(zones) - 1; i += 1 {
                result[region_index], err = new_instrument_region(&zones[0], &zones[i + 1], samples)
                if err != nil {
                    err = Odinysynth_Error.Invalid_Soundfont
                    return nil, err
                }
                region_index += 1
            }
        } else {
            // No global zone.
            for i := 0; i < len(zones); i += 1 {
                result[region_index], err = new_instrument_region(&empty_zone, &zones[i], samples)
                if err != nil {
                    err = Odinysynth_Error.Invalid_Soundfont
                    return nil, err
                }
                region_index += 1
            }
        }
    }

    if region_index != len(result) {
        err = Odinysynth_Error.Unexpected
        return nil, err
    }

    return result, nil
}
