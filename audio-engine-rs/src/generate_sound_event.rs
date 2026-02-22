use std::vec;

use super::circular_buffer::CircularBuffer;

type ElementType = f32;

enum NumericCommand {
    InsertAtIndex = 2,
    InsertAndForget = 3,
    StopAtIndex = 4,
    Exit = 5,
    SineGenerator = 1000,
    SineGeneratorWithFrequency = 1001,
    ModulateOp = 1002,
    MixOp = 1003,
    Envelope = 1004,
    Volume = 1005,
    Bell = 2001,
    Custom = 2002,
}

trait SerializableCommand {
    fn serialize_append(&self, result: &mut Vec<ElementType>) -> ();
}

#[derive(Clone)]
pub enum AudioCommand {
    InsertAtIndex(u32, AudioGenerator),
    InsertAndForget(AudioGenerator),
    StopAtIndex(u32),
    Exit,
}

#[derive(Clone)]
pub enum AudioGenerator {
    Sine,
    SineWithFrequency(ElementType),
    ModulateOp(Box<AudioGenerator>, Box<AudioGenerator>),
    MixOp(Box<AudioGenerator>, Box<AudioGenerator>),
    Envelope(f32, f32, f32),
    Volume(f32, Box<AudioGenerator>),
    Bell(f32),
    Custom(f32),
}

impl<'a> SerializableCommand for AudioCommand {
    fn serialize_append(&self, result: &mut Vec<ElementType>) -> () {
        match self {
            AudioCommand::InsertAtIndex(index, generator) => {
                write_command_marker(NumericCommand::InsertAtIndex, result);
                result.push(*index as ElementType);
                generator.serialize_append(result);
            }
            AudioCommand::InsertAndForget(generator) => {
                write_command_marker(NumericCommand::InsertAndForget, result);
                generator.serialize_append(result);
            }
            AudioCommand::StopAtIndex(index) => {
                write_command_marker(NumericCommand::StopAtIndex, result);
                result.push(*index as ElementType);
            }
            AudioCommand::Exit => {
                write_command_marker(NumericCommand::Exit, result);
            }
        }
    }
}

impl<'a> SerializableCommand for AudioGenerator {
    fn serialize_append(&self, result: &mut Vec<ElementType>) -> () {
        match self {
            AudioGenerator::Sine => write_command_marker(NumericCommand::SineGenerator, result),
            AudioGenerator::SineWithFrequency(frequency) => {
                write_command_marker(NumericCommand::SineGeneratorWithFrequency, result);
                result.push(*frequency);
            }
            AudioGenerator::ModulateOp(gen0, gen1) => {
                write_command_marker(NumericCommand::ModulateOp, result);
                gen0.serialize_append(result);
                gen1.serialize_append(result);
            }
            AudioGenerator::MixOp(gen0, gen1) => {
                write_command_marker(NumericCommand::MixOp, result);
                gen0.serialize_append(result);
                gen1.serialize_append(result);
            }
            AudioGenerator::Envelope(attack_t, peak_amp, descent_t) => {
                write_command_marker(NumericCommand::Envelope, result);
                result.push(*attack_t);
                result.push(*peak_amp);
                result.push(*descent_t);
            }
            AudioGenerator::Volume(volume, signal) => {
                write_command_marker(NumericCommand::Volume, result);
                result.push(*volume);
                signal.serialize_append(result);
            }
            AudioGenerator::Bell(freq) => {
                write_command_marker(NumericCommand::Bell, result);
                result.push(*freq);
            }
            AudioGenerator::Custom(freq) => {
                write_command_marker(NumericCommand::Custom, result);
                result.push(*freq);
            }
        }
    }
}

fn write_command_marker(marker: NumericCommand, result: &mut Vec<ElementType>) -> () {
    result.push(marker as u32 as ElementType);
}

pub fn write_command(command: &AudioCommand, event_buffer: &mut CircularBuffer) -> () {
    let mut to_write = vec![0.0]; // Define first element to be overwritten
    command.serialize_append(&mut to_write);
    let total_command_length_including_size_element = to_write.len();
    to_write[0] = total_command_length_including_size_element as f32;

    if event_buffer.can_write_size(total_command_length_including_size_element) {
        event_buffer.write(&to_write);
        println!(">>>> Wrote elements {:?}", to_write);
    }
}

pub fn generate_sine_at_index(index: u32, event_buffer: &mut CircularBuffer) -> () {
    let command = AudioCommand::InsertAtIndex(index, AudioGenerator::Sine);
    write_command(&command, event_buffer);
}

pub fn stop_at_index(index: u32, event_buffer: &mut CircularBuffer) -> () {
    let command = AudioCommand::StopAtIndex(index);
    write_command(&command, event_buffer);
}

pub fn generate_and_forget_sine(event_buffer: &mut CircularBuffer) -> () {
    let command = AudioCommand::InsertAndForget(AudioGenerator::Sine);
    write_command(&command, event_buffer);
}

pub fn enveloped_double_sine_at_index(
    index: u32,
    frequency: f32,
    event_buffer: &mut CircularBuffer,
) -> () {
    let sine0 = AudioGenerator::SineWithFrequency(frequency);
    let sine1 = AudioGenerator::SineWithFrequency(frequency * 0.49);
    let double_sine = AudioGenerator::MixOp(Box::new(sine0), Box::new(sine1));

    let generator = AudioGenerator::ModulateOp(
        Box::new(AudioGenerator::Envelope(0.01, 8.0, 0.05)),
        Box::new(double_sine),
    );

    let command = AudioCommand::InsertAtIndex(index, generator);
    write_command(&command, event_buffer);
}

pub fn generate_bell(frequency: ElementType, event_buffer: &mut CircularBuffer) -> () {
    let generator = AudioGenerator::Bell(frequency);
    let command = AudioCommand::InsertAndForget(generator);
    write_command(&command, event_buffer);
}

pub fn generate_sine_at_index_with_frequency(
    index: u32,
    frequency: ElementType,
    event_buffer: &mut CircularBuffer,
) -> () {
    let sine_with_freq = AudioGenerator::SineWithFrequency(frequency);
    let command = AudioCommand::InsertAtIndex(index, sine_with_freq);
    write_command(&command, event_buffer);
}

pub fn close_stream(event_buffer: &mut CircularBuffer) -> () {
    let command = AudioCommand::Exit;
    write_command(&command, event_buffer);
}
