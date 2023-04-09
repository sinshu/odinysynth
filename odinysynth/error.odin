package odinysynth

import "core:io"

Error :: union #shared_nil {
    OdinySynth_Error,
    io.Error,
}

OdinySynth_Error :: enum {
    None = 0,
    Invalid_SoundFont,
}
