package odinysynth

@(private)
Channel :: struct {
    is_percussion_channel: bool,

    bank_number: int,
    patch_number: int,

    modulation: i16,
    volume: i16,
    pan: i16,
    expression: i16,
    hold_pedal: bool,

    reverb_send: u8,
    chorus_send: u8,

    rpn: i16,
    pitch_bend_range: i16,
    coarse_tune: i16,
    fine_tune: i16,

    pitch_bend: f32,
}

@(private)
new_channel :: proc(is_percussion_channel: bool) -> Channel {
    result: Channel = {}
    result.is_percussion_channel = is_percussion_channel
    return result
}

@(private)
channel_reset :: proc(ch: ^Channel) {
    ch.bank_number = ch.is_percussion_channel ? 128 : 0
    ch.patch_number = 0

    ch.modulation = 0
    ch.volume = 100 << 7
    ch.pan = 64 << 7
    ch.expression = 127 << 7
    ch.hold_pedal = false

    ch.reverb_send = 40
    ch.chorus_send = 0

    ch.rpn = -1
    ch.pitch_bend_range = 2 << 7
    ch.coarse_tune = 0
    ch.fine_tune = 8192

    ch.pitch_bend = 0.0
}

@(private)
channel_reset_all_controllers :: proc(ch: ^Channel) {
    ch.modulation = 0
    ch.expression = 127 << 7
    ch.hold_pedal = false

    ch.rpn = -1

    ch.pitch_bend = 0.0
}

@(private)
channel_set_bank :: proc(ch: ^Channel, value: i32) {
    ch.bank_number = int(value)

    if ch.is_percussion_channel {
        ch.bank_number += 128
    }
}

@(private)
channel_set_patch :: proc(ch: ^Channel, value: i32) {
    ch.patch_number = int(value)
}

@(private)
channel_set_modulation_coarse :: proc(ch: ^Channel, value: i32) {
    ch.modulation = i16((i32(ch.modulation) & 0x7F) | (value << 7))
}

@(private)
channel_set_modulation_fine :: proc(ch: ^Channel, value: i32) {
    ch.modulation = i16((i32(ch.modulation) & 0xFF80) | value)
}

@(private)
channel_set_volume_coarse :: proc(ch: ^Channel, value: i32) {
    ch.volume = i16((i32(ch.volume) & 0x7F) | (value << 7))
}

@(private)
channel_set_volume_fine :: proc(ch: ^Channel, value: i32) {
    ch.volume = i16((i32(ch.volume) & 0xFF80) | value)
}

@(private)
channel_set_pan_coarse :: proc(ch: ^Channel, value: i32) {
    ch.pan = i16((i32(ch.pan) & 0x7F) | (value << 7))
}

@(private)
channel_set_pan_fine :: proc(ch: ^Channel, value: i32) {
    ch.pan = i16((i32(ch.pan) & 0xFF80) | value)
}

@(private)
channel_set_expression_coarse :: proc(ch: ^Channel, value: i32) {
    ch.expression = i16((i32(ch.expression) & 0x7F) | (value << 7))
}

@(private)
channel_set_expression_fine :: proc(ch: ^Channel, value: i32) {
    ch.expression = i16((i32(ch.expression) & 0xFF80) | value)
}

@(private)
channel_set_hold_pedal :: proc(ch: ^Channel, value: i32) {
    ch.hold_pedal = value >= 64
}

@(private)
channel_set_reverb_send :: proc(ch: ^Channel, value: i32) {
    ch.reverb_send = u8(value)
}

@(private)
channel_set_chorus_send :: proc(ch: ^Channel, value: i32) {
    ch.chorus_send = u8(value)
}

@(private)
channel_set_rpn_coarse :: proc(ch: ^Channel, value: i32) {
    ch.rpn = i16((i32(ch.rpn) & 0x7F) | (value << 7))
}

@(private)
channel_set_rpn_fine :: proc(ch: ^Channel, value: i32) {
    ch.rpn = i16((i32(ch.rpn) & 0xFF80) | value)
}

@(private)
channel_data_entry_coarse :: proc(ch: ^Channel, value: i32) {
    switch ch.rpn {
    case 0:
        ch.pitch_bend_range = i16((i32(ch.pitch_bend_range) & 0x7F) | (value << 7))
    case 1:
        ch.fine_tune = i16((i32(ch.fine_tune) & 0x7F) | (value << 7))
    case 2:
        ch.coarse_tune = i16(value - 64)
    }
}

@(private)
channel_data_entry_fine :: proc(ch: ^Channel, value: i32) {
    switch ch.rpn {
    case 0:
        ch.pitch_bend_range = i16((i32(ch.pitch_bend_range) & 0xFF80) | value)
    case 1:
        ch.fine_tune = i16((i32(ch.fine_tune) & 0xFF80) | value)
    }
}

@(private)
channel_set_pitch_bend :: proc(ch: ^Channel, value1: i32, value2: i32) {
    ch.pitch_bend = (1.0 / 8192.0) * f32((value1 | (value2 << 7)) - 8192)
}

@(private)
channel_get_modulation :: proc(ch: ^Channel) -> f32 {
    return (50.0 / 16383.0) * f32(ch.modulation)
}

@(private)
channel_get_volume :: proc(ch: ^Channel) -> f32 {
    return (1.0 / 16383.0) * f32(ch.volume)
}

@(private)
channel_get_pan :: proc(ch: ^Channel) -> f32 {
    return (100.0 / 16383.0) * f32(ch.pan) - 50.0
}

@(private)
channel_get_expression :: proc(ch: ^Channel) -> f32 {
    return (1.0 / 16383.0) * f32(ch.expression)
}

@(private)
channel_get_reverb_send :: proc(ch: ^Channel) -> f32 {
    return (1.0 / 127.0) * f32(ch.reverb_send)
}

@(private)
channel_get_chorus_send :: proc(ch: ^Channel) -> f32 {
    return (1.0 / 127.0) * f32(ch.chorus_send)
}

@(private)
channel_get_pitch_bend_range :: proc(ch: ^Channel) -> f32 {
    return f32(ch.pitch_bend_range >> 7) + 0.01 * f32(ch.pitch_bend_range & 0x7F)
}

@(private)
channel_get_tune :: proc(ch: ^Channel) -> f32 {
    return f32(ch.coarse_tune) + (1.0 / 8192.0) * f32(ch.fine_tune - 8192)
}

@(private)
channel_get_pitch_bend :: proc(ch: ^Channel) -> f32 {
    return channel_get_pitch_bend_range(ch) * ch.pitch_bend
}
