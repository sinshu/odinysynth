package odinysynth

import "core:io"

@(private)
MSG_NORMAL :: 0

@(private)
MSG_TEMPO_CHANGE :: 252

@(private)
MSG_END_OF_TRACK :: 255

@(private)
MAX_TRACK_COUNT :: 32

@(private)
Message :: struct {
    channel: u8,
    command: u8,
    data1: u8,
    data2: u8,
}

Midi_File :: struct {
    messages: [dynamic]Message
    times: [dynamic]f64
}

@(private)
common1 :: proc(status: u8, data1: u8) -> Message {
    result: Message = {}
    result.channel = status & 0x0F
    result.command = status & 0xF0
    result.data1 = data1
    result.data2 = 0
    return result
}

@(private)
common2 :: proc(status: u8, data1: u8, data2: u8) -> Message {
    result: Message = {}
    result.channel = status & 0x0F
    result.command = status & 0xF0
    result.data1 = data1
    result.data2 = data2
    return result
}

@(private)
tempo_change :: proc(tempo: i32) -> Message {
    result: Message = {}
    result.channel = MSG_TEMPO_CHANGE
    result.command = u8(tempo >> 16)
    result.data1 = u8(tempo >> 8)
    result.data2 = u8(tempo)
    return result
}

@(private)
end_of_track :: proc() -> Message {
    result: Message = {}
    result.channel = MSG_END_OF_TRACK
    return result
}

@(private)
get_message_type :: proc(m: ^Message) -> u8 {
    switch m.channel {
    case MSG_TEMPO_CHANGE:
        return MSG_TEMPO_CHANGE
    case MSG_END_OF_TRACK:
        return MSG_END_OF_TRACK
    case:
        return MSG_NORMAL
    }
}

@(private)
get_tempo :: proc(m: ^Message) -> f64 {
    return 60000000.0 / f64((i32(m.command) << 16) | (i32(m.data1) << 8) | i32(m.data2))
}

new_midi_file :: proc(r: io.Reader) -> (Midi_File, Error) {
    message_lists: [MAX_TRACK_COUNT][dynamic]Message = {}
    tick_lists: [MAX_TRACK_COUNT][dynamic]i32 = {}
    err: Error = nil

    defer {
        for i := 0; i < MAX_TRACK_COUNT; i += 1 {
            if message_lists[i] != nil {
                delete(message_lists[i])
            }
            if tick_lists[i] != nil {
                delete(tick_lists[i])
            }
        }
    }

    chunk_type: [4]u8
    chunk_type, err = read_four_cc(r)
    if err != nil {
        return {}, err
    }
    if chunk_type != "MThd" {
        err = Odinysynth_Error.Invalid_Midi_File
        return {}, err
    }

    size: i32
    size, err = read_i32_big_endian(r)
    if err != nil {
        return {}, err
    }
    if size != 6 {
        err = Odinysynth_Error.Invalid_Midi_File
        return {}, err
    }

    format: i16
    format, err = read_i16_big_endian(r)
    if err != nil {
        return {}, err
    }
    if !(format == 0 || format == 1) {
        err = Odinysynth_Error.Invalid_Midi_File
        return {}, err
    }

    track_count: i16
    track_count, err = read_i16_big_endian(r)
    if err != nil {
        return {}, err
    }

    resolution: i16
    resolution, err = read_i16_big_endian(r)
    if err != nil {
        return {}, err
    }

    for i := 0; i < int(track_count); i += 1 {
        message_list: [dynamic]Message
        tick_list: [dynamic]i32
        message_list, tick_list, err = read_track(r)
        if err != nil {
            return {}, err
        }
        message_lists[i] = message_list
        tick_lists[i] = tick_list
    }

    messages: [dynamic]Message
    times: [dynamic]f64
    messages, times, err = merge_tracks(message_lists[0:track_count], tick_lists[0:track_count], resolution)
    if err != nil {
        return {}, err
    }

    result: Midi_File
    result.messages = messages
    result.times = times
    return result, nil
}

