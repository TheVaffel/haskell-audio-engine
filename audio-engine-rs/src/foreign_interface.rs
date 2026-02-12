// WARNING: This file has been auto-generated. Modifications should be done to `typegen.py` rather than this file directly
pub enum NumericCommand {
    InsertAtIndex = 0,
    InsertAndForget = 1,
    StopAtIndex = 2,
    Exit = 3,
    SineGenerator = 4,
    SineGeneratorWithFrequency = 5,
    ModulateOp = 6,
    MixOp = 7,
    Envelope = 8,
    Volume = 9,
    Bell = 10,
    Custom = 11,
    Custom2 = 12,
}

#[derive(Clone)]
pub enum AudioCommand {
    InsertAtIndex(u32,AudioGenerator),
    InsertAndForget(AudioGenerator),
    StopAtIndex(u32),
    Exit,
}

#[derive(Clone)]
pub enum AudioGenerator {
    SineGenerator,
    SineGeneratorWithFrequency(f32),
    ModulateOp(Box<AudioGenerator>,Box<AudioGenerator>),
    MixOp(Box<AudioGenerator>,Box<AudioGenerator>),
    Envelope(f32,f32,f32),
    Volume(f32,Box<AudioGenerator>),
    Bell(f32),
    Custom(f32),
    Custom2(f32),
}