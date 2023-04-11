package odinysynth

@(private)
Zone :: struct {
    generators: []Generator,
}

@(private)
empty_generators: [0]Generator = {}

@(private)
empty_zone: Zone = { generators = empty_generators[:] }

@(private)
new_zone :: proc(info: ^Zone_Info, generators: []Generator) -> Zone {
    start := int(info.generator_index)
    end := start + int(info.generator_count)
    segment := generators[start:end]

    return Zone {
        generators = segment,
    }
}

@(private)
create_zones :: proc(infos: []Zone_Info, generators: []Generator) -> ([]Zone, Error) {
    result: []Zone = nil
    err: Error = nil

    defer {
        if err != nil {
            if result != nil {
                delete(result)
            }
        }
    }

    if len(infos) <= 1 {
        err = Odinysynth_Error.Invalid_Soundfont
        return nil, err
    }

    // The last one is the terminator.
    count := len(infos) - 1

    result = make([]Zone, count)

    for i := 0; i < count; i += 1 {
        result[i] = new_zone(&infos[i], generators)
    }

    return result, nil
}
