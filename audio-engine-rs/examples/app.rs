use winit::event_loop::{ControlFlow, EventLoop};

use winit::{
    application::ApplicationHandler,
    event::{ElementState, WindowEvent},
    event_loop::ActiveEventLoop,
    keyboard::{Key, KeyCode, PhysicalKey},
    window::{Window, WindowId},
};

use audio_engine_rs::{
    create_sound_buffer, enveloped_double_sine_at_index, generate_and_forget_sine, generate_bell,
    stop_at_index, write_command, AudioCommand, AudioGenerator, CircularBuffer,
};

fn main() {
    let event_loop = EventLoop::new().unwrap();
    event_loop.set_control_flow(ControlFlow::Wait);

    let sound_event_buffer = create_sound_buffer();

    let mut app = App::new(sound_event_buffer);
    let _ = event_loop.run_app(&mut app);
}

pub struct App {
    window: Option<Window>,
    sound_event_buffer: Box<CircularBuffer>,
    shift_pressed: bool,
}

impl App {
    pub fn new(sound_event_buffer: Box<CircularBuffer>) -> Self {
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

                    if event.logical_key == Key::Character("g".into()) {
                        write_command(
                            &AudioCommand::InsertAtIndex(100001, AudioGenerator::Custom(440.0)),
                            &mut self.sound_event_buffer,
                        );
                    }

                    if event.logical_key == Key::Character("c".into()) {
                        write_command(
                            &AudioCommand::InsertAtIndex(100002, AudioGenerator::Custom2(440.0)),
                            &mut self.sound_event_buffer,
                        );
                    }

                    let maybe_index = find_index_for_key_event(event.physical_key);
                    println!("Physical key: {:?}", event.physical_key);
                    return match maybe_index {
                        Some(index) => {
                            let frequency = 440.0 * 2.0f32.powf(index as f32 / 12.0);
                            if !self.shift_pressed {
                                enveloped_double_sine_at_index(
                                    index as u32,
                                    frequency,
                                    &mut self.sound_event_buffer,
                                );
                            } else {
                                generate_bell(frequency, &mut self.sound_event_buffer);
                            }
                        }
                        None => (),
                    };
                } else if event.state == ElementState::Released {
                    if event.logical_key == Key::Character("g".into()) {
                        write_command(
                            &AudioCommand::StopAtIndex(100001),
                            &mut self.sound_event_buffer,
                        );
                    }

                    if event.logical_key == Key::Character("c".into()) {
                        write_command(
                            &AudioCommand::StopAtIndex(100002),
                            &mut self.sound_event_buffer,
                        );
                    }

                    let maybe_index = find_index_for_key_event(event.physical_key);

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
