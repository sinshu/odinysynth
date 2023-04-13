package odinysynth

@(private)
region_pair_start_oscillator :: proc(rp: ^Region_Pair, o: ^Oscillator, data: []i16) {
    sample_rate := int(rp.instrument.sample.sample_rate)
    loop_mode := Loop_Mode(region_pair_get_sample_modes(rp))
    start := int(region_pair_get_sample_start(rp))
    end := int(region_pair_get_sample_end(rp))
    start_loop := int(region_pair_get_sample_start_loop(rp))
    end_loop := int(region_pair_get_sample_end_loop(rp))
    root_key := int(region_pair_get_root_key(rp))
    coarse_tune := int(region_pair_get_coarse_tune(rp))
    fine_tune := int(region_pair_get_fine_tune(rp))
    scale_tuning := int(region_pair_get_scale_tuning(rp))

    start_oscillator(o, data, loop_mode, sample_rate, start, end, start_loop, end_loop, root_key, coarse_tune, fine_tune, scale_tuning)
}

@(private)
region_pair_start_volume_envelope :: proc(rp: ^Region_Pair, e: ^Volume_Envelope, key: i32) {
    // If the release time is shorter than 10 ms, it will be clamped to 10 ms to avoid pop noise.
    delay := region_pair_get_delay_volume_envelope(rp)
    attack := region_pair_get_attack_volume_envelope(rp)
    hold := region_pair_get_hold_volume_envelope(rp) * key_number_to_multiplying_factor(region_pair_get_key_number_to_volume_envelope_hold(rp), key)
    decay := region_pair_get_decay_volume_envelope(rp) * key_number_to_multiplying_factor(region_pair_get_key_number_to_volume_envelope_decay(rp), key)
    sustain := decibels_to_linear(-region_pair_get_sustain_volume_envelope(rp))
    release := max(region_pair_get_release_volume_envelope(rp), 0.01)

    start_volume_envelope(e, delay, attack, hold, decay, sustain, release)
}

@(private)
region_pair_start_modulation_envelope :: proc(rp: ^Region_Pair, e: ^Modulation_Envelope, key: i32, velocity: i32) {
    // According to the implementation of TinySoundFont, the attack time should be adjusted by the velocity.
    delay := region_pair_get_delay_modulation_envelope(rp)
    attack := region_pair_get_attack_modulation_envelope(rp) * (f32(145 - velocity) / 144.0)
    hold := region_pair_get_hold_modulation_envelope(rp) * key_number_to_multiplying_factor(region_pair_get_key_number_to_modulation_envelope_hold(rp), key)
    decay := region_pair_get_decay_modulation_envelope(rp) * key_number_to_multiplying_factor(region_pair_get_key_number_to_modulation_envelope_decay(rp), key)
    sustain := 1.0 - region_pair_get_sustain_modulation_envelope(rp) / 100.0
    release := region_pair_get_release_modulation_envelope(rp)

    start_modulation_envelope(e, delay, attack, hold, decay, sustain, release)
}

@(private)
region_pair_start_vibrato :: proc(rp: ^Region_Pair, lfo: ^Lfo) {
    start_lfo(lfo, region_pair_get_delay_vibrato_lfo(rp), region_pair_get_frequency_vibrato_lfo(rp))
}

@(private)
region_pair_start_modulation :: proc(rp: ^Region_Pair, lfo: ^Lfo) {
    start_lfo(lfo, region_pair_get_delay_modulation_lfo(rp), region_pair_get_frequency_modulation_lfo(rp))
}
