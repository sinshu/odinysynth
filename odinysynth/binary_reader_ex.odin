package odinysynth

import "core:io"

read_i8 :: proc(r: io.Reader) -> (i8, io.Error) {
	value, err := io.read_byte(r)
	if err != nil {
		return 0, err
	}

	return i8(value), nil
}

read_u8 :: proc(r: io.Reader) -> (u8, io.Error) {
	value, err := io.read_byte(r)
	if err != nil {
		return 0, err
	}

	return value, nil
}

read_i16 :: proc(r: io.Reader) -> (i16, io.Error) {
	data: [2]u8
	n, err := io.read_full(r, data[:])
	if err != nil {
		return 0, err
	}

	return transmute(i16)data, nil
}

read_u16 :: proc(r: io.Reader) -> (u16, io.Error) {
	data: [2]u8
	n, err := io.read_full(r, data[:])
	if err != nil {
		return 0, err
	}

	return transmute(u16)data, nil
}

read_i32 :: proc(r: io.Reader) -> (i32, io.Error) {
	data: [4]u8
	n, err := io.read_full(r, data[:])
	if err != nil {
		return 0, err
	}

	return transmute(i32)data, nil
}

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

discard_data :: proc(r: io.Reader, size: int) -> io.Error {
	data := make([dynamic]u8, size)
	defer delete(data)

	n, err := io.read_full(r, data[:])
	return err
}
