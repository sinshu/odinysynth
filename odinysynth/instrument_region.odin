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

create_instrument_regions :: proc(infos: []Instrument_Info, all_zones: []Zone, samples: []Sample_Header) -> ([]Instrument_Region, Error) {
    result: []Instrument_Region = nil
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

    result = make([]Instrument_Region, instrument_region_count_regions(infos, all_zones))

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

instrument_get_sample_start :: proc(ir: ^Instrument_Region) -> i32 {
    return ir.sample.start + instrument_get_start_address_offset(ir)
}

instrument_get_sample_end :: proc(ir: ^Instrument_Region) -> i32 {
    return ir.sample.end + instrument_get_end_address_offset(ir)
}

instrument_get_sample_start_loop :: proc(ir: ^Instrument_Region) -> i32 {
    return ir.sample.start_loop + instrument_get_start_loop_address_offset(ir)
}

instrument_get_sample_end_loop :: proc(ir: ^Instrument_Region) -> i32 {
    return ir.sample.end_loop + instrument_get_end_loop_address_offset(ir)
}

instrument_get_start_address_offset :: proc(ir: ^Instrument_Region) -> i32 {
    return 32768 * i32(ir.gs[Generator_Type.Start_Address_Coarse_Offset]) + i32(ir.gs[Generator_Type.Start_Address_Offset])
}

instrument_get_end_address_offset :: proc(ir: ^Instrument_Region) -> i32 {
    return 32768 * i32(ir.gs[Generator_Type.End_Address_Coarse_Offset]) + i32(ir.gs[Generator_Type.End_Address_Offset])
}

instrument_get_start_loop_address_offset :: proc(ir: ^Instrument_Region) -> i32 {
    return 32768 * i32(ir.gs[Generator_Type.Start_Loop_Address_Coarse_Offset]) + i32(ir.gs[Generator_Type.Start_Loop_Address_Offset])
}

instrument_get_end_loop_address_offset :: proc(ir: ^Instrument_Region) -> i32 {
    return 32768 * i32(ir.gs[Generator_Type.End_Loop_Address_Coarse_Offset]) + i32(ir.gs[Generator_Type.End_Loop_Address_Offset])
}

instrument_get_modulation_lfo_to_pitch :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Modulation_Lfo_To_Pitch])
}

instrument_get_vibrato_lfo_to_pitch :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Vibrato_Lfo_To_Pitch])
}

instrument_get_modulation_envelope_to_pitch :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Modulation_Envelope_To_Pitch])
}

instrument_get_initial_filter_cutoff_frequency :: proc(ir: ^Instrument_Region) -> f32 {
    return cents_to_hertz(f32(ir.gs[Generator_Type.Initial_Filter_Cutoff_Frequency]))
}

instrument_get_initial_filter_q :: proc(ir: ^Instrument_Region) -> f32 {
    return 0.1 * f32(ir.gs[Generator_Type.Initial_Filter_Q])
}

instrument_get_modulation_lfo_to_filter_cutoff_frequency :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Modulation_Lfo_To_Filter_Cutoff_Frequency])
}

instrument_get_modulation_envelope_to_filter_cutoff_frequency :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Modulation_Envelope_To_Filter_Cutoff_Frequency])
}

instrument_get_modulation_lfo_to_volume :: proc(ir: ^Instrument_Region) -> f32 {
    return 0.1 * f32(ir.gs[Generator_Type.Modulation_Lfo_To_Volume])
}

instrument_get_chorus_effects_send :: proc(ir: ^Instrument_Region) -> f32 {
    return 0.1 * f32(ir.gs[Generator_Type.Chorus_Effects_Send])
}

instrument_get_reverb_effects_send :: proc(ir: ^Instrument_Region) -> f32 {
    return 0.1 * f32(ir.gs[Generator_Type.Reverb_Effects_Send])
}

instrument_get_pan :: proc(ir: ^Instrument_Region) -> f32 {
    return 0.1 * f32(ir.gs[Generator_Type.Pan])
}

