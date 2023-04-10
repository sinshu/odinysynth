package odinysynth

import "core:io"

Instrument :: struct {
    name: [20]u8,
    regions: []Instrument_Region,
}

@(private)
new_instrument :: proc(name: [20]u8, regions: []Instrument_Region) -> Instrument {
    result: Instrument = {}
    result.name = name
    result.regions = regions
    return result
}

@(private)
create_instruments :: proc(infos: []Instrument_Info, all_zones: []Zone, all_regions: []Instrument_Region) -> ([]Instrument, Error) {
    result: []Instrument = nil
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

    result = make([]Instrument, instrument_count)

    region_index := 0
    for instrument_index := 0; instrument_index < instrument_count; instrument_index += 1 {
        info := infos[instrument_index]
        zones := all_zones[info.zone_start_index:info.zone_end_index]

        region_count := 0
        // Is the first one the global zone?
        if instrument_region_contains_global_zone(zones) {
            // The first one is the global zone.
            region_count = len(zones) - 1
        } else {
            // No global zone.
            region_count = len(zones)
        }

        region_end := region_index + region_count
        result[instrument_index] = new_instrument(info.name, all_regions[region_index:region_end])
        region_index += region_count
    }

    if region_index != len(all_regions) {
        err = Odinysynth_Error.Unexpected
        return nil, err
    }

    return result, nil
}
