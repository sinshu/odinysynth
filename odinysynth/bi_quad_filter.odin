package odinysynth

import "core:math"

@(private)
RESONANCE_PEAK_OFFSET :: 1.0 - 1.0 / 1.41421356237

@(private)
Bi_Quad_Filter :: struct {
    sample_rate: int,

    active: bool,

    a0: f32,
    a1: f32,
    a2: f32,
    a3: f32,
    a4: f32,

    x1: f32,
    x2: f32,
    y1: f32,
    y2: f32,
}

@(private)
new_bi_quad_filter :: proc(settings: ^Synthesizer_Settings) -> Bi_Quad_Filter {
    result: Bi_Quad_Filter = {}
    result.sample_rate = settings.sample_rate
    return result
}

@(private)
clear_bi_quad_filter :: proc(f: ^Bi_Quad_Filter) {
    f.x1 = 0.0
    f.x2 = 0.0
    f.y1 = 0.0
    f.y2 = 0.0
}

@(private)
set_low_pass_filter :: proc(f: ^Bi_Quad_Filter, cutoff_frequency: f32, resonance: f32) {
    if cutoff_frequency < 0.499 * f32(f.sample_rate) {
        f.active = true

        // This equation gives the Q value which makes the desired resonance peak.
        // The error of the resultant peak height is less than 3%.
        q := resonance - RESONANCE_PEAK_OFFSET / (1.0 + 6.0 * (resonance - 1.0))

        w := 2.0 * math.PI * cutoff_frequency / f32(f.sample_rate)
        cosw := math.cos_f32(w)
        alpha := math.sin_f32(w) / (2.0 * q)

        b0 := (1.0 - cosw) / 2.0
        b1 := 1.0 - cosw
        b2 := (1.0 - cosw) / 2.0
        a0 := 1.0 + alpha
        a1 := -2.0 * cosw
        a2 := 1.0 - alpha

        set_bi_quad_filter_coefficients(f, a0, a1, a2, b0, b1, b2)
    } else {
        f.active = false;
    }
}

@(private)
process_bi_quad_filter :: proc(f: ^Bi_Quad_Filter, block: []f32) {
    if f.active {
        for input, t in block {
            output := f.a0 * input + f.a1 * f.x1 + f.a2 * f.x2 - f.a3 * f.y1 - f.a4 * f.y2

            f.x2 = f.x1
            f.x1 = input
            f.y2 = f.y1
            f.y1 = output

            block[t] = output
        }
    } else {
        f.x2 = block[len(block) - 2]
        f.x1 = block[len(block) - 1]
        f.y2 = f.x2
        f.y1 = f.x1
    }
}

@(private)
set_bi_quad_filter_coefficients :: proc(f: ^Bi_Quad_Filter, a0: f32, a1: f32, a2: f32, b0: f32, b1: f32, b2: f32) {
    f.a0 = b0 / a0
    f.a1 = b1 / a0
    f.a2 = b2 / a0
    f.a3 = a1 / a0
    f.a4 = a2 / a0
}
