package odinysynth

import "core:io"

Preset :: struct {
    name: [20]u8,
    patch_number: i32,
    bank_number: i32,
    regions: []Preset_Region,
}

@(private)
new_preset :: proc(info: ^Preset_Info, regions: []Preset_Region) -> Preset {
    result: Preset = {}
    result.name = info.name
    result.patch_number = i32(info.patch_number)
    result.bank_number = i32(info.bank_number)
    result.regions = regions
    return result
}

@(private)
create_presets :: proc(infos: []Preset_Info, all_zones: []Zone, all_regions: []Preset_Region) -> ([]Preset, Error) {
    result: []Preset = nil
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

    result = make([]Preset, preset_count)

    region_index := 0
    for preset_index := 0; preset_index < preset_count; preset_index += 1 {
        info := infos[preset_index]
        zones := all_zones[info.zone_start_index:info.zone_end_index]

        region_count := 0
        // Is the first one the global zone?
        if preset_region_contains_global_zone(zones) {
            // The first one is the global zone.
            region_count = len(zones) - 1
        } else {
            // No global zone.
            region_count = len(zones)
        }

        region_end := region_index + region_count
        result[preset_index] = new_preset(&info, all_regions[region_index:region_end])
        region_index += region_count
    }

    if region_index != len(all_regions) {
        err = Odinysynth_Error.Unexpected
        return nil, err
    }

    return result, nil
}
