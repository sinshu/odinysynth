package odinysynth

import "core:io"

Preset_Region :: struct {
    instrument: ^Instrument,
    gs: [Generator_Type.Count]i16,
}

@(private)
preset_region_contains_global_zone :: proc(zones: []Zone) -> bool {
    if len(zones[0].generators) == 0 {
        return true
    }

    if zones[0].generators[len(zones[0].generators) - 1].generator_type != u16(Generator_Type.Instrument) {
        return true
    }

    return false
}

@(private)
preset_region_count_regions :: proc(infos: []Preset_Info, all_zones: []Zone) -> int {
    // The last one is the terminator.
    preset_count := len(infos) - 1

    sum: int = 0

    for preset_index: int = 0; preset_index < preset_count; preset_index += 1 {
        info := infos[preset_index]
        zones := all_zones[info.zone_start_index:info.zone_end_index]

        // Is the first one the global zone?
        if preset_region_contains_global_zone(zones) {
            // The first one is the global zone.
            sum += len(zones) - 1
        } else {
            // No global zone.
            sum += len(zones)
        }
    }

    return sum
}

@(private)
preset_region_set_parameter :: proc(gs: ^[Generator_Type.Count]i16, generator: Generator) {
    index := int(generator.generator_type)

    // Unknown generators should be ignored.
    if index < len(gs) {
        gs[index] = generator.value
    }
}

@(private)
new_preset_region :: proc(global: ^Zone, local: ^Zone, instruments: []Instrument) -> (Preset_Region, Error) {
    err: Error = nil

    gs: [Generator_Type.Count]i16 = {}
    gs[Generator_Type.Key_Range] = 0x7F00
    gs[Generator_Type.Velocity_Range] = 0x7F00

    for value in global.generators {
        preset_region_set_parameter(&gs, value)
    }

    for value in local.generators {
        preset_region_set_parameter(&gs, value)
    }

    id := int(gs[Generator_Type.Instrument])
    if id >= len(instruments) {
        err = Odinysynth_Error.Invalid_Soundfont
        return {}, err
    }
    instrument := &instruments[id]

    result: Preset_Region = {}
    result.instrument = instrument
    result.gs = gs
    return result, nil
}

@(private)
create_preset_regions :: proc(infos: []Preset_Info, all_zones: []Zone, instruments: []Instrument) -> ([]Preset_Region, Error) {
    result: []Preset_Region = nil
    err: Error = nil

    defer {
        if err != nil {
            if result != nil {
                delete(result)
            }
        }
    }

    // The last one is the terminator.
    preset_count := len(infos) - 1

    result = make([]Preset_Region, preset_region_count_regions(infos, all_zones))

    region_index := 0
    for preset_index := 0; preset_index < preset_count; preset_index += 1 {
        info := infos[preset_index]
        zones := all_zones[info.zone_start_index:info.zone_end_index]

        // Is the first one the global zone?
        if preset_region_contains_global_zone(zones) {
            // The first one is the global zone.
            for i := 0; i < len(zones) - 1; i += 1 {
                result[region_index], err = new_preset_region(&zones[0], &zones[i + 1], instruments)
                if err != nil {
                    err = Odinysynth_Error.Invalid_Soundfont
                    return nil, err
                }
                region_index += 1
            }
        } else {
            // No global zone.
            for i := 0; i < len(zones); i += 1 {
                result[region_index], err = new_preset_region(&empty_zone, &zones[i], instruments)
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
