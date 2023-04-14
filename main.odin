package main

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:testing"
import rl "vendor:raylib"
import "odinysynth"

sample_rate :: 44100
buffer_size :: 4096

main :: proc() {
    using odinysynth

    // Load the SoundFont.
    sf2, _ := os.open("TimGM6mb.sf2", os.O_RDONLY)
    defer os.close(sf2)
    soundfont, _ := new_soundfont(io.Reader { stream = os.stream_from_handle(sf2) })
    defer destroy(&soundfont)

    // Create the synthesizer.
    settings := new_synthesizer_settings(sample_rate)
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

    rl.InitWindow(800, 600, "MIDI file playback")

    rl.InitAudioDevice()
    rl.SetAudioStreamBufferSizeDefault(buffer_size)

    stream := rl.LoadAudioStream(sample_rate, 16, 2)
    buffer := make([]i16, 2 * buffer_size)
    defer delete(buffer)
    left := make([]f32, buffer_size)
    defer delete(left)
    right := make([]f32, buffer_size)
    defer delete(right)

    rl.PlayAudioStream(stream)

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        if rl.IsAudioStreamProcessed(stream) {
            render(&sequencer, left[:], right[:])
            for i := 0; i < buffer_size; i += 1 {
                left_i32 := i32(32768.0 * left[i])
                if left_i32 > i32(max(i16)) {
                    left_i32 = i32(max(i16))
                } else if left_i32 < i32(min(i16)) {
                    left_i32 = i32(min(i16))
                }
                right_i32 := i32(32768.0 * right[i])
                if right_i32 > i32(max(i16)) {
                    right_i32 = i32(max(i16))
                } else if right_i32 < i32(min(i16)) {
                    right_i32 = i32(min(i16))
                }
                buffer[2 * i] = i16(left_i32)
                buffer[2 * i + 1] = i16(right_i32)
            }
            rl.UpdateAudioStream(stream, raw_data(buffer[:]), buffer_size)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.PINK)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
