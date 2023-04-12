package odinysynth

@(private)
Region_Pair :: struct {
    preset: ^Preset_Region,
    instrument: ^Instrument_Region,
}

@(private)
new_region_pair :: proc(preset: ^Preset_Region, instrument: ^Instrument_Region) -> Region_Pair {
    result: Region_Pair = {}
    result.preset = preset
    result.instrument = instrument
    return result
}

@(private)
region_pair_gs :: proc(rp: ^Region_Pair, gt: Generator_Type) -> int {
    return int(rp.preset.gs[int(gt)]) + int(rp.instrument.gs[int(gt)])
}

@(private)
region_pair_get_sample_start :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_sample_start(rp.instrument)
}

@(private)
region_pair_get_sample_end :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_sample_end(rp.instrument)
}

@(private)
region_pair_get_sample_start_loop :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_sample_start_loop(rp.instrument)
}

@(private)
region_pair_get_sample_end_loop :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_sample_end_loop(rp.instrument)
}

@(private)
region_pair_get_start_address_offset :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_start_address_offset(rp.instrument)
}

@(private)
region_pair_get_end_address_offset :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_end_address_offset(rp.instrument)
}

@(private)
region_pair_get_start_loop_address_offset :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_start_loop_address_offset(rp.instrument)
}

@(private)
region_pair_get_end_loop_address_offset :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_end_loop_address_offset(rp.instrument)
}

@(private)
region_pair_get_modulation_lfo_to_pitch :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Modulation_Lfo_To_Pitch))
}

@(private)
region_pair_get_vibrato_lfo_to_pitch :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Vibrato_Lfo_To_Pitch))
}

@(private)
region_pair_get_modulation_envelope_to_pitch :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Modulation_Envelope_To_Pitch))
}

@(private)
region_pair_get_initial_filter_cutoff_frequency :: proc(rp: ^Region_Pair) -> f32 {
    return cents_to_hertz(f32(region_pair_gs(rp, Generator_Type.Initial_Filter_Cutoff_Frequency)))
}

@(private)
region_pair_get_initial_filter_q :: proc(rp: ^Region_Pair) -> f32 {
    return 0.1 * f32(region_pair_gs(rp, Generator_Type.Initial_Filter_Q))
}

@(private)
region_pair_get_modulation_lfo_to_filter_cutoff_frequency :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Modulation_Lfo_To_Filter_Cutoff_Frequency))
}

@(private)
region_pair_get_modulation_envelope_to_filter_cutoff_frequency :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Modulation_Envelope_To_Filter_Cutoff_Frequency))
}

@(private)
region_pair_get_modulation_lfo_to_volume :: proc(rp: ^Region_Pair) -> f32 {
    return 0.1 * f32(region_pair_gs(rp, Generator_Type.Modulation_Lfo_To_Volume))
}

@(private)
region_pair_get_chorus_effects_send :: proc(rp: ^Region_Pair) -> f32 {
    return 0.1 * f32(region_pair_gs(rp, Generator_Type.Chorus_Effects_Send))
}

@(private)
region_pair_get_reverb_effects_send :: proc(rp: ^Region_Pair) -> f32 {
    return 0.1 * f32(region_pair_gs(rp, Generator_Type.Reverb_Effects_Send))
}

@(private)
region_pair_get_pan :: proc(rp: ^Region_Pair) -> f32 {
    return 0.1 * f32(region_pair_gs(rp, Generator_Type.Pan))
}

@(private)
region_pair_get_delay_modulation_lfo :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Delay_Modulation_Lfo)))
}

@(private)
region_pair_get_frequency_modulation_lfo :: proc(rp: ^Region_Pair) -> f32 {
    return cents_to_hertz(f32(region_pair_gs(rp, Generator_Type.Frequency_Modulation_Lfo)))
}

@(private)
region_pair_get_delay_vibrato_lfo :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Delay_Vibrato_Lfo)))
}

@(private)
region_pair_get_frequency_vibrato_lfo :: proc(rp: ^Region_Pair) -> f32 {
    return cents_to_hertz(f32(region_pair_gs(rp, Generator_Type.Frequency_Vibrato_Lfo)))
}

@(private)
region_pair_get_delay_modulation_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Delay_Modulation_Envelope)))
}

@(private)
region_pair_get_attack_modulation_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Attack_Modulation_Envelope)))
}

@(private)
region_pair_get_hold_modulation_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Hold_Modulation_Envelope)))
}

@(private)
region_pair_get_decay_modulation_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Decay_Modulation_Envelope)))
}

@(private)
region_pair_get_sustain_modulation_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return 0.1 * f32(region_pair_gs(rp, Generator_Type.Sustain_Modulation_Envelope))
}

@(private)
region_pair_get_release_modulation_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Release_Modulation_Envelope)))
}

@(private)
region_pair_get_key_number_to_modulation_envelope_hold :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Key_Number_To_Modulation_Envelope_Hold))
}

@(private)
region_pair_get_key_number_to_modulation_envelope_decay :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Key_Number_To_Modulation_Envelope_Decay))
}

@(private)
region_pair_get_delay_volume_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Delay_Volume_Envelope)))
}

@(private)
region_pair_get_attack_volume_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Attack_Volume_Envelope)))
}

@(private)
region_pair_get_hold_volume_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Hold_Volume_Envelope)))
}

@(private)
region_pair_get_decay_volume_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Decay_Volume_Envelope)))
}

@(private)
region_pair_get_sustain_volume_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return 0.1 * f32(region_pair_gs(rp, Generator_Type.Sustain_Volume_Envelope))
}

@(private)
region_pair_get_release_volume_envelope :: proc(rp: ^Region_Pair) -> f32 {
    return timecents_to_seconds(f32(region_pair_gs(rp, Generator_Type.Release_Volume_Envelope)))
}

@(private)
region_pair_get_key_number_to_volume_envelope_hold :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Key_Number_To_Volume_Envelope_Hold))
}

@(private)
region_pair_get_key_number_to_volume_envelope_decay :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Key_Number_To_Volume_Envelope_Decay))
}

@(private)
region_pair_get_initial_attenuation :: proc(rp: ^Region_Pair) -> f32 {
    return 0.1 * f32(region_pair_gs(rp, Generator_Type.Initial_Attenuation))
}

@(private)
region_pair_get_coarse_tune :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Coarse_Tune))
}

@(private)
region_pair_get_fine_tune :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Fine_Tune)) + i32(rp.instrument.sample.pitch_correction)
}

@(private)
region_pair_get_sample_modes :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_sample_modes(rp.instrument)
}

@(private)
region_pair_get_scale_tuning :: proc(rp: ^Region_Pair) -> i32 {
    return i32(region_pair_gs(rp, Generator_Type.Scale_Tuning))
}

@(private)
region_pair_get_exclusive_class :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_exclusive_class(rp.instrument)
}

@(private)
region_pair_get_root_key :: proc(rp: ^Region_Pair) -> i32 {
    return instrument_get_root_key(rp.instrument)
}