@(private)
read_track :: proc(r: io.Reader) -> ([dynamic]Message, [dynamic]i32, Error) {
    messages: [dynamic]Message = nil
    ticks: [dynamic]i32 = nil
    err: Error = nil

    defer {
        if err != nil {
            if messages != nil {
                delete(messages)
            }
            if ticks != nil {
                delete(ticks)
            }
        }
    }

    chunk_type: [4]u8
    chunk_type, err = read_four_cc(r)
    if err != nil {
        return nil, nil, err
    }
    if chunk_type != "MTrk" {
        err = Odinysynth_Error.Invalid_Midi_File
        return nil, nil, err
    }

    _, err = read_i32_big_endian(r)
    if err != nil {
        return nil, nil, err
    }

    messages, err = make([dynamic]Message, 0, 300)
    if err != nil {
        return nil, nil, err
    }

    ticks, err = make([dynamic]i32, 0, 300)
    if err != nil {
        return nil, nil, err
    }

    tick: i32 = 0
    last_status: u8 = 0

    for {
        delta: i32
        delta, err = read_int_variable_length(r)
        if err != nil {
            return nil, nil, err
        }

        first: u8
        first, err = read_u8(r)
        if err != nil {
            return nil, nil, err
        }

        tick += delta

        if (first & 128) == 0 {
            command := last_status & 0xF0
            if command == 0xC0 || command == 0xD0 {
                append(&messages, common1(last_status, first))
                append(&ticks, tick)
            } else {
                data2: u8
                data2, err = read_u8(r)
                if err != nil {
                    return nil, nil, err
                }
                append(&messages, common2(last_status, first, data2))
                append(&ticks, tick)
            }

            continue
        }

        switch first {
        case 0xF0: // System Exclusive
            err = discard_midi_data(r)
            if err != nil {
                return nil, nil, err
            }

        case 0xF7: // System Exclusive
            err = discard_midi_data(r)
            if err != nil {
                return nil, nil, err
            }

        case 0xFF: // Meta Event
            meta_event: u8
            meta_event, err = read_u8(r)
            if err != nil {
                return nil, nil, err
            }
            switch meta_event {
            case 0x2F: // End of Track
                _, err = read_u8(r)
                if err != nil {
                    return nil, nil, err
                }
                append(&messages, end_of_track())
                append(&ticks, tick)
                return messages, ticks, nil

            case 0x51: // Tempo
                tempo: i32
                tempo, err = read_tempo(r)
                if err != nil {
                    return nil, nil, err
                }
                append(&messages, tempo_change(tempo))
                append(&ticks, tick)

            case:
                err = discard_midi_data(r)
                if err != nil {
                    return nil, nil, err
                }
            }

        case:
            command := first & 0xF0
            if command == 0xC0 || command == 0xD0 {
                data1: u8
                data1, err = read_u8(r)
                if err != nil {
                    return nil, nil, err
                }
                append(&messages, common1(first, data1))
                append(&ticks, tick)
            } else {
                data1: u8
                data1, err = read_u8(r)
                if err != nil {
                    return nil, nil, err
                }
                data2: u8
                data2, err = read_u8(r)
                if err != nil {
                    return nil, nil, err
                }
                append(&messages, common2(first, data1, data2))
                append(&ticks, tick)
            }
        }

        last_status = first
    }
}

@(private)
merge_tracks :: proc(message_lists: [][dynamic]Message, tick_lists: [][dynamic]i32, resolution: i16) -> ([dynamic]Message, [dynamic]f64, Error) {
    merged_messages: [dynamic]Message = nil
    merged_times: [dynamic]f64 = nil
    indices: []int = nil
    err: Error = nil

    defer {
        if err != nil {
            if merged_messages != nil {
                delete(merged_messages)
            }
            if merged_times != nil {
                delete(merged_times)
            }
        }

        if indices != nil {
            delete(indices)
        }
    }

    merged_messages, err = make([dynamic]Message, 0, 1000)
    if err != nil {
        return nil, nil, err
    }

    merged_times, err = make([dynamic]f64, 0, 1000)
    if err != nil {
        return nil, nil, err
    }

    indices, err = make([]int, len(message_lists))
    if err != nil {
        return nil, nil, err
    }

    current_tick: i32 = 0
    current_time: f64 = 0

    tempo: f64 = 120

    for {
        min_tick := max(i32)
        min_index := -1
        tick_lists_length := len(tick_lists)
        for ch := 0; ch < tick_lists_length; ch += 1 {
            if indices[ch] < len(tick_lists[ch]) {
                tick := tick_lists[ch][indices[ch]]
                if tick < min_tick {
                    min_tick = tick
                    min_index = ch
                }
            }
        }

        if min_index == -1 {
            break
        }

        next_tick := tick_lists[min_index][indices[min_index]]
        delta_tick := next_tick - current_tick
        delta_time := 60.0 / (f64(resolution) * tempo) * f64(delta_tick)

        current_tick += delta_tick
        current_time += delta_time

        message := message_lists[min_index][indices[min_index]]
        if get_message_type(&message) == MSG_TEMPO_CHANGE {
            tempo = get_tempo(&message)
        } else {
            append(&merged_messages, message)
            append(&merged_times, current_time)
        }

        indices[min_index] += 1
    }

    return merged_messages, merged_times, nil
}

@(private)
discard_midi_data :: proc(r: io.Reader) -> Error {
    err: Error = nil

    size: i32
    size, err = read_int_variable_length(r)
    if err != nil {
        return err
    }

    err = discard_data(r, int(size))
    if err != nil {
        return err
    }

    return nil
}

@(private)
read_tempo :: proc(r: io.Reader) -> (i32, Error) {
    err: Error = nil

    size: i32
    size, err = read_int_variable_length(r)
    if err != nil {
        return 0, err
    }
    if size != 3 {
        err = Odinysynth_Error.Invalid_Midi_File
        return 0, err
    }

    bs: [3]u8
    _, err = io.read_full(r, bs[:])
    if err != nil {
        return 0, err
    }

    b1 := bs[0]
    b2 := bs[1]
    b3 := bs[2]
    return (i32(b1) << 16) | (i32(b2) << 8) | i32(b3), nil
}
