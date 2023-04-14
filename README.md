# OdinySynth

OdinySynth is a SoundFont MIDI synthesizer written in pure Odin, ported from [MeltySynth](https://github.com/sinshu/meltysynth).



## Examples

An example code to synthesize a simple chord:

```odin
using odinysynth

// Load the SoundFont.
sf2, _ := os.open("TimGM6mb.sf2", os.O_RDONLY)
defer os.close(sf2)
soundfont, _ := new_soundfont(io.Reader { stream = os.stream_from_handle(sf2) })
defer destroy(&soundfont)

// Create the synthesizer.
settings := new_synthesizer_settings(44100)
synthesizer, _ := new_synthesizer(&soundfont, &settings)
defer destroy(&synthesizer)

// Play some notes (middle C, E, G).
note_on(&synthesizer, 0, 60, 100)
note_on(&synthesizer, 0, 64, 100)
note_on(&synthesizer, 0, 67, 100)

// The output buffer (3 seconds).
sample_count := 3 * settings.sample_rate
left := make([]f32, sample_count)
defer delete(left)
right := make([]f32, sample_count)
defer delete(right)

// Render the waveform.
render(&synthesizer, left[:], right[:])
```

Another example code to synthesize a MIDI file:

```odin
using odinysynth

// Load the SoundFont.
sf2, _ := os.open("TimGM6mb.sf2", os.O_RDONLY)
defer os.close(sf2)
soundfont, _ := new_soundfont(io.Reader { stream = os.stream_from_handle(sf2) })
defer destroy(&soundfont)

// Create the synthesizer.
settings := new_synthesizer_settings(44100)
synthesizer, _ := new_synthesizer(&soundfont, &settings)
defer destroy(&synthesizer)

// Load the MIDI file.
mid, _ := os.open("flourish.mid", os.O_RDONLY)
defer os.close(mid)
midi_file, _ := new_midi_file(io.Reader { stream = os.stream_from_handle(mid) })
defer destroy(&midi_file)

// Create the sequencer.
sequencer := new_midi_file_sequencer(&synthesizer)

// Play the MIDI file.
play(&sequencer, &midi_file, false)

// The output buffer.
sample_count := int(f64(settings.sample_rate) * get_length(&midi_file))
left := make([]f32, sample_count)
defer delete(left)
right := make([]f32, sample_count)
defer delete(right)

// Render the waveform.
render(&sequencer, left[:], right[:])
```



## Todo

* __Wave synthesis__
    - [x] SoundFont reader
    - [x] Waveform generator
    - [x] Envelope generator
    - [x] Low-pass filter
    - [x] Vibrato LFO
    - [x] Modulation LFO
* __MIDI message processing__
    - [x] Note on/off
    - [x] Bank selection
    - [x] Modulation
    - [x] Volume control
    - [x] Pan
    - [x] Expression
    - [x] Hold pedal
    - [x] Program change
    - [x] Pitch bend
    - [x] Tuning
* __Effects__
    - [ ] Reverb
    - [ ] Chorus
* __Other things__
    - [x] Standard MIDI file support
    - [ ] Performace optimization



## License

OdinySynth is available under [the MIT license](LICENSE.txt).