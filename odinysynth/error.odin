package odinysynth

import "core:io"
import "core:runtime"

Error :: union #shared_nil {
    Odinysynth_Error,
    io.Error,
    runtime.Allocator_Error
}

Odinysynth_Error :: enum {
    None = 0,
    Invalid_Soundfont,
    Unexpected,
}
