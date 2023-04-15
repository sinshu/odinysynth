package odinysynth

import "core:io"
import "core:runtime"

Error :: union #shared_nil {
    Odinysynth_Error,
    io.Error,
    runtime.Allocator_Error,
}

Odinysynth_Error :: enum {
    None = 0,
    Invalid_Soundfont,
    Invalid_Midi_File,
    Sample_Rate_Is_Out_Of_Range,
    Block_Size_Is_Out_Of_Range,
    Maximum_Polyphony_Is_Out_Of_Range,
    Unexpected,
    File_IO_Error,
}
