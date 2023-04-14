package main

import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:testing"
import rl "vendor:raylib"
import "odinysynth"

main :: proc() {
    rl.InitWindow(800, 600, "MIDI file playback")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.PINK)
        rl.EndDrawing()
    }
}
