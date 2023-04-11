package main

import "core:math"
import "core:testing"
import "odinysynth"

are_equal :: proc(t: ^testing.T, x: f64, y: f64) {
    if math.floor_f64(x) == math.ceil_f64(x) && math.floor_f64(y) == math.ceil_f64(y) {
        if x != y {
            testing.fail(t)
        }
        return
    }

    m := max(abs(x), abs(y))
    limit := m / 1000.0
    delta := abs(x - y)

    if delta >= limit {
        testing.fail(t)
    }
}

check_instrument_region :: proc(t: ^testing.T, ir: ^odinysynth.Instrument_Region, values: []f64) {
    are_equal(t, f64(odinysynth.instrument_get_sample_start(ir)), values[0])
    are_equal(t, f64(odinysynth.instrument_get_sample_end(ir)), values[1])
    are_equal(t, f64(odinysynth.instrument_get_sample_start_loop(ir)), values[2])
    are_equal(t, f64(odinysynth.instrument_get_sample_end_loop(ir)), values[3])
    are_equal(t, f64(odinysynth.instrument_get_start_address_offset(ir)), values[4])
    are_equal(t, f64(odinysynth.instrument_get_end_address_offset(ir)), values[5])
    are_equal(t, f64(odinysynth.instrument_get_start_loop_address_offset(ir)), values[6])
    are_equal(t, f64(odinysynth.instrument_get_end_loop_address_offset(ir)), values[7])
    are_equal(t, f64(odinysynth.instrument_get_modulation_lfo_to_pitch(ir)), values[8])
    are_equal(t, f64(odinysynth.instrument_get_vibrato_lfo_to_pitch(ir)), values[9])
    are_equal(t, f64(odinysynth.instrument_get_modulation_envelope_to_pitch(ir)), values[10])
    are_equal(t, f64(odinysynth.instrument_get_initial_filter_cutoff_frequency(ir)), values[11])
    are_equal(t, f64(odinysynth.instrument_get_initial_filter_q(ir)), values[12])
    are_equal(t, f64(odinysynth.instrument_get_modulation_lfo_to_filter_cutoff_frequency(ir)), values[13])
    are_equal(t, f64(odinysynth.instrument_get_modulation_envelope_to_filter_cutoff_frequency(ir)), values[14])
    are_equal(t, f64(odinysynth.instrument_get_modulation_lfo_to_volume(ir)), values[15])
    are_equal(t, f64(odinysynth.instrument_get_chorus_effects_send(ir)), values[16])
    are_equal(t, f64(odinysynth.instrument_get_reverb_effects_send(ir)), values[17])
    are_equal(t, f64(odinysynth.instrument_get_pan(ir)), values[18])
    are_equal(t, f64(odinysynth.instrument_get_delay_modulation_lfo(ir)), values[19])
    are_equal(t, f64(odinysynth.instrument_get_frequency_modulation_lfo(ir)), values[20])
    are_equal(t, f64(odinysynth.instrument_get_delay_vibrato_lfo(ir)), values[21])
    are_equal(t, f64(odinysynth.instrument_get_frequency_vibrato_lfo(ir)), values[22])
    are_equal(t, f64(odinysynth.instrument_get_delay_modulation_envelope(ir)), values[23])
    are_equal(t, f64(odinysynth.instrument_get_attack_modulation_envelope(ir)), values[24])
    are_equal(t, f64(odinysynth.instrument_get_hold_modulation_envelope(ir)), values[25])
    are_equal(t, f64(odinysynth.instrument_get_decay_modulation_envelope(ir)), values[26])
    are_equal(t, f64(odinysynth.instrument_get_sustain_modulation_envelope(ir)), values[27])
    are_equal(t, f64(odinysynth.instrument_get_release_modulation_envelope(ir)), values[28])
    are_equal(t, f64(odinysynth.instrument_get_key_number_to_modulation_envelope_hold(ir)), values[29])
    are_equal(t, f64(odinysynth.instrument_get_key_number_to_modulation_envelope_decay(ir)), values[30])
    are_equal(t, f64(odinysynth.instrument_get_delay_volume_envelope(ir)), values[31])
    are_equal(t, f64(odinysynth.instrument_get_attack_volume_envelope(ir)), values[32])
    are_equal(t, f64(odinysynth.instrument_get_hold_volume_envelope(ir)), values[33])
    are_equal(t, f64(odinysynth.instrument_get_decay_volume_envelope(ir)), values[34])
    are_equal(t, f64(odinysynth.instrument_get_sustain_volume_envelope(ir)), values[35])
    are_equal(t, f64(odinysynth.instrument_get_release_volume_envelope(ir)), values[36])
    are_equal(t, f64(odinysynth.instrument_get_key_number_to_volume_envelope_hold(ir)), values[37])
    are_equal(t, f64(odinysynth.instrument_get_key_number_to_volume_envelope_decay(ir)), values[38])
    are_equal(t, f64(odinysynth.instrument_get_key_range_start(ir)), values[39])
    are_equal(t, f64(odinysynth.instrument_get_key_range_end(ir)), values[40])
    are_equal(t, f64(odinysynth.instrument_get_velocity_range_start(ir)), values[41])
    are_equal(t, f64(odinysynth.instrument_get_velocity_range_end(ir)), values[42])
    are_equal(t, f64(odinysynth.instrument_get_initial_attenuation(ir)), values[43])
    are_equal(t, f64(odinysynth.instrument_get_coarse_tune(ir)), values[44])
    are_equal(t, f64(odinysynth.instrument_get_fine_tune(ir)), values[45])
    are_equal(t, f64(odinysynth.instrument_get_sample_modes(ir)), values[46])
    are_equal(t, f64(odinysynth.instrument_get_scale_tuning(ir)), values[47])
    are_equal(t, f64(odinysynth.instrument_get_exclusive_class(ir)), values[48])
    are_equal(t, f64(odinysynth.instrument_get_root_key(ir)), values[49])
}

