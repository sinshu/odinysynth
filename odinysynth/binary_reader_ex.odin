package odinysynth

import "core:io"

@(private)
read_i8 :: proc(r: io.Reader) -> (i8, io.Error) {
    value, err := io.read_byte(r)
    if err != nil {
        return 0, err
    }

    return i8(value), nil
}

@(private)
read_u8 :: proc(r: io.Reader) -> (u8, io.Error) {
    value, err := io.read_byte(r)
    if err != nil {
        return 0, err
    }

    return value, nil
}

@(private)
read_i16 :: proc(r: io.Reader) -> (i16, io.Error) {
    data: [2]u8
    n, err := io.read_full(r, data[:])
    if err != nil {
        return 0, err
    }

    return transmute(i16)data, nil
}

@(private)
read_u16 :: proc(r: io.Reader) -> (u16, io.Error) {
    data: [2]u8
    n, err := io.read_full(r, data[:])
    if err != nil {
        return 0, err
    }

    return transmute(u16)data, nil
}

@(private)
read_i32 :: proc(r: io.Reader) -> (i32, io.Error) {
    data: [4]u8
    n, err := io.read_full(r, data[:])
    if err != nil {
        return 0, err
    }

    return transmute(i32)data, nil
}

@(private)
read_four_cc :: proc(r: io.Reader) -> ([4]u8, io.Error) {
    data: [4]u8
    n, err := io.read_full(r, data[:])
    if err != nil {
        return data, err
    }

    for value, i in data {
        if !(32 <= value && value <= 126) {
            data[i] = '?'
        }
    }

    return data, nil
}

@(private)
read_fixed_length_string :: proc(r: io.Reader, data: []u8) -> io.Error {
    n, err := io.read_full(r, data[:])
    if err != nil {
        return err
    }

    pad := false
    for value, i in data {
        if value == 0 {
            pad = true
        }
        if pad {
            data[i] = 0
        }
    }

    return nil
}

@(private)
discard_data :: proc(r: io.Reader, size: int) -> io.Error {
    data := make([dynamic]u8, size)
    defer delete(data)

    n, err := io.read_full(r, data[:])
    return err
}
