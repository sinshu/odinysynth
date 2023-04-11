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

preset_get_modulation_lfo_to_pitch :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Modulation_Lfo_To_Pitch])
}

preset_get_vibrato_lfo_to_pitch :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Vibrato_Lfo_To_Pitch])
}

preset_get_modulation_envelope_to_pitch :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Modulation_Envelope_To_Pitch])
}

preset_get_initial_filter_cutoff_frequency :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Initial_Filter_Cutoff_Frequency]))
}

preset_get_initial_filter_q :: proc(pr: ^Preset_Region) -> f32 {
    return 0.1 * f32(pr.gs[Generator_Type.Initial_Filter_Q])
}

preset_get_modulation_lfo_to_filter_cutoff_frequency :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Modulation_Lfo_To_Filter_Cutoff_Frequency])
}

preset_get_modulation_envelope_to_filter_cutoff_frequency :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Modulation_Envelope_To_Filter_Cutoff_Frequency])
}

preset_get_modulation_lfo_to_volume :: proc(pr: ^Preset_Region) -> f32 {
    return 0.1 * f32(pr.gs[Generator_Type.Modulation_Lfo_To_Volume])
}

preset_get_chorus_effects_send :: proc(pr: ^Preset_Region) -> f32 {
    return 0.1 * f32(pr.gs[Generator_Type.Chorus_Effects_Send])
}

preset_get_reverb_effects_send :: proc(pr: ^Preset_Region) -> f32 {
    return 0.1 * f32(pr.gs[Generator_Type.Reverb_Effects_Send])
}

preset_get_pan :: proc(pr: ^Preset_Region) -> f32 {
    return 0.1 * f32(pr.gs[Generator_Type.Pan])
}

preset_get_delay_modulation_lfo :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Delay_Modulation_Lfo]))
}

preset_get_frequency_modulation_lfo :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Frequency_Modulation_Lfo]))
}

preset_get_delay_vibrato_lfo :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Delay_Vibrato_Lfo]))
}

preset_get_frequency_vibrato_lfo :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Frequency_Vibrato_Lfo]))
}

preset_get_delay_modulation_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Delay_Modulation_Envelope]))
}

preset_get_attack_modulation_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Attack_Modulation_Envelope]))
}

preset_get_hold_modulation_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Hold_Modulation_Envelope]))
}

preset_get_decay_modulation_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Decay_Modulation_Envelope]))
}

preset_get_sustain_modulation_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return 0.1 * f32(pr.gs[Generator_Type.Sustain_Modulation_Envelope])
}

preset_get_release_modulation_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Release_Modulation_Envelope]))
}

preset_get_key_number_to_modulation_envelope_hold :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Key_Number_To_Modulation_Envelope_Hold])
}

preset_get_key_number_to_modulation_envelope_decay :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Key_Number_To_Modulation_Envelope_Decay])
}

preset_get_delay_volume_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Delay_Volume_Envelope]))
}

preset_get_attack_volume_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Attack_Volume_Envelope]))
}

preset_get_hold_volume_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Hold_Volume_Envelope]))
}

preset_get_decay_volume_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Decay_Volume_Envelope]))
}

preset_get_sustain_volume_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return 0.1 * f32(pr.gs[Generator_Type.Sustain_Volume_Envelope])
}

preset_get_release_volume_envelope :: proc(pr: ^Preset_Region) -> f32 {
    return cents_to_multiplying_factor(f32(pr.gs[Generator_Type.Release_Volume_Envelope]))
}

preset_get_key_number_to_volume_envelope_hold :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Key_Number_To_Volume_Envelope_Hold])
}

preset_get_key_number_to_volume_envelope_decay :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Key_Number_To_Volume_Envelope_Decay])
}

preset_get_key_range_start :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Key_Range]) & 0xFF
}

preset_get_key_range_end :: proc(pr: ^Preset_Region) -> i32 {
    return (i32(pr.gs[Generator_Type.Key_Range]) >> 8) & 0xFF
}

preset_get_velocity_range_start :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Velocity_Range]) & 0xFF
}

preset_get_velocity_range_end :: proc(pr: ^Preset_Region) -> i32 {
    return (i32(pr.gs[Generator_Type.Velocity_Range]) >> 8) & 0xFF
}

preset_get_initial_attenuation :: proc(pr: ^Preset_Region) -> f32 {
    return 0.1 * f32(pr.gs[Generator_Type.Initial_Attenuation])
}

preset_get_coarse_tune :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Coarse_Tune])
}

preset_get_fine_tune :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Fine_Tune])
}

preset_get_scale_tuning :: proc(pr: ^Preset_Region) -> i32 {
    return i32(pr.gs[Generator_Type.Scale_Tuning])
}
