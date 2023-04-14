package odinysynth

import "core:io"

@(private)
read_i8 :: proc(r: io.Reader) -> (i8, Error) {
    value, err := io.read_byte(r)
    if err != nil {
        return 0, err
    }

    return i8(value), nil
}

@(private)
read_u8 :: proc(r: io.Reader) -> (u8, Error) {
    value, err := io.read_byte(r)
    if err != nil {
        return 0, err
    }

    return value, nil
}

@(private)
read_i16 :: proc(r: io.Reader) -> (i16, Error) {
    data: [2]u8
    n, err := io.read_full(r, data[:])
    if err != nil {
        return 0, err
    }

    return transmute(i16)data, nil
}

@(private)
read_u16 :: proc(r: io.Reader) -> (u16, Error) {
    data: [2]u8
    n, err := io.read_full(r, data[:])
    if err != nil {
        return 0, err
    }

    return transmute(u16)data, nil
}

@(private)
read_i32 :: proc(r: io.Reader) -> (i32, Error) {
    data: [4]u8
    n, err := io.read_full(r, data[:])
    if err != nil {
        return 0, err
    }

    return transmute(i32)data, nil
}

@(private)
read_four_cc :: proc(r: io.Reader) -> ([4]u8, Error) {
    data: [4]u8
    n, err := io.read_full(r, data[:])
    if err != nil {
        return {}, err
    }

    for value, i in data {
        if !(32 <= value && value <= 126) {
            data[i] = '?'
        }
    }

    return data, nil
}

@(private)
read_fixed_length_string :: proc(r: io.Reader, data: []u8) -> Error {
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
discard_data :: proc(r: io.Reader, size: int) -> Error {
    data: []u8 = nil
    err: Error = nil

    defer {
        if data != nil {
            delete(data)
        }
    }

    data, err = make([]u8, size)
    if err != nil {
        return err
    }

    n: int
    n, err = io.read_full(r, data[:])
    if err != nil {
        return err
    }

    return nil
}

@(private)
read_i16_big_endian :: proc(r: io.Reader) -> (i16, Error) {
    data1: [2]u8
    n, err := io.read_full(r, data1[:])
    if err != nil {
        return 0, err
    }

    data2: [2]u8
    data2[0] = data1[1]
    data2[1] = data1[0]

    return transmute(i16)data2, nil
}

@(private)
read_i32_big_endian :: proc(r: io.Reader) -> (i32, Error) {
    data1: [4]u8
    n, err := io.read_full(r, data1[:])
    if err != nil {
        return 0, err
    }

    data2: [4]u8
    data2[0] = data1[3]
    data2[1] = data1[2]
    data2[2] = data1[1]
    data2[3] = data1[0]

    return transmute(i32)data2, nil
}

@(private)
read_int_variable_length :: proc(r: io.Reader) -> (i32, Error) {
    acc: i32 = 0
    count := 0
    for {
        value, err := io.read_byte(r)
        if err != nil {
            return 0, err
        }
        acc = (acc << 7) | (i32(value) & 127)
        if (value & 128) == 0 {
            break
        }
        count += 1
        if count == 4 {
            return 0, Odinysynth_Error.Unexpected
        }
    }
    return acc, nil
}
