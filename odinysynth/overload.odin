package odinysynth

destroy :: proc{destroy_soundfont, destroy_synthesizer, destroy_midi_file}
render :: proc{synthesizer_render, sequencer_render}

get_sample_start :: proc{instrument_get_sample_start}
get_sample_end :: proc{instrument_get_sample_end}
get_sample_start_loop :: proc{instrument_get_sample_start_loop}
get_sample_end_loop :: proc{instrument_get_sample_end_loop}
get_start_address_offset :: proc{instrument_get_start_address_offset}
get_end_address_offset :: proc{instrument_get_end_address_offset}
get_start_loop_address_offset :: proc{instrument_get_start_loop_address_offset}
get_end_loop_address_offset :: proc{instrument_get_end_loop_address_offset}
get_modulation_lfo_to_pitch :: proc{instrument_get_modulation_lfo_to_pitch, preset_get_modulation_lfo_to_pitch}
get_vibrato_lfo_to_pitch :: proc{instrument_get_vibrato_lfo_to_pitch, preset_get_vibrato_lfo_to_pitch}
get_modulation_envelope_to_pitch :: proc{instrument_get_modulation_envelope_to_pitch, preset_get_modulation_envelope_to_pitch}
get_initial_filter_cutoff_frequency :: proc{instrument_get_initial_filter_cutoff_frequency, preset_get_initial_filter_cutoff_frequency}
get_initial_filter_q :: proc{instrument_get_initial_filter_q, preset_get_initial_filter_q}
get_modulation_lfo_to_filter_cutoff_frequency :: proc{instrument_get_modulation_lfo_to_filter_cutoff_frequency, preset_get_modulation_lfo_to_filter_cutoff_frequency}
get_modulation_envelope_to_filter_cutoff_frequency :: proc{instrument_get_modulation_envelope_to_filter_cutoff_frequency, preset_get_modulation_envelope_to_filter_cutoff_frequency}
get_modulation_lfo_to_volume :: proc{instrument_get_modulation_lfo_to_volume, preset_get_modulation_lfo_to_volume}
get_chorus_effects_send :: proc{instrument_get_chorus_effects_send, preset_get_chorus_effects_send}
get_reverb_effects_send :: proc{instrument_get_reverb_effects_send, preset_get_reverb_effects_send}
get_pan :: proc{instrument_get_pan, preset_get_pan}
get_delay_modulation_lfo :: proc{instrument_get_delay_modulation_lfo, preset_get_delay_modulation_lfo}
get_frequency_modulation_lfo :: proc{instrument_get_frequency_modulation_lfo, preset_get_frequency_modulation_lfo}
get_delay_vibrato_lfo :: proc{instrument_get_delay_vibrato_lfo, preset_get_delay_vibrato_lfo}
get_frequency_vibrato_lfo :: proc{instrument_get_frequency_vibrato_lfo, preset_get_frequency_vibrato_lfo}
get_delay_modulation_envelope :: proc{instrument_get_delay_modulation_envelope, preset_get_delay_modulation_envelope}
get_attack_modulation_envelope :: proc{instrument_get_attack_modulation_envelope, preset_get_attack_modulation_envelope}
get_hold_modulation_envelope :: proc{instrument_get_hold_modulation_envelope, preset_get_hold_modulation_envelope}
get_decay_modulation_envelope :: proc{instrument_get_decay_modulation_envelope, preset_get_decay_modulation_envelope}
get_sustain_modulation_envelope :: proc{instrument_get_sustain_modulation_envelope, preset_get_sustain_modulation_envelope}
get_release_modulation_envelope :: proc{instrument_get_release_modulation_envelope, preset_get_release_modulation_envelope}
get_key_number_to_modulation_envelope_hold :: proc{instrument_get_key_number_to_modulation_envelope_hold, preset_get_key_number_to_modulation_envelope_hold}
get_key_number_to_modulation_envelope_decay :: proc{instrument_get_key_number_to_modulation_envelope_decay, preset_get_key_number_to_modulation_envelope_decay}
get_delay_volume_envelope :: proc{instrument_get_delay_volume_envelope, preset_get_delay_volume_envelope}
get_attack_volume_envelope :: proc{instrument_get_attack_volume_envelope, preset_get_attack_volume_envelope}
get_hold_volume_envelope :: proc{instrument_get_hold_volume_envelope, preset_get_hold_volume_envelope}
get_decay_volume_envelope :: proc{instrument_get_decay_volume_envelope, preset_get_decay_volume_envelope}
get_sustain_volume_envelope :: proc{instrument_get_sustain_volume_envelope, preset_get_sustain_volume_envelope}
get_release_volume_envelope :: proc{instrument_get_release_volume_envelope, preset_get_release_volume_envelope}
get_key_number_to_volume_envelope_hold :: proc{instrument_get_key_number_to_volume_envelope_hold, preset_get_key_number_to_volume_envelope_hold}
get_key_number_to_volume_envelope_decay :: proc{instrument_get_key_number_to_volume_envelope_decay, preset_get_key_number_to_volume_envelope_decay}
get_key_range_start :: proc{instrument_get_key_range_start, preset_get_key_range_start}
get_key_range_end :: proc{instrument_get_key_range_end, preset_get_key_range_end}
get_velocity_range_start :: proc{instrument_get_velocity_range_start, preset_get_velocity_range_start}
get_velocity_range_end :: proc{instrument_get_velocity_range_end, preset_get_velocity_range_end}
get_initial_attenuation :: proc{instrument_get_initial_attenuation, preset_get_initial_attenuation}
get_coarse_tune :: proc{instrument_get_coarse_tune, preset_get_coarse_tune}
get_fine_tune :: proc{instrument_get_fine_tune, preset_get_fine_tune}
get_sample_modes :: proc{instrument_get_sample_modes}
get_scale_tuning :: proc{instrument_get_scale_tuning, preset_get_scale_tuning}
get_exclusive_class :: proc{instrument_get_exclusive_class}
get_root_key :: proc{instrument_get_root_key}
