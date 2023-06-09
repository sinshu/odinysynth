package odinysynth

Synthesizer_Settings :: struct {
    sample_rate: int,
    block_size: int,
    maximum_polyphony: int,
    enable_reverb_and_chorus: bool,
}

new_synthesizer_settings :: proc(sample_rate: int) -> Synthesizer_Settings {
    result: Synthesizer_Settings = {}
    result.sample_rate = sample_rate
    result.block_size = 64
    result.maximum_polyphony = 64
    result.enable_reverb_and_chorus = true
    return result
}

@(private)
validate_settings :: proc(s: ^Synthesizer_Settings) -> Error {
    if !(16000 <= s.sample_rate && s.sample_rate <= 192000) {
        return Odinysynth_Error.Sample_Rate_Is_Out_Of_Range
    }

    if !(8 <= s.block_size && s.block_size <= 1024) {
        return Odinysynth_Error.Block_Size_Is_Out_Of_Range
    }

    if !(8 <= s.maximum_polyphony && s.maximum_polyphony <= 256) {
        return Odinysynth_Error.Maximum_Polyphony_Is_Out_Of_Range
    }

    return nil
}
