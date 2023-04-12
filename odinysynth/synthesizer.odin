package odinysynth

Synthesizer :: struct {
    sound_font: ^Soundfont,
    sample_rate: int,
    block_size: int,
    maximum_polyphony: int,
    enable_reverb_and_chorus: bool,
}
