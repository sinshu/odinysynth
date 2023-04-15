package odinysynth

Midi_File_Sequencer :: struct {
    synthesizer: ^Synthesizer,

    midi_file: ^Midi_File,
    loop: bool,

    block_wrote: int,

    current_time: f64,
    msg_index: int,

    speed: f64
}

new_midi_file_sequencer :: proc(synthesizer: ^Synthesizer) -> Midi_File_Sequencer {
    result: Midi_File_Sequencer = {}
    result.synthesizer = synthesizer
    result.speed = 1
    return result
}

play :: proc(seq: ^Midi_File_Sequencer, midi_file: ^Midi_File, loop: bool) {
    seq.midi_file = midi_file
    seq.loop = loop

    seq.block_wrote = seq.synthesizer.block_size

    seq.current_time = 0
    seq.msg_index = 0

    reset(seq.synthesizer)
}

stop :: proc(seq: ^Midi_File_Sequencer) {
    seq.midi_file = nil
    reset(seq.synthesizer)
}

sequencer_render :: proc(seq: ^Midi_File_Sequencer, left: []f32, right: []f32) {
    wrote: int = 0
    length := len(left)
    for wrote < length {
        if seq.block_wrote == seq.synthesizer.block_size {
            process_events(seq)
            seq.block_wrote = 0
            seq.current_time += seq.speed * f64(seq.synthesizer.block_size) / f64(seq.synthesizer.sample_rate)
        }

        src_rem := seq.synthesizer.block_size - seq.block_wrote
        dst_rem := length - wrote
        rem := min(src_rem, dst_rem)

        synthesizer_render(seq.synthesizer, left[wrote : wrote + rem], right[wrote : wrote + rem])

        seq.block_wrote += rem
        wrote += rem
    }
}

@(private)
process_events :: proc(seq: ^Midi_File_Sequencer) {
    if seq.midi_file == nil {
        return
    }

    msg_length := len(seq.midi_file.messages)
    for seq.msg_index < msg_length {
        time := seq.midi_file.times[seq.msg_index]
        msg := seq.midi_file.messages[seq.msg_index]
        if time <= seq.current_time {
            if get_message_type(&msg) == MSG_NORMAL {
                process_midi_message(seq.synthesizer, i32(msg.channel), i32(msg.command), i32(msg.data1), i32(msg.data2))
            }
            seq.msg_index += 1
        } else {
            break
        }
    }

    if seq.msg_index == msg_length && seq.loop {
        seq.current_time = 0
        seq.msg_index = 0
        note_off_all(seq.synthesizer, false)
    }
}