instrument_get_delay_modulation_lfo :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Delay_Modulation_Lfo]))
}

instrument_get_frequency_modulation_lfo :: proc(ir: ^Instrument_Region) -> f32 {
    return cents_to_hertz(f32(ir.gs[Generator_Type.Frequency_Modulation_Lfo]))
}

instrument_get_delay_vibrato_lfo :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Delay_Vibrato_Lfo]))
}

instrument_get_frequency_vibrato_lfo :: proc(ir: ^Instrument_Region) -> f32 {
    return cents_to_hertz(f32(ir.gs[Generator_Type.Frequency_Vibrato_Lfo]))
}

instrument_get_delay_modulation_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Delay_Modulation_Envelope]))
}

instrument_get_attack_modulation_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Attack_Modulation_Envelope]))
}

instrument_get_hold_modulation_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Hold_Modulation_Envelope]))
}

instrument_get_decay_modulation_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Decay_Modulation_Envelope]))
}

instrument_get_sustain_modulation_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return 0.1 * f32(ir.gs[Generator_Type.Sustain_Modulation_Envelope])
}

instrument_get_release_modulation_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Release_Modulation_Envelope]))
}

instrument_get_key_number_to_modulation_envelope_hold :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Key_Number_To_Modulation_Envelope_Hold])
}

instrument_get_key_number_to_modulation_envelope_decay :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Key_Number_To_Modulation_Envelope_Decay])
}

instrument_get_delay_volume_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Delay_Volume_Envelope]))
}

instrument_get_attack_volume_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Attack_Volume_Envelope]))
}

instrument_get_hold_volume_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Hold_Volume_Envelope]))
}

instrument_get_decay_volume_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Decay_Volume_Envelope]))
}

instrument_get_sustain_volume_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return 0.1 * f32(ir.gs[Generator_Type.Sustain_Volume_Envelope])
}

instrument_get_release_volume_envelope :: proc(ir: ^Instrument_Region) -> f32 {
    return timecents_to_seconds(f32(ir.gs[Generator_Type.Release_Volume_Envelope]))
}

instrument_get_key_number_to_volume_envelope_hold :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Key_Number_To_Volume_Envelope_Hold])
}

instrument_get_key_number_to_volume_envelope_decay :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Key_Number_To_Volume_Envelope_Decay])
}

instrument_get_key_range_start :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Key_Range]) & 0xFF
}

instrument_get_key_range_end :: proc(ir: ^Instrument_Region) -> i32 {
    return (i32(ir.gs[Generator_Type.Key_Range]) >> 8) & 0xFF
}

instrument_get_velocity_range_start :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Velocity_Range]) & 0xFF
}

instrument_get_velocity_range_end :: proc(ir: ^Instrument_Region) -> i32 {
    return (i32(ir.gs[Generator_Type.Velocity_Range]) >> 8) & 0xFF
}

instrument_get_initial_attenuation :: proc(ir: ^Instrument_Region) -> f32 {
    return 0.1 * f32(ir.gs[Generator_Type.Initial_Attenuation])
}

instrument_get_coarse_tune :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Coarse_Tune])
}

instrument_get_fine_tune :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Fine_Tune]) + i32(ir.sample.pitch_correction)
}

instrument_get_sample_modes :: proc(ir: ^Instrument_Region) -> i32 {
    return ir.gs[Generator_Type.Sample_Modes] != 2 ? i32(ir.gs[Generator_Type.Sample_Modes]) : i32(Loop_Mode.No_Loop)
}

instrument_get_scale_tuning :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Scale_Tuning])
}

instrument_get_exclusive_class :: proc(ir: ^Instrument_Region) -> i32 {
    return i32(ir.gs[Generator_Type.Exclusive_Class])
}

instrument_get_root_key :: proc(ir: ^Instrument_Region) -> i32 {
    return ir.gs[Generator_Type.Overriding_Root_Key] != -1 ? i32(ir.gs[Generator_Type.Overriding_Root_Key]) : i32(ir.sample.original_pitch)
}
