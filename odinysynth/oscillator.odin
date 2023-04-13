package odinysynth

import "core:math"

@(private)
FRAC_BITS :: 24

@(private)
FRAC_UNIT :: 1 << FRAC_BITS

@(private)
FP_TO_SAMPLE :: 1.0 / (32768.0 * f32(FRAC_UNIT))

@(private)
Oscillator :: struct {
    synthesizer_sample_rate: int,

    data: []i16,
    loop_mode: Loop_Mode,
    sample_sample_rate: int,
    start: int,
    end: int,
    start_loop: int,
    end_loop: int,
    root_key: int,

    tune: f32,
    pitch_change_scale: f32,
    sample_rate_ratio: f32,

    looping: bool,

    position_fp: i64,
}

@(private)
new_oscillator :: proc(settings: ^Synthesizer_Settings) -> Oscillator {
    result: Oscillator = {}
    result.synthesizer_sample_rate = settings.sample_rate
    return result
}

@(private)
start_oscillator :: proc(o: ^Oscillator, data: []i16, loop_mode: Loop_Mode, sample_rate: int, start: int, end: int, start_loop: int, end_loop: int, root_key: int, coarse_tune: int, fine_tune: int, scale_tuning: int) {
    o.data = data
    o.loop_mode = loop_mode
    o.sample_sample_rate = sample_rate
    o.start = start
    o.end = end
    o.start_loop = start_loop
    o.end_loop = end_loop
    o.root_key = root_key

    o.tune = f32(coarse_tune) + 0.01 * f32(fine_tune)
    o.pitch_change_scale = 0.01 * f32(scale_tuning)
    o.sample_rate_ratio = f32(sample_rate) / f32(o.synthesizer_sample_rate)

    if o.loop_mode == Loop_Mode.No_Loop {
        o.looping = false
    } else {
        o.looping = true
    }

    o.position_fp = i64(start) << FRAC_BITS
}

@(private)
release_oscillator :: proc(o: ^Oscillator) {
    if o.loop_mode == Loop_Mode.Loop_Until_Note_Off {
        o.looping = false
    }
}

@(private)
process_oscillator :: proc(o: ^Oscillator, block: []f32, pitch: f32) -> bool {
    pitch_change := o.pitch_change_scale * (pitch - f32(o.root_key)) + o.tune
    pitch_ratio := o.sample_rate_ratio * math.pow_f32(2.0, pitch_change / 12.0)
    return oscillator_fill_block(o, block, f64(pitch_ratio))
}

@(private)
oscillator_fill_block :: proc(o: ^Oscillator, block: []f32, pitch_ratio: f64) -> bool {
    pitch_ratio_fp := i64(f64(FRAC_UNIT) * pitch_ratio)

    if o.looping {
        return oscillator_fill_block_continuous(o, block, pitch_ratio_fp)
    } else {
        return oscillator_fill_block_no_loop(o, block, pitch_ratio_fp)
    }
}

@(private)
oscillator_fill_block_no_loop :: proc(o: ^Oscillator, block: []f32, pitch_ratio_fp: i64) -> bool {
    data := o.data
    block_length := len(block)

    for t := 0; t < block_length; t += 1 {
        index := int(o.position_fp >> FRAC_BITS)

        if index >= o.end {
            if t > 0 {
                for u := t; u < block_length; u += 1 {
                    block[u] = 0.0
                }
                return true
            } else {
                return false
            }
        }

        x1 := i64(data[index])
        x2 := i64(data[index + 1])
        a_fp := o.position_fp & (FRAC_UNIT - 1)
        block[t] = FP_TO_SAMPLE * f32((x1 << FRAC_BITS) + a_fp * (x2 - x1))

        o.position_fp += pitch_ratio_fp
    }

    return true
}

@(private)
oscillator_fill_block_continuous :: proc(o: ^Oscillator, block: []f32, pitch_ratio_fp: i64) -> bool {
    data := o.data
    block_length := len(block)

    end_loop_fp := i64(o.end_loop) << FRAC_BITS

    loop_length := o.end_loop - o.start_loop
    loop_length_fp := i64(loop_length) << FRAC_BITS

    for t := 0; t < block_length; t += 1 {
        if o.position_fp >= end_loop_fp {
            o.position_fp -= loop_length_fp
        }

        index1 := int(o.position_fp >> FRAC_BITS)
        index2 := index1 + 1

        if index2 >= o.end_loop {
            index2 -= loop_length
        }

        x1 := i64(data[index1])
        x2 := i64(data[index2])
        a_fp := o.position_fp & (FRAC_UNIT - 1)
        block[t] = FP_TO_SAMPLE * f32((x1 << FRAC_BITS) + a_fp * (x2 - x1))

        o.position_fp += pitch_ratio_fp
    }

    return true
}
