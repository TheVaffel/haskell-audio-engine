// WARNING: This file has been auto-generated. Modifications should be done to `typegen.py` rather than this file directly
pub enum NumericCommand {
    InsertAtIndex = 0,
    InsertAndForget = 1,
    StopAtIndex = 2,
    Exit = 3,
    SetExternalParameter = 4,
    SetExternalParameter2 = 5,
    SetExternalParameter3 = 6,
    SineGenerator = 7,
    SineGeneratorWithFrequency = 8,
    ModulateOp = 9,
    MixOp = 10,
    Envelope = 11,
    Volume = 12,
    DistanceFactor = 13,
    Bell = 14,
    ExternalParameter = 15,
    Custom = 16,
    Custom2 = 17,
}

#[derive(Clone)]
pub enum AudioCommand {
    InsertAtIndex(u32,AudioGenerator),
    InsertAndForget(AudioGenerator),
    StopAtIndex(u32),
    Exit,
    SetExternalParameter(u32,f32,f32),
    SetExternalParameter2((i32, i32),(f32, f32),f32),
    SetExternalParameter3((i32, i32, i32),(f32, f32, f32),f32),
}

#[derive(Clone)]
pub enum AudioGenerator {
    SineGenerator(Box<AudioGenerator>),
    SineGeneratorWithFrequency(f32),
    ModulateOp(Box<AudioGenerator>,Box<AudioGenerator>),
    MixOp(Box<AudioGenerator>,Box<AudioGenerator>),
    Envelope(f32,f32,f32),
    Volume(f32,Box<AudioGenerator>),
    DistanceFactor((i32, i32, i32),Box<AudioGenerator>),
    Bell(f32),
    ExternalParameter(i32),
    Custom(f32),
    Custom2(f32),
}

pub const LISTENER_X_PARAM_INDEX: f32 = -1000.0;
pub const LISTENER_Y_PARAM_INDEX: f32 = -1001.0;
pub const LISTENER_Z_PARAM_INDEX: f32 = -1002.0;