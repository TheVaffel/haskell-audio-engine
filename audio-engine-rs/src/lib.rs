mod circular_buffer;
mod foreign_interface;
mod generate_sound_event;

use std::thread;

pub use circular_buffer::CircularBuffer;
pub use foreign_interface::{AudioCommand, AudioGenerator};
pub use generate_sound_event::*;

unsafe extern "C" {
    pub fn play_hs(
        buffer_ptr: *const f32,
        buffer_size: i32,
        read_index_ptr: *mut i32,
        write_index_ptr: *mut i32,
    ) -> ();
    pub fn init_hs() -> ();
    pub fn exit_hs() -> ();
}

pub fn create_sound_buffer() -> Box<CircularBuffer> {
    let mut sound_event_buffer = Box::new(CircularBuffer::new());

    let buffer_ptr_as_usize = sound_event_buffer.buffer.as_ptr() as usize;
    let buffer_size = sound_event_buffer.buffer_size() as i32;
    let read_index_ptr = &mut sound_event_buffer.read_index as *mut i32;
    let read_as_usize = read_index_ptr as usize;
    let write_index_ptr = &mut sound_event_buffer.write_index as *mut i32;
    let write_as_usize = write_index_ptr as usize;

    let _ = thread::spawn(move || unsafe {
        println!(">> Initializing Haskell");
        init_hs();
        println!(">> Initializing sound loop");
        play_hs(
            buffer_ptr_as_usize as *mut f32,
            buffer_size,
            read_as_usize as *mut i32,
            write_as_usize as *mut i32,
        );

        println!(">> Exited sound loop");
        exit_hs();
        println!(">> Exited Haskell");
    });

    sound_event_buffer
}
