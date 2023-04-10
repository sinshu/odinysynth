package odinysynth

Generator_Type :: enum {
    Start_Address_Offset = 0,
    End_Address_Offset = 1,
    Start_Loop_Address_Offset = 2,
    End_Loop_Address_Offset = 3,
    Start_Address_Coarse_Offset = 4,
    Modulation_Lfo_To_Pitch = 5,
    Vibrato_Lfo_To_Pitch = 6,
    Modulation_Envelope_To_Pitch = 7,
    Initial_Filter_Cutoff_Frequency = 8,
    Initial_Filter_Q = 9,
    Modulation_Lfo_To_Filter_Cutoff_Frequency = 10,
    Modulation_Envelope_To_Filter_Cutoff_Frequency = 11,
    End_Address_Coarse_Offset = 12,
    Modulation_Lfo_To_Volume = 13,
    Unused1 = 14,
    Chorus_Effects_Send = 15,
    Reverb_Effects_Send = 16,
    Pan = 17,
    Unused2 = 18,
    Unused3 = 19,
    Unused4 = 20,
    Delay_Modulation_Lfo = 21,
    Frequency_Modulation_Lfo = 22,
    Delay_Vibrato_Lfo = 23,
    Frequency_Vibrato_Lfo = 24,
    Delay_Modulation_Envelope = 25,
    Attack_Modulation_Envelope = 26,
    Hold_Modulation_Envelope = 27,
    Decay_Modulation_Envelope = 28,
    Sustain_Modulation_Envelope = 29,
    Release_Modulation_Envelope = 30,
    Key_Number_To_Modulation_Envelope_Hold = 31,
    Key_Number_To_Modulation_Envelope_Decay = 32,
    Delay_Volume_Envelope = 33,
    Attack_Volume_Envelope = 34,
    Hold_Volume_Envelope = 35,
    Decay_Volume_Envelope = 36,
    Sustain_Volume_Envelope = 37,
    Release_Volume_Envelope = 38,
    Key_Number_To_Volume_Envelope_Hold = 39,
    Key_Number_To_Volume_Envelope_Decay = 40,
    Instrument = 41,
    Reserved1 = 42,
    Key_Range = 43,
    Velocity_Range = 44,
    Start_Loop_Address_Coarse_Offset = 45,
    Key_Number = 46,
    Velocity = 47,
    Initial_Attenuation = 48,
    Reserved2 = 49,
    End_Loop_Address_Coarse_Offset = 50,
    Coarse_Tune = 51,
    Fine_Tune = 52,
    Sample_ID = 53,
    Sample_Modes = 54,
    Reserved3 = 55,
    Scale_Tuning = 56,
    Exclusive_Class = 57,
    Overriding_Root_Key = 58,
    Unused5 = 59,
    Unused_End = 60,

    Count = 61,
}