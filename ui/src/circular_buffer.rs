const CIRCULAR_BUFFER_SIZE: usize = 1024;

pub struct CircularBuffer {
    pub buffer: [f32; CIRCULAR_BUFFER_SIZE],
    // Use i32 for simple Haskell interoperability
    pub read_index: i32,
    pub write_index: i32,
}

impl CircularBuffer {
    pub fn new() -> Self {
        Self {
            buffer: [0.0; CIRCULAR_BUFFER_SIZE],
            write_index: 0,
            read_index: 0,
        }
    }

    pub fn buffer_size(&self) -> usize {
        CIRCULAR_BUFFER_SIZE
    }

    pub fn can_write_size(&self, size: usize) -> bool {
        return self.free_size() >= size;
    }

    pub fn free_size(&self) -> usize {
        let mut signed_difference = self.read_index - self.write_index;

        if signed_difference <= 0 {
            signed_difference += CIRCULAR_BUFFER_SIZE as i32;
        }

        signed_difference as usize
    }

    pub fn advance_write(&mut self, element_count: usize) -> () {
        let new_index = ((self.write_index as usize) + element_count) % self.buffer_size();
        self.write_index = new_index as i32;
    }

    pub fn write(&mut self, data: &Vec<f32>) -> () {
        if !self.can_write_size(data.len()) {
            panic!("Tried to write data to circular buffer that wouldn't fit");
        }

        for (write_index, data_index) in circular_index_iter(self.write_index as usize)
            .zip(0..)
            .take(data.len())
        {
            self.buffer[write_index] = data[data_index];
        }

        self.advance_write(data.len());
    }
}

fn circular_index_iter(start: usize) -> impl Iterator<Item = usize> {
    return (start..).map(|i| i % CIRCULAR_BUFFER_SIZE);
}
