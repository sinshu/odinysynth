package odinysynth

import "core:io"

Error :: union #shared_nil {
    Odinysynth_Error,
    io.Error,
}

Odinysynth_Error :: enum {
    None = 0,
    Invalid_Soundfont,
    Unexpected,
}
