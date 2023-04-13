package odinysynth

import "core:math"

@(private)
HALF_PI :: math.PI / 2.0

@(private)
NON_AUDIBLE :: 1.0E-3

@(private)
LOG_NON_AUDIBLE :: -6.90775527898

@(private)
clamp :: proc(value: f32, min: f32, max: f32) -> f32 {
    if value < min {
        return min
    } else if value > max {
        return max
    } else {
        return value
    }
}

@(private)
timecents_to_seconds :: proc(x: f32) -> f32 {
    return math.pow_f32(2.0, (1.0 / 1200.0) * x)
}

@(private)
cents_to_hertz :: proc(x: f32) -> f32 {
    return 8.176 * math.pow_f32(2.0, (1.0 / 1200.0) * x)
}

@(private)
cents_to_multiplying_factor :: proc(x: f32) -> f32 {
    return math.pow_f32(2.0, (1.0 / 1200.0) * x)
}

@(private)
decibels_to_linear :: proc(x: f32) -> f32 {
    return math.pow_f32(10.0, 0.05 * x)
}

@(private)
linear_to_decibels :: proc(x: f32) -> f32 {
    return 20.0 * math.log10_f32(x)
}

@(private)
key_number_to_multiplying_factor :: proc(cents: i32, key: i32) -> f32 {
    return timecents_to_seconds(f32(cents) * f32(60 - key))
}

@(private)
exp_cutoff :: proc(x: f64) -> f64 {
    if x < LOG_NON_AUDIBLE {
        return 0.0
    } else {
        return math.exp_f64(x)
    }
}
