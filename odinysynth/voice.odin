package odinysynth

import "core:math"

@(private)
Voice :: struct {
    sample_rate: int,
    block_size: int,

    vol_env: Volume_Envelope,
    mod_env: Modulation_Envelope,

    vib_lfo: Lfo,
    mod_lfo: Lfo,

    oscillator: Oscillator,
    filter: Bi_Quad_Filter,

    block: []f32,

    // A sudden change in the mix gain will cause pop noise.
    // To avoid this, we save the mix gain of the previous block,
    // and smooth out the gain if the gap between the current and previous gain is too large.
    // The actual smoothing process is done in the WriteBlock method of the Synthesizer class.

    previous_mix_gain_left: f32,
    previous_mix_gain_right: f32,
    current_mix_gain_left: f32,
    current_mix_gain_right: f32,

    previous_reverb_send: f32,
    previous_chorus_send: f32,
    current_reverb_send: f32,
    current_chorus_send: f32,

    exclusive_class: i32,
    channel: i32,
    key: i32,
    velocity: i32,

    note_gain: f32,

    cutoff: f32,
    resonance: f32,

    vib_lfo_to_pitch: f32,
    mod_lfo_to_pitch: f32,
    mod_env_to_pitch: f32,

    mod_lfo_to_cutoff: i32,
    mod_env_to_cutoff: i32,
    dynamic_cutoff: bool,

    mod_lfo_to_volume: f32,
    dynamic_volume: bool,

    instrument_pan: f32,
    instrument_reverb: f32,
    instrument_chorus: f32,

    // Some instruments require fast cutoff change, which can cause pop noise.
    // This is used to smooth out the cutoff frequency.
    smoothed_cutoff: f32,

    voice_state: Voice_State,
    voice_length: int,
    minimum_voice_length: int,
}

@(private)
new_voice :: proc(settings: ^Synthesizer_Settings, block: []f32) -> Voice {
    result: Voice = {}
    result.sample_rate = settings.sample_rate
    result.block_size = settings.block_size
    result.vol_env = new_volume_envelope(settings)
    result.mod_env = new_modulation_envelope(settings)
    result.vib_lfo = new_lfo(settings)
    result.mod_lfo = new_lfo(settings)
    result.oscillator = new_oscillator(settings)
    result.filter = new_bi_quad_filter(settings)
    result.block = block
    result.minimum_voice_length = settings.sample_rate / 500
    return result
}

@(private)
start_voice :: proc(v: ^Voice, data: []i16, rp: ^Region_Pair, channel: i32, key: i32, velocity: i32) {
    v.exclusive_class = region_pair_get_exclusive_class(rp)
    v.channel = channel
    v.key = key
    v.velocity = velocity

    if velocity > 0 {
        // According to the Polyphone's implementation, the initial attenuation should be reduced to 40%.
        // I'm not sure why, but this indeed improves the loudness variability.
        sample_attenuation := 0.4 * region_pair_get_initial_attenuation(rp)
        filter_attenuation := 0.5 * region_pair_get_initial_filter_q(rp)
        decibels := 2.0 * linear_to_decibels(f32(velocity) / 127.0) - sample_attenuation - filter_attenuation
        v.note_gain = decibels_to_linear(decibels)
    } else {
        v.note_gain = 0.0
    }

    v.cutoff = region_pair_get_initial_filter_cutoff_frequency(rp)
    v.resonance = decibels_to_linear(region_pair_get_initial_filter_q(rp))

    v.vib_lfo_to_pitch = 0.01 * f32(region_pair_get_vibrato_lfo_to_pitch(rp))
    v.mod_lfo_to_pitch = 0.01 * f32(region_pair_get_modulation_lfo_to_pitch(rp))
    v.mod_env_to_pitch = 0.01 * f32(region_pair_get_modulation_envelope_to_pitch(rp))

    v.mod_lfo_to_cutoff = region_pair_get_modulation_lfo_to_filter_cutoff_frequency(rp)
    v.mod_env_to_cutoff = region_pair_get_modulation_envelope_to_filter_cutoff_frequency(rp)
    v.dynamic_cutoff = v.mod_lfo_to_cutoff != 0 || v.mod_env_to_cutoff != 0

    v.mod_lfo_to_volume = region_pair_get_modulation_lfo_to_volume(rp)
    v.dynamic_volume = v.mod_lfo_to_volume > 0.05

    v.instrument_pan = clamp(region_pair_get_pan(rp), -50.0, 50.0)
    v.instrument_reverb = 0.01 * region_pair_get_reverb_effects_send(rp)
    v.instrument_chorus = 0.01 * region_pair_get_chorus_effects_send(rp)

    region_pair_start_volume_envelope(rp, &v.vol_env, key)
    region_pair_start_modulation_envelope(rp, &v.mod_env, key, velocity)
    region_pair_start_vibrato(rp, &v.vib_lfo)
    region_pair_start_modulation(rp, &v.mod_lfo)
    region_pair_start_oscillator(rp, &v.oscillator, data)
    clear_bi_quad_filter(&v.filter)
    set_low_pass_filter(&v.filter, v.cutoff, v.resonance)

    v.smoothed_cutoff = v.cutoff

    v.voice_state = Voice_State.Playing
    v.voice_length = 0
}

