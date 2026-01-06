use circular_buffer::CircularBuffer;
use generate_sound_event::{
    enveloped_double_sine_at_index, generate_and_forget_sine, generate_bell,
    generate_sine_at_index, generate_sine_at_index_with_frequency, stop_at_index,
};
use std::thread;
use winit::application::ApplicationHandler;
use winit::event::{ElementState, KeyEvent, WindowEvent};
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::keyboard::{Key, KeyCode, NativeKeyCode, PhysicalKey};
use winit::window::{Window, WindowId};

mod circular_buffer;
mod generate_sound_event;

unsafe extern "C" {
    fn play_hs(
        buffer_ptr: *const f32,
        buffer_size: i32,
        read_index_ptr: *mut i32,
        write_index_ptr: *mut i32,
    ) -> ();
    fn init_hs() -> ();
    fn exit_hs() -> ();
}

struct App {
    window: Option<Window>,
    sound_event_buffer: Box<CircularBuffer>,
    shift_pressed: bool,
}

impl App {
    fn new(sound_event_buffer: Box<CircularBuffer>) -> Self {
        Self {
            window: None,
            sound_event_buffer,
            shift_pressed: false,
        }
    }
}

impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        self.window = Some(
            event_loop
                .create_window(Window::default_attributes())
                .unwrap(),
        );
    }

    fn window_event(&mut self, event_loop: &ActiveEventLoop, id: WindowId, event: WindowEvent) {
        match event {
            WindowEvent::CloseRequested => {
                println!("The close button was pressed; stopping");
                event_loop.exit();
            }
            WindowEvent::RedrawRequested => {
                // Redraw the application.
                //
                // It's preferable for applications that do not render continuously to render in
                // this event rather than in AboutToWait, since rendering in here allows
                // the program to gracefully handle redraws requested by the OS.

                // Draw.

                // Queue a RedrawRequested event.
                //
                // You only need to call this if you've determined that you need to redraw in
                // applications which do not always need to. Applications that redraw continuously
                // can render here instead.
                self.window.as_ref().unwrap().request_redraw();
            }
            WindowEvent::KeyboardInput {
                device_id: _device,
                event,
                is_synthetic: synthetic,
            } => {
                if event.physical_key == PhysicalKey::Code(winit::keyboard::KeyCode::Escape) {
                    println!("Escape was pressed; stopping");

                    event_loop.exit();
                }

                if event.physical_key == PhysicalKey::Code(winit::keyboard::KeyCode::ShiftLeft) {
                    self.shift_pressed = event.state.is_pressed();
                    return;
                }

                if event.state == ElementState::Pressed {
                    if event.repeat || synthetic {
                        return;
                    }

                    if event.logical_key == Key::Character("g".into()) && !event.repeat {
                        return generate_and_forget_sine(self.sound_event_buffer.as_mut());
                    }

                    let maybe_index = find_index_for_key_event(event.physical_key);
                    println!("Physical key: {:?}", event.physical_key);
                    return match maybe_index {
                        Some(index) => {
                            let frequency = 440.0 * 2.0f32.powf(index as f32 / 12.0);
                            /* generate_sine_at_index_with_frequency(
                                                index as u32,
                                                frequency,
                                                &mut self.sound_event_buffer,
                            ); */

                            if !self.shift_pressed {
                                enveloped_double_sine_at_index(
                                    index as u32,
                                    frequency,
                                    &mut self.sound_event_buffer,
                                );
                            } else {
                                generate_bell(
                                    index as u32,
                                    frequency,
                                    &mut self.sound_event_buffer,
                                );
                            }
                        }
                        None => (),
                    };
                } else if event.state == ElementState::Released {
                    let maybe_index = find_index_for_key_event(event.physical_key);

                    println!(">>>> Released! Found maybe_index {:?}", maybe_index);

                    return match maybe_index {
                        Some(index) => stop_at_index(index as u32, &mut self.sound_event_buffer),
                        None => (),
                    };
                }
            }
            _ => (),
        }
    }
}

fn find_index_for_key_event(key: PhysicalKey) -> Option<usize> {
    let char_list = [
        (0, PhysicalKey::Code(KeyCode::KeyA)),
        (2, PhysicalKey::Code(KeyCode::KeyS)),
        (4, PhysicalKey::Code(KeyCode::KeyD)),
        (5, PhysicalKey::Code(KeyCode::KeyF)),
        (7, PhysicalKey::Code(KeyCode::KeyG)),
        (9, PhysicalKey::Code(KeyCode::KeyH)),
        (11, PhysicalKey::Code(KeyCode::KeyJ)),
        (12, PhysicalKey::Code(KeyCode::KeyK)),
        (14, PhysicalKey::Code(KeyCode::KeyL)),
        (16, PhysicalKey::Code(KeyCode::Semicolon)),
        (17, PhysicalKey::Code(KeyCode::Quote)),
        (19, PhysicalKey::Code(KeyCode::Backslash)),
    ];
    let pair = char_list
        .iter()
        .find(|(_, ch)| key == *ch)
        .map(|(ind, _)| *ind);

    pair
}

fn main() {
    let event_loop = EventLoop::new().unwrap();

    let mut sound_event_buffer = Box::new(CircularBuffer::new());

    let buffer_ptr_as_usize = sound_event_buffer.buffer.as_ptr() as usize;
    let buffer_size = sound_event_buffer.buffer_size() as i32;
    let read_index_ptr = &mut sound_event_buffer.read_index as *mut i32;
    let read_as_usize = read_index_ptr as usize;
    let write_index_ptr = &mut sound_event_buffer.write_index as *mut i32;
    let write_as_usize = write_index_ptr as usize;

    let _ = thread::spawn(move || {
        // thread code
        unsafe {
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
        }
    });

    // ControlFlow::Poll continuously runs the event loop, even if the OS hasn't
    // dispatched any events. This is ideal for games and similar applications.
    event_loop.set_control_flow(ControlFlow::Poll);

    // ControlFlow::Wait pauses the event loop if no events are available to process.
    // This is ideal for non-game applications that only update in response to user
    // input, and uses significantly less power/CPU time than ControlFlow::Poll.
    event_loop.set_control_flow(ControlFlow::Wait);

    let mut app = App::new(sound_event_buffer);
    event_loop.run_app(&mut app);
}
