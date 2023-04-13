package odinysynth

@(private)
Voice_Collection :: struct {
    block_buffer: []f32,
    voices: []Voice,
    active_voice_count: int,
}

@(private)
new_voice_collection :: proc(settings: ^Synthesizer_Settings) -> (Voice_Collection, Error) {
    block_buffer: []f32 = nil
    voices: []Voice = nil
    err: Error = nil

    defer {
        if err != nil {
            if block_buffer != nil {
                delete(block_buffer)
            }
            if voices != nil {
                delete(voices)
            }
        }
    }

    block_buffer, err = make([]f32, settings.block_size * settings.maximum_polyphony)
    if err != nil {
        return {}, err
    }

    voices = make([]Voice, settings.maximum_polyphony)
    if err != nil {
        return {}, err
    }

    for i := 0; i < len(voices); i += 1 {
        buffer_start := settings.block_size * i
        buffer_end := buffer_start + settings.block_size
        block := block_buffer[buffer_start:buffer_end]
        voices[i] = new_voice(settings, block)
    }

    result: Voice_Collection = {}
    result.block_buffer = block_buffer
    result.voices = voices
    result.active_voice_count = 0
    return result, nil
}

@(private)
destroy_voice_collection :: proc(vc: ^Voice_Collection) {
    delete(vc.block_buffer)
    delete(vc.voices)
}

@(private)
request_new_voice :: proc(vc: ^Voice_Collection, region: ^Instrument_Region, channel: i32) -> ^Voice {
    // If an exclusive class is assigned to the region, find a voice with the same class.
    // If found, reuse it to avoid playing multiple voices with the same class at a time.
    exclusive_class := instrument_get_exclusive_class(region)
    if exclusive_class != 0 {
        for i := 0; i < vc.active_voice_count; i += 1 {
            voice := &vc.voices[i]
            if voice.exclusive_class == exclusive_class && voice.channel == channel {
                return voice
            }
        }
    }

    // If the number of active voices is less than the limit, use a free one.
    if vc.active_voice_count < len(vc.voices) {
        free := &vc.voices[vc.active_voice_count]
        vc.active_voice_count += 1
        return free
    }

    // Too many active voices...
    // Find one which has the lowest priority.
    candidate: ^Voice = nil
    lowest_priority: f32 = 1000000.0
    for i := 0; i < vc.active_voice_count; i += 1 {
        voice := &vc.voices[i]
        priority := get_voice_priproty(voice)
        if priority < lowest_priority {
            lowest_priority = priority
            candidate = voice
        } else if priority == lowest_priority {
            // Same priority...
            // The older one should be more suitable for reuse.
            if voice.voice_length > candidate.voice_length {
                candidate = voice
            }
        }
    }
    return candidate
}

@(private)
process_voice_collection :: proc(vc: ^Voice_Collection, channels: []Channel) {
    i: int = 0
    for {
        if i == vc.active_voice_count {
            return
        }

        if process_voice(&vc.voices[i], channels) {
            i += 1
        } else {
            vc.active_voice_count -= 1

            tmp := vc.voices[i]
            vc.voices[i] = vc.voices[vc.active_voice_count]
            vc.voices[vc.active_voice_count] = tmp
        }
    }
}

@(private)
clear_voice_collection :: proc(vc: ^Voice_Collection) {
    vc.active_voice_count = 0
}