end_voice :: proc(v: ^Voice) {
    if v.voice_state == Voice_State.Playing {
        v.voice_state = Voice_State.Release_Requested
    }
}

kill_voice :: proc(v: ^Voice) {
    v.note_gain = 0.0
}

@(private)
process_voice :: proc(v: ^Voice, channel_infos: []Channel) -> bool {
    if v.note_gain < NON_AUDIBLE {
        return false
    }

    channel_info := &channel_infos[int(v.channel)]

    release_voice_if_necessary(v, channel_info)

    if !process_volume_envelope(&v.vol_env, v.block_size) {
        return false
    }

    process_modulation_envelope(&v.mod_env, v.block_size)
    process_lfo(&v.vib_lfo)
    process_lfo(&v.mod_lfo)

    vib_pitch_change := (0.01 * channel_get_modulation(channel_info) + v.vib_lfo_to_pitch) * v.vib_lfo.value
    mod_pitch_change := v.mod_lfo_to_pitch * v.mod_lfo.value + v.mod_env_to_pitch * v.mod_env.value
    channel_pitch_change := channel_get_tune(channel_info) + channel_get_pitch_bend(channel_info)
    pitch := f32(v.key) + vib_pitch_change + mod_pitch_change + channel_pitch_change
    if !process_oscillator(&v.oscillator, v.block, pitch) {
        return false
    }

    if v.dynamic_cutoff {
        cents := f32(v.mod_lfo_to_cutoff) * v.mod_lfo.value + f32(v.mod_env_to_cutoff) * v.mod_env.value
        factor := cents_to_multiplying_factor(cents)
        new_cutoff := factor * v.cutoff

        // The cutoff change is limited within x0.5 and x2 to reduce pop noise.
        lower_limit := 0.5 * v.smoothed_cutoff
        upper_limit := 2.0 * v.smoothed_cutoff
        v.smoothed_cutoff = clamp(new_cutoff, lower_limit, upper_limit)

        set_low_pass_filter(&v.filter, v.smoothed_cutoff, v.resonance)
    }
    process_bi_quad_filter(&v.filter, v.block)

    v.previous_mix_gain_left = v.current_mix_gain_left
    v.previous_mix_gain_right = v.current_mix_gain_right
    v.previous_reverb_send = v.current_reverb_send
    v.previous_chorus_send = v.current_chorus_send

    // According to the GM spec, the following value should be squared.
    ve := channel_get_volume(channel_info) * channel_get_expression(channel_info)
    channel_gain := ve * ve

    mix_gain := v.note_gain * channel_gain * v.vol_env.value
    if v.dynamic_volume {
        decibels := v.mod_lfo_to_volume * v.mod_lfo.value
        mix_gain *= decibels_to_linear(decibels)
    }

    angle := (math.PI / 200.0) * (channel_get_pan(channel_info) + v.instrument_pan + 50.0)
    if angle <= 0.0 {
        v.current_mix_gain_left = mix_gain
        v.current_mix_gain_right = 0.0
    } else if (angle >= HALF_PI) {
        v.current_mix_gain_left = 0.0
        v.current_mix_gain_right = mix_gain
    } else {
        v.current_mix_gain_left = mix_gain * math.cos_f32(angle)
        v.current_mix_gain_right = mix_gain * math.sin_f32(angle)
    }

    v.current_reverb_send = clamp(channel_get_reverb_send(channel_info) + v.instrument_reverb, 0.0, 1.0)
    v.current_chorus_send = clamp(channel_get_chorus_send(channel_info) + v.instrument_chorus, 0.0, 1.0)

    if v.voice_length == 0 {
        v.previous_mix_gain_left = v.current_mix_gain_left
        v.previous_mix_gain_right = v.current_mix_gain_right
        v.previous_reverb_send = v.current_reverb_send
        v.previous_chorus_send = v.current_chorus_send
    }

    v.voice_length += v.block_size

    return true
}

@(private)
release_voice_if_necessary :: proc(v: ^Voice, channel_info: ^Channel) {
    if v.voice_length < v.minimum_voice_length {
        return
    }

    if v.voice_state == Voice_State.Release_Requested && !channel_info.hold_pedal {
        release_volume_envelope(&v.vol_env)
        release_modulation_envelope(&v.mod_env)
        release_oscillator(&v.oscillator)

        v.voice_state = Voice_State.Released
    }
}

@(private)
get_voice_priproty :: proc(v: ^Voice) -> f32 {
    if v.note_gain < NON_AUDIBLE {
        return 0.0
    } else {
        return v.vol_env.priority
    }
}
