// WARNING: This file has been auto-generated. Modifications should be done to `typegen.py` rather than this file directly
pub enum NumericCommand {
    InsertAtIndex = 0,
    InsertAndForget = 1,
    StopAtIndex = 2,
    Exit = 3,
    SetExternalParameter = 4,
    SineGenerator = 5,
    SineGeneratorWithFrequency = 6,
    ModulateOp = 7,
    MixOp = 8,
    Envelope = 9,
    Volume = 10,
    Bell = 11,
    ExternalParameter = 12,
    Custom = 13,
    Custom2 = 14,
}

#[derive(Clone)]
pub enum AudioCommand {
    InsertAtIndex(u32,AudioGenerator),
    InsertAndForget(AudioGenerator),
    StopAtIndex(u32),
    Exit,
    SetExternalParameter(u32,f32,f32),
}

#[derive(Clone)]
pub enum AudioGenerator {
    SineGenerator(Box<AudioGenerator>),
    SineGeneratorWithFrequency(f32),
    ModulateOp(Box<AudioGenerator>,Box<AudioGenerator>),
    MixOp(Box<AudioGenerator>,Box<AudioGenerator>),
    Envelope(f32,f32,f32),
    Volume(f32,Box<AudioGenerator>),
    Bell(f32),
    ExternalParameter(u32),
    Custom(f32),
    Custom2(f32),
}