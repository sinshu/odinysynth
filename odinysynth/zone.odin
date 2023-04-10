package odinysynth

Zone :: struct {
    generators: []Generator,
}

empty_generators: [0]Generator = {}
empty_zone: Zone = { generators = empty_generators[:] }

new_zone :: proc(info: ^Zone_Info, generators: []Generator) -> Zone {
    start := int(info.generator_index)
    end := start + int(info.generator_count)
    segment := generators[start:end]

    return Zone {
        generators = segment,
    }
}

create_zones :: proc(infos: []Zone_Info, generators: []Generator) -> ([dynamic]Zone, Error) {
    result: [dynamic]Zone = nil
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

    result = make([dynamic]Zone, count)

    for i := 0; i < count; i += 1 {
        result[i] = new_zone(&infos[i], generators)
    }

    return result, nil;
}
