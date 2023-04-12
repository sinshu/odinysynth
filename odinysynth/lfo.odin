package odinysynth

import "core:math"

@(private)
Lfo :: struct {
    sample_rate: int,
    block_size: int,

    active: bool,

    delay: f64,
    period: f64,

    processed_sample_count: int,
    value: f32,
}

@(private)
new_lfo :: proc(settings: ^Synthesizer_Settings) -> Lfo {
    result: Lfo = {}
    result.sample_rate = settings.sample_rate
    result.block_size = settings.block_size
    return result
}

@(private)
start_lfo :: proc(lfo: ^Lfo, delay: f32, frequency: f32) {
    if frequency > 1.0e-3 {
		lfo.active = true

		lfo.delay = f64(delay)
		lfo.period = 1.0 / f64(frequency)

		lfo.processed_sample_count = 0
		lfo.value = 0
	} else {
	    lfo.active = false
	    lfo.value = 0
    }
}

@(private)
process_lfo :: proc(lfo: ^Lfo, sample_count: int) {
    if !lfo.active {
        return
    }

    lfo.processed_sample_count += lfo.block_size

    current_time := f64(lfo.processed_sample_count) / f64(lfo.sample_rate)

    if current_time < lfo.delay {
        lfo.value = 0.0
    } else {
        phase := math.mod_f64((current_time - lfo.delay), lfo.period) / lfo.period
        if phase < 0.25 {
            lfo.value = f32(4.0 * phase)
        } else if phase < 0.75 {
            lfo.value = f32(4.0 * (0.5 - phase))
        } else {
            lfo.value = f32(4.0 * (phase - 1.0))
        }
    }
}
