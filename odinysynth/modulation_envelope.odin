package odinysynth

@(private)
Modulation_Envelope :: struct {
    sample_rate: int,

    attack_slope: f64,
    decay_slope: f64,
    release_slope: f64,

    attack_start_time: f64,
    hold_start_time: f64,
    decay_start_time: f64,

    decay_end_time: f64,
    release_end_time: f64,

    sustain_level: f32,
    release_level: f32,

    processed_sample_count: int,
    stage: Envelope_Stage,
    value: f32,
}

@(private)
new_modulation_envelope :: proc(settings: ^Synthesizer_Settings) -> Modulation_Envelope {
    result: Modulation_Envelope = {}
    result.sample_rate = settings.sample_rate
    return result
}

@(private)
start_modulation_envelope :: proc(e: ^Modulation_Envelope, delay: f32, attack: f32, hold: f32, decay: f32, sustain: f32, release: f32) {
    e.attack_slope = 1.0 / f64(attack)
    e.decay_slope = 1.0 / f64(decay)
    e.release_slope = 1.0 / f64(release)

    e.attack_start_time = f64(delay)
    e.hold_start_time = e.attack_start_time + f64(attack)
    e.decay_start_time = e.hold_start_time + f64(hold)

    e.decay_end_time = e.decay_start_time + f64(decay)
    e.release_end_time = f64(release)

    e.sustain_level = clamp(sustain, 0.0, 1.0)
    e.release_level = 0.0

    e.processed_sample_count = 0
    e.stage = Envelope_Stage.Delay
    e.value = 0.0

    process_modulation_envelope(e, 0)
}

@(private)
release_modulation_envelope :: proc(e: ^Modulation_Envelope) {
    e.stage = Envelope_Stage.Release
    e.release_end_time += f64(e.processed_sample_count) / f64(e.sample_rate)
    e.release_level = e.value
}

@(private)
process_modulation_envelope :: proc(e: ^Modulation_Envelope, sample_count: int) -> bool {
    e.processed_sample_count += sample_count

    current_time := f64(e.processed_sample_count) / f64(e.sample_rate)

    for e.stage <= Envelope_Stage.Hold {
        end_time: f64
        #partial switch e.stage {
        case Envelope_Stage.Delay:
            end_time = e.attack_start_time
        case Envelope_Stage.Attack:
            end_time = e.hold_start_time
        case Envelope_Stage.Hold:
            end_time = e.decay_start_time
        case:
            panic("invalid envelope stage")
        }

        if current_time < end_time {
            break
        } else {
            e.stage = Envelope_Stage(int(e.stage) + 1)
        }
    }

    switch e.stage {
    case Envelope_Stage.Delay:
        e.value = 0
        return true
    case Envelope_Stage.Attack:
        e.value = f32(e.attack_slope * (current_time - e.attack_start_time))
        return true
    case Envelope_Stage.Hold:
        e.value = 1
        return true
    case Envelope_Stage.Decay:
        e.value = f32(max(e.decay_slope * (e.decay_end_time - current_time), f64(e.sustain_level)))
        return e.value > NON_AUDIBLE
    case Envelope_Stage.Release:
        e.value = f32(max(f64(e.release_level) * f64(e.release_slope) * (e.release_end_time - current_time), 0))
        return e.value > NON_AUDIBLE
    case:
        panic("invalid envelope stage.")
    }
}
