package odinysynth

@(private)
Volume_Envelope :: struct {
    sample_rate: int,

    attack_slope: f64,
    decay_slope: f64,
    release_slope: f64,

    attack_start_time: f64,
    hold_start_time: f64,
    decay_start_time: f64,
    release_start_time: f64,

    sustain_level: f32,
    release_level: f32,

    processed_sample_count: int,
    stage: Envelope_Stage,
    value: f32,

    priority: f32,
}

@(private)
new_volume_envelope :: proc(settings: ^Synthesizer_Settings) -> Volume_Envelope {
    result: Volume_Envelope = {}
    result.sample_rate = settings.sample_rate
    return result
}

@(private)
start_volume_envelope :: proc(e: ^Volume_Envelope, delay: f32, attack: f32, hold: f32, decay: f32, sustain: f32, release: f32) {
    e.attack_slope = 1.0 / f64(attack)
    e.decay_slope = -9.226 / f64(decay)
    e.release_slope = -9.226 / f64(release)

    e.attack_start_time = f64(delay)
    e.hold_start_time = e.attack_start_time + f64(attack)
    e.decay_start_time = e.hold_start_time + f64(hold)
    e.release_start_time = 0.0

    e.sustain_level = clamp(sustain, 0.0, 1.0)
    e.release_level = 0.0

    e.processed_sample_count = 0
    e.stage = Envelope_Stage.Delay
    e.value = 0.0

    process_volume_envelope(e, 0)
}

@(private)
release_volume_envelope :: proc(e: ^Volume_Envelope) {
    e.stage = Envelope_Stage.Release
    e.release_start_time = f64(e.processed_sample_count) / f64(e.sample_rate)
    e.release_level = e.value
}

@(private)
process_volume_envelope :: proc(e: ^Volume_Envelope, sample_count: int) -> bool {
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
        e.priority = 4 + e.value
        return true
    case Envelope_Stage.Attack:
        e.value = f32(e.attack_slope * (current_time - e.attack_start_time))
        e.priority = 3 + e.value
        return true
    case Envelope_Stage.Hold:
        e.value = 1
        e.priority = 2 + e.value
        return true
    case Envelope_Stage.Decay:
        e.value = f32(max(exp_cutoff(e.decay_slope * (current_time - e.decay_start_time)), f64(e.sustain_level)))
        e.priority = 1 + e.value
        return e.value > NON_AUDIBLE
    case Envelope_Stage.Release:
        e.value = f32(f64(e.release_level) * exp_cutoff(e.release_slope * (current_time - e.release_start_time)))
        e.priority = e.value
        return e.value > NON_AUDIBLE
    case:
        panic("invalid envelope stage")
    }
}
