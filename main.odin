package main

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:testing"
import "core:time"
import "odinysynth"

main :: proc() {
    flourish()
}

simple_chord :: proc() {
    using odinysynth

    // Load the SoundFont.
    sf2, _ := os.open("TimGM6mb.sf2", os.O_RDONLY)
    defer os.close(sf2)
    soundfont, _ := new_soundfont(io.Reader { stream = os.stream_from_handle(sf2) })
    defer destroy(&soundfont)

    // Create the synthesizer.
    settings := new_synthesizer_settings(44100)
    synthesizer, _ := new_synthesizer(&soundfont, &settings)
    defer destroy(&synthesizer)

    // Play some notes (middle C, E, G).
    note_on(&synthesizer, 0, 60, 100)
    note_on(&synthesizer, 0, 64, 100)
    note_on(&synthesizer, 0, 67, 100)

    // The output buffer (3 seconds).
    sample_count := 3 * settings.sample_rate
    left := make([]f32, sample_count)
    defer delete(left)
    right := make([]f32, sample_count)
    defer delete(right)

    // Render the waveform.
    render(&synthesizer, left[:], right[:])

    // Export the waveform as a PCM file.
    write_pcm("simple_chord.pcm", left[:], right[:])
}

flourish :: proc() {
    using odinysynth

    // Load the SoundFont.
    sf2, _ := os.open("TimGM6mb.sf2", os.O_RDONLY)
    defer os.close(sf2)
    soundfont, _ := new_soundfont(io.Reader { stream = os.stream_from_handle(sf2) })
    defer destroy(&soundfont)

    // Create the synthesizer.
    settings := new_synthesizer_settings(44100)
    synthesizer, _ := new_synthesizer(&soundfont, &settings)
    defer destroy(&synthesizer)

    // Load the MIDI file.
    mid, _ := os.open("flourish.mid", os.O_RDONLY)
    defer os.close(mid)
    midi_file, _ := new_midi_file(io.Reader { stream = os.stream_from_handle(mid) })
    defer destroy(&midi_file)

    // Create the sequencer.
    sequencer := new_midi_file_sequencer(&synthesizer)

    // Play the MIDI file.
    play(&sequencer, &midi_file, false)

    // The output buffer.
    sample_count := int(f64(settings.sample_rate) * get_length(&midi_file))
    left := make([]f32, sample_count)
    defer delete(left)
    right := make([]f32, sample_count)
    defer delete(right)

    // Render the waveform.
    stopwatch := time.Stopwatch{}
    time.stopwatch_start(&stopwatch)
    render(&sequencer, left[:], right[:])
    time.stopwatch_stop(&stopwatch)
    duration := time.stopwatch_duration(stopwatch)
    fmt.printf("Time: %v s", time.duration_seconds(duration))

    // Export the waveform as a PCM file.
    write_pcm("flourish.pcm", left[:], right[:])
}

write_pcm :: proc(path: string, left: []f32, right: []f32) {
    length := len(left)

    max_value: f32 = 0
    for i := 0; i < length; i += 1 {
        if abs(left[i]) > max_value {
            max_value = abs(left[i])
        }
        if abs(right[i]) > max_value {
            max_value = abs(right[i])
        }
    }
    a := 0.99 / max_value

    pcm, _ := os.open(path, os.O_CREATE)
    defer os.close(pcm)

    for i := 0; i < length; i += 1 {
        left_i16 := i16(32768.0 * a * left[i])
        right_i16 := i16(32768.0 * a * right[i])
        frame: [4]u8
        frame[0] = u8(left_i16)
        frame[1] = u8(left_i16 >> 8)
        frame[2] = u8(right_i16)
        frame[3] = u8(right_i16 >> 8)
        os.write(pcm, frame[:])
    }
}
