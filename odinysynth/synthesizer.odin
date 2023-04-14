package odinysynth

CHANNEL_COUNT :: 16
PERCUSSION_CHANNEL :: 9

Synthesizer :: struct {
    soundfont: ^Soundfont,
    sample_rate: int,
    block_size: int,
    maximum_polyphony: int,
    enable_reverb_and_chorus: bool,

    minimum_voice_length: int,

    preset_lookup: map[i32]^Preset,
    default_preset: ^Preset,

    channels: []Channel,

    voices: Voice_Collection,

    block_left: []f32,
    block_right: []f32,

    inverse_block_size: f32,

    block_read: int,

    master_volume: f32,
}

new_synthesizer :: proc(soundfont: ^Soundfont, settings: ^Synthesizer_Settings) -> (Synthesizer, Error) {
    preset_lookup: map[i32]^Preset = nil
    channels: []Channel = nil
    voices: Voice_Collection = {}
    block_left: []f32 = nil
    block_right: []f32 = nil
    err: Error = nil

    defer {
        if err != nil {
            if preset_lookup != nil {
                delete(preset_lookup)
            }
            if channels != nil {
                delete(channels)
            }
            if voices.block_buffer != nil {
                destroy_voice_collection(&voices)
            }
            if block_left != nil {
                delete(block_left)
            }
            if block_right != nil {
                delete(block_right)
            }
        }
    }

    //try settings.validate()
    err = validate_settings(settings)
    if err != nil {
        return {}, err
    }

    minimum_voice_length := settings.sample_rate / 500

    preset_lookup, err = make(map[i32]^Preset)
    if err != nil {
        return {}, err
    }

    min_preset_id: i32 = max(i32)
    default_preset: ^Preset = nil
    for i := 0; i < len(soundfont.presets); i += 1 {
        preset := &soundfont.presets[i]

        // The preset ID is Int32, where the upper 16 bits represent the bank number
        // and the lower 16 bits represent the patch number.
        // This ID is used to search for presets by the combination of bank number
        // and patch number.
        preset_id := (preset.bank_number << 16) | preset.patch_number
        preset_lookup[preset_id] = preset

        // The preset with the minimum ID number will be default.
        // If the SoundFont is GM compatible, the piano will be chosen.
        if preset_id < min_preset_id {
            default_preset = preset
            min_preset_id = preset_id
        }
    }

    channels, err = make([]Channel, CHANNEL_COUNT)
    if err != nil {
        return {}, err
    }
    for i := 0; i < len(channels); i += 1 {
        channels[i] = new_channel(i == PERCUSSION_CHANNEL)
    }

    voices, err = new_voice_collection(settings)
    if err != nil {
        return {}, err
    }

    block_left = make([]f32, settings.block_size)
    if err != nil {
        return {}, err
    }

    block_right = make([]f32, settings.block_size)
    if err != nil {
        return {}, err
    }

    inverse_block_size := 1.0 / f32(settings.block_size)

    block_read := settings.block_size

    master_volume: f32 = 0.5

    result: Synthesizer = {}
    result.soundfont = soundfont
    result.sample_rate = settings.sample_rate
    result.block_size = settings.block_size
    result.maximum_polyphony = settings.maximum_polyphony
    result.enable_reverb_and_chorus = settings.enable_reverb_and_chorus
    result.minimum_voice_length = minimum_voice_length
    result.preset_lookup = preset_lookup
    result.default_preset = default_preset
    result.channels = channels
    result.voices = voices
    result.block_left = block_left
    result.block_right = block_right
    result.inverse_block_size = inverse_block_size
    result.block_read = block_read
    result.master_volume = master_volume
    return result, nil
}

destroy_synthesizer :: proc(s: ^Synthesizer) {
    delete(s.preset_lookup)
    delete(s.channels)
    destroy_voice_collection(&s.voices)
    delete(s.block_left)
    delete(s.block_right)
}

