package main

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:strings"
import "core:testing"
import rl "vendor:raylib"
import "odinysynth"

sample_rate :: 44100
buffer_size :: 4096

main :: proc() {
    using odinysynth

    // Load the SoundFont.
    soundfont, _ := new_soundfont("TimGM6mb.sf2")
    defer destroy(&soundfont)

    // Create the synthesizer.
    settings := new_synthesizer_settings(sample_rate)
    synthesizer, _ := new_synthesizer(&soundfont, &settings)
    defer destroy(&synthesizer)

    // Load the MIDI file.
    midi_file, _ := new_midi_file("flourish.mid")
    defer destroy(&midi_file)

    // Create the sequencer.
    sequencer := new_midi_file_sequencer(&synthesizer)

    // Play the MIDI file.
    play(&sequencer, &midi_file, false)

    rl.InitWindow(1024, 768, "MIDI file playback")

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

    speed := 100

    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(rl.KeyboardKey.UP) {
            speed += 10
        }
        if rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
            speed -= 10
        }
        if speed < 0 {
            speed = 0
        }
        if speed > 1000 {
            speed = 1000
        }

        speed_f64 := f64(speed) / 100

        sequencer.speed = speed_f64

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
        rl.ClearBackground(rl.LIGHTGRAY)

        rl.DrawText("MIDI music playback with Odin + raylib!", 20, 20, 50, rl.DARKGRAY)
        str := fmt.ctprintf("%.1f", speed_f64)
        rl.DrawText("Playback speed:", 20, 700, 50, rl.Color{r=128,a=255})
        rl.DrawText(str, 460, 670, 90, rl.Color{r=128,a=255})

        for i := 0; i < buffer_size / 4; i += 1 {
            offset := 4 * i
            top := left[offset]
            top = max(left[offset + 1], top)
            top = max(left[offset + 2], top)
            top = max(left[offset + 3], top)
            btm := left[offset]
            btm = min(left[offset + 1], btm)
            btm = min(left[offset + 2], btm)
            btm = min(left[offset + 3], btm)
            x := i32(i)
            y1 := i32(384 - 300 * top) - 5
            y2 := i32(384 - 300 * btm) + 5
            rl.DrawRectangle(x, y1, 3, y2 - y1, rl.DARKGRAY)
        }
        
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
