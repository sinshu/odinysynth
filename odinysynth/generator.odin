package odinysynth

import "core:io"

@(private)
Generator :: struct {
    generator_type: u16,
    value: i16,
}

@(private)
new_generator :: proc(r: io.Reader) -> (Generator, Error) {
    result: Generator = {}
    err: Error = nil

    result.generator_type, err = read_u16(r)
    if err != nil {
        return {}, err
    }

    result.value, err = read_i16(r)
    if err != nil {
        return {}, err
    }

    return result, nil
}

@(private)
read_generators_from_chunk :: proc(r: io.Reader, size: int) -> ([]Generator, Error) {
    result: []Generator = nil
    err: Error = nil

    defer {
        if err != nil {
            if result != nil {
                delete(result)
            }
        }
    }

    if size % 4 != 0 {
        err = Odinysynth_Error.Invalid_Soundfont
        return nil, err
    }

    count := size / 4 - 1
    
    result, err = make([]Generator, count)
    if err != nil {
        return nil, err
    }

    for i := 0; i < count; i += 1 {
        result[i], err = new_generator(r)
        if err != nil {
            return nil, err
        }
    }

    // The last one is the terminator.
    terminator: Generator
    terminator, err = new_generator(r)
    if err != nil {
        return nil, err
    }

    return result, nil
}