process_midi_message :: proc(s: ^Synthesizer, channel: i32, command: i32, data1: i32, data2: i32) {
    if !(0 <= channel && int(channel) < len(s.channels)) {
        return
    }

    channel_info := &s.channels[channel]

    switch command {
    case 0x80: // Note Off
        note_off(s, channel, data1)

    case 0x90: // Note On
        note_on(s, channel, data1, data2)

    case 0xB0: // Controller
        switch data1 {
        case 0x00: // Bank Selection
            channel_set_bank(channel_info, data2)

        case 0x01: // Modulation Coarse
            channel_set_modulation_coarse(channel_info, data2)

        case 0x21: // Modulation Fine
            channel_set_modulation_fine(channel_info, data2)

        case 0x06: // Data Entry Coarse
            channel_data_entry_coarse(channel_info, data2)

        case 0x26: // Data Entry Fine
            channel_data_entry_fine(channel_info, data2)

        case 0x07: // Channel Volume Coarse
            channel_set_volume_coarse(channel_info, data2)

        case 0x27: // Channel Volume Fine
            channel_set_volume_fine(channel_info, data2)

        case 0x0A: // Pan Coarse
            channel_set_pan_coarse(channel_info, data2)

        case 0x2A: // Pan Fine
            channel_set_pan_fine(channel_info, data2)

        case 0x0B: // Expression Coarse
            channel_set_expression_coarse(channel_info, data2)

        case 0x2B: // Expression Fine
            channel_set_expression_fine(channel_info, data2)

        case 0x40: // Hold Pedal
            channel_set_hold_pedal(channel_info, data2)

        case 0x5B: // Reverb Send
            channel_set_reverb_send(channel_info, data2)

        case 0x5D: // Chorus Send
            channel_set_chorus_send(channel_info, data2)

        case 0x65: // RPN Coarse
            channel_set_rpn_coarse(channel_info, data2)

        case 0x64: // RPN Fine
            channel_set_rpn_fine(channel_info, data2)

        case 0x78: // All Sound Off
            note_off_all_channel(s, channel, true)

        case 0x79: // Reset All Controllers
            reset_all_controllers_channel(s, channel)

        case 0x7B: // All Note Off
            note_off_all_channel(s, channel, false)
        }

    case 0xC0: // Program Change
        channel_set_patch(channel_info, data1)

    case 0xE0: // Pitch Bend
        channel_set_pitch_bend(channel_info, data1, data2)
    }
}

note_off :: proc(s: ^Synthesizer, channel: i32, key: i32) {
    if !(0 <= channel && int(channel) < len(s.channels)) {
        return
    }

    for i := 0; i < s.voices.active_voice_count; i += 1 {
        voice := &s.voices.voices[i]
        if voice.channel == channel && voice.key == key {
            end_voice(voice)
        }
    }
}

note_on :: proc(s: ^Synthesizer, channel: i32, key: i32, velocity: i32) {
    if velocity == 0 {
        note_off(s, channel, key)
        return
    }

    if !(0 <= channel && int(channel) < len(s.channels)) {
        return
    }

    channel_info := &s.channels[channel]
    preset_id := (channel_info.bank_number << 16) | channel_info.patch_number

    preset, found := s.preset_lookup[preset_id]
    if !found {
        // Try fallback to the GM sound set.
        // Normally, the given patch number + the bank number 0 will work.
        // For drums (bank number >= 128), it seems to be better to select the standard set (128:0).
        gm_preset_id: i32
        if channel_info.bank_number < 128 {
            gm_preset_id = channel_info.patch_number
        } else {
            gm_preset_id = 128 << 16
        }

        preset, found = s.preset_lookup[gm_preset_id]
        if !found {
            // No corresponding preset was found. Use the default one...
            preset = s.default_preset
        }
    }

    preset_count := len(preset.regions)
    for i := 0; i < preset_count; i += 1 {
        preset_region := &preset.regions[i]
        if preset_contains(preset_region, key, velocity) {
            instrument_count := len(preset_region.instrument.regions)
            for j := 0; j < instrument_count; j += 1 {
                instrument_region := &preset_region.instrument.regions[j]
                if instrument_contains(instrument_region, key, velocity) {
                    region_pair := new_region_pair(preset_region, instrument_region)

                    voice := request_new_voice(&s.voices, instrument_region, channel)
                    if voice != nil {
                        start_voice(voice, s.soundfont.wave_data, &region_pair, channel, key, velocity)
                    }
                }
            }
        }
    }
}

