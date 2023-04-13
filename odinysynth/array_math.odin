package odinysynth

array_multiply_add :: proc(a: f32, x: []f32, destination: []f32) {
    destination_length := len(destination)
    for i := 0; i < destination_length; i += 1 {
        destination[i] += a * x[i]
    }
}

array_multiply_add_slope :: proc(a: f32, step: f32, x: []f32, destination: []f32) {
    destination_length := len(destination)
    b := a
    for i := 0; i < destination_length; i += 1 {
        destination[i] += b * x[i]
        b += step
    }
}
