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