note_off_all :: proc(s: ^Synthesizer, immediate: bool) {
    if immediate {
        clear_voice_collection(&s.voices)
    } else {
        for i := 0; i < s.voices.active_voice_count; i += 1 {
            end_voice(&s.voices.voices[i])
        }
    }
}

note_off_all_channel :: proc(s: ^Synthesizer, channel: i32, immediate: bool) {
    if immediate {
        for i := 0; i < s.voices.active_voice_count; i += 1 {
            if s.voices.voices[i].channel == channel {
                kill_voice(&s.voices.voices[i])
            }
        }
    } else {
        for i := 0; i < s.voices.active_voice_count; i += 1 {
            if s.voices.voices[i].channel == channel {
                end_voice(&s.voices.voices[i])
            }
        }
    }
}

reset_all_controllers :: proc(s: ^Synthesizer) {
    channel_count := len(s.channels)
    for i := 0; i < channel_count; i += 1 {
        channel_reset_all_controllers(&s.channels[i])
    }
}

reset_all_controllers_channel :: proc(s: ^Synthesizer, channel: i32) {
    if !(0 <= channel && int(channel) < len(s.channels)) {
        return
    }

    channel_reset_all_controllers(&s.channels[channel])
}

reset :: proc(s: ^Synthesizer) {
    clear_voice_collection(&s.voices)

    channel_count := len(s.channels)
    for i := 0; i < channel_count; i += 1 {
        channel_reset(&s.channels[i])
    }

    /*
    if s.EnableReverbAndChorus {
        s.reverb.mute()
        s.chorus.mute()
    }
    */

    s.block_read = s.block_size
}

synthesizer_render :: proc(s: ^Synthesizer, left: []f32, right: []f32) {
    wrote := 0
    length := len(left)
    for wrote < length {
        if s.block_read == s.block_size {
            synthesizer_render_block(s)
            s.block_read = 0
        }

        src_rem := s.block_size - s.block_read
        dst_rem := length - wrote
        rem := min(src_rem, dst_rem)

        for i := 0; i < rem; i += 1 {
            left[wrote + i] = s.block_left[s.block_read + i]
            right[wrote + i] = s.block_right[s.block_read + i]
        }

        s.block_read += rem
        wrote += rem
    }
}

@(private)
synthesizer_render_block :: proc(s: ^Synthesizer) {
    block_size := s.block_size
    active_voice_count := s.voices.active_voice_count

    process_voice_collection(&s.voices, s.channels)

    for i := 0; i < block_size; i += 1 {
        s.block_left[i] = 0
        s.block_right[i] = 0
    }

    for i := 0; i < active_voice_count; i += 1 {
        voice := s.voices.voices[i]
        previous_gain_left := s.master_volume * voice.previous_mix_gain_left
        current_gain_left := s.master_volume * voice.current_mix_gain_left
        synthesizer_write_block(s, previous_gain_left, current_gain_left, voice.block, s.block_left)
        previous_gain_right := s.master_volume * voice.previous_mix_gain_right
        current_gain_right := s.master_volume * voice.current_mix_gain_right
        synthesizer_write_block(s, previous_gain_right, current_gain_right, voice.block, s.block_right)
    }
}

@(private)
synthesizer_write_block :: proc(s: ^Synthesizer, previous_gain: f32, current_gain: f32, source: []f32, destination: []f32) {
    if max(previous_gain, current_gain) < NON_AUDIBLE {
        return
    }

    if abs(current_gain - previous_gain) < 1.0e-3 {
        array_multiply_add(current_gain, source, destination)
    } else {
        step := s.inverse_block_size * (current_gain - previous_gain)
        array_multiply_add_slope(previous_gain, step, source, destination)
    }
}
