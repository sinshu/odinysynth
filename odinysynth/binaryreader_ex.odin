package odinysynth

import "core:io"

read_four_cc :: proc(r: io.Reader) -> ([4]u8, io.Error) {
	data: [4]u8
	n, err := io.read_full(r, data[:])
	if err != nil {
		return data, err
	}

	for i := 0; i < len(data); i += 1 {
		value := data[i]
		if !(32 <= value && value <= 126) {
			data[i] = '?'
		}
	}

	return data, io.Error.None
}