check_preset_region :: proc(t: ^testing.T, pr: ^odinysynth.Preset_Region, values: []f64) {
    are_equal(t, f64(odinysynth.preset_get_modulation_lfo_to_pitch(pr)), values[0])
    are_equal(t, f64(odinysynth.preset_get_vibrato_lfo_to_pitch(pr)), values[1])
    are_equal(t, f64(odinysynth.preset_get_modulation_envelope_to_pitch(pr)), values[2])
    are_equal(t, f64(odinysynth.preset_get_initial_filter_cutoff_frequency(pr)), values[3])
    are_equal(t, f64(odinysynth.preset_get_initial_filter_q(pr)), values[4])
    are_equal(t, f64(odinysynth.preset_get_modulation_lfo_to_filter_cutoff_frequency(pr)), values[5])
    are_equal(t, f64(odinysynth.preset_get_modulation_envelope_to_filter_cutoff_frequency(pr)), values[6])
    are_equal(t, f64(odinysynth.preset_get_modulation_lfo_to_volume(pr)), values[7])
    are_equal(t, f64(odinysynth.preset_get_chorus_effects_send(pr)), values[8])
    are_equal(t, f64(odinysynth.preset_get_reverb_effects_send(pr)), values[9])
    are_equal(t, f64(odinysynth.preset_get_pan(pr)), values[10])
    are_equal(t, f64(odinysynth.preset_get_delay_modulation_lfo(pr)), values[11])
    are_equal(t, f64(odinysynth.preset_get_frequency_modulation_lfo(pr)), values[12])
    are_equal(t, f64(odinysynth.preset_get_delay_vibrato_lfo(pr)), values[13])
    are_equal(t, f64(odinysynth.preset_get_frequency_vibrato_lfo(pr)), values[14])
    are_equal(t, f64(odinysynth.preset_get_delay_modulation_envelope(pr)), values[15])
    are_equal(t, f64(odinysynth.preset_get_attack_modulation_envelope(pr)), values[16])
    are_equal(t, f64(odinysynth.preset_get_hold_modulation_envelope(pr)), values[17])
    are_equal(t, f64(odinysynth.preset_get_decay_modulation_envelope(pr)), values[18])
    are_equal(t, f64(odinysynth.preset_get_sustain_modulation_envelope(pr)), values[19])
    are_equal(t, f64(odinysynth.preset_get_release_modulation_envelope(pr)), values[20])
    are_equal(t, f64(odinysynth.preset_get_key_number_to_modulation_envelope_hold(pr)), values[21])
    are_equal(t, f64(odinysynth.preset_get_key_number_to_modulation_envelope_decay(pr)), values[22])
    are_equal(t, f64(odinysynth.preset_get_delay_volume_envelope(pr)), values[23])
    are_equal(t, f64(odinysynth.preset_get_attack_volume_envelope(pr)), values[24])
    are_equal(t, f64(odinysynth.preset_get_hold_volume_envelope(pr)), values[25])
    are_equal(t, f64(odinysynth.preset_get_decay_volume_envelope(pr)), values[26])
    are_equal(t, f64(odinysynth.preset_get_sustain_volume_envelope(pr)), values[27])
    are_equal(t, f64(odinysynth.preset_get_release_volume_envelope(pr)), values[28])
    are_equal(t, f64(odinysynth.preset_get_key_number_to_volume_envelope_hold(pr)), values[29])
    are_equal(t, f64(odinysynth.preset_get_key_number_to_volume_envelope_decay(pr)), values[30])
    are_equal(t, f64(odinysynth.preset_get_key_range_start(pr)), values[31])
    are_equal(t, f64(odinysynth.preset_get_key_range_end(pr)), values[32])
    are_equal(t, f64(odinysynth.preset_get_velocity_range_start(pr)), values[33])
    are_equal(t, f64(odinysynth.preset_get_velocity_range_end(pr)), values[34])
    are_equal(t, f64(odinysynth.preset_get_initial_attenuation(pr)), values[35])
    are_equal(t, f64(odinysynth.preset_get_coarse_tune(pr)), values[36])
    are_equal(t, f64(odinysynth.preset_get_fine_tune(pr)), values[37])
    are_equal(t, f64(odinysynth.preset_get_scale_tuning(pr)), values[38])
}
