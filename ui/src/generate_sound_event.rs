use crate::circular_buffer::CircularBuffer;
use std::vec;

type ElementType = f32;

enum NumericCommand {
    InsertAtIndex = 2,
    InsertAndForget = 3,
    StopAtIndex = 4,
    SineGenerator = 1000,
    SineGeneratorWithFrequency = 1001,
    ModulateOp = 1002,
    MixOp = 1003,
    Envelope = 1004,
}

trait AudioCommand {
    fn serialize_append(&self, result: &mut Vec<ElementType>) -> ();
}

enum Command<'a> {
    InsertAtIndex(u32, &'a Generator<'a>),
    InsertAndForget(&'a Generator<'a>),
    StopAtIndex(u32),
}

enum Generator<'a> {
    Sine,
    SineWithFrequency(ElementType),
    ModulateOp(&'a Generator<'a>, &'a Generator<'a>),
    MixOp(&'a Generator<'a>, &'a Generator<'a>),
    Envelope(f32, f32, f32),
}

impl<'a> AudioCommand for Command<'a> {
    fn serialize_append(&self, result: &mut Vec<ElementType>) -> () {
        match self {
            Command::InsertAtIndex(index, generator) => {
                result.push(NumericCommand::InsertAtIndex as u32 as ElementType);
                result.push(*index as ElementType);
                generator.serialize_append(result);
            }
            Command::InsertAndForget(generator) => {
                result.push(NumericCommand::InsertAndForget as u32 as ElementType);
                generator.serialize_append(result);
            }
            Command::StopAtIndex(index) => {
                result.push(NumericCommand::StopAtIndex as u32 as ElementType);
                result.push(*index as ElementType);
            }
        }
    }
}

impl<'a> AudioCommand for Generator<'a> {
    fn serialize_append(&self, result: &mut Vec<ElementType>) -> () {
        match self {
            Generator::Sine => result.push(NumericCommand::SineGenerator as u32 as ElementType),
            Generator::SineWithFrequency(frequency) => {
                result.push(NumericCommand::SineGeneratorWithFrequency as u32 as ElementType);
                result.push(*frequency);
            }
            Generator::ModulateOp(gen0, gen1) => {
                result.push(NumericCommand::ModulateOp as u32 as ElementType);
                gen0.serialize_append(result);
                gen1.serialize_append(result);
            }
            Generator::MixOp(gen0, gen1) => {
                result.push(NumericCommand::MixOp as u32 as ElementType);
                gen0.serialize_append(result);
                gen1.serialize_append(result);
            }
            Generator::Envelope(attack_t, peak_amp, descent_t) => {
                result.push(NumericCommand::Envelope as u32 as ElementType);
                result.push(*attack_t);
                result.push(*peak_amp);
                result.push(*descent_t);
            }
        }
    }
}

fn write_command(command: &Command, event_buffer: &mut CircularBuffer) -> () {
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
    let command = Command::InsertAtIndex(index, &Generator::Sine);
    write_command(&command, event_buffer);
}

pub fn stop_at_index(index: u32, event_buffer: &mut CircularBuffer) -> () {
    let command = Command::StopAtIndex(index);
    write_command(&command, event_buffer);
}

pub fn generate_and_forget_sine(event_buffer: &mut CircularBuffer) -> () {
    let command = Command::InsertAndForget(&Generator::Sine);
    write_command(&command, event_buffer);
}

pub fn enveloped_double_sine_at_index(
    index: u32,
    frequency: f32,
    event_buffer: &mut CircularBuffer,
) -> () {
    let sine0 = Generator::SineWithFrequency(frequency);
    let sine1 = Generator::SineWithFrequency(frequency * 0.49);
    let double_sine = Generator::MixOp(&sine0, &sine1);

    let generator = Generator::ModulateOp(&Generator::Envelope(0.01, 8.0, 0.05), &double_sine);

    let command = Command::InsertAtIndex(index, &generator);
    write_command(&command, event_buffer);
}

pub fn generate_sine_at_index_with_frequency(
    index: u32,
    frequency: ElementType,
    event_buffer: &mut CircularBuffer,
) -> () {
    let sine_with_freq = Generator::SineWithFrequency(frequency);
    let command = Command::InsertAtIndex(index, &sine_with_freq);
    write_command(&command, event_buffer);
}
