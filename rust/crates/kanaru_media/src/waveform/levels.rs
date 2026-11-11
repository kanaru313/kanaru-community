//! Reduces decoded audio to at most 1000 loudness levels for the waveform.
//!
//! The length of the track is not known before decoding (VBR MP3 without a
//! header, ADTS), so the accumulator keeps a fixed number of slots and doubles
//! the time each slot covers whenever they are all full. Memory is the same
//! for a 3-second clip and a 24-hour file, and a slot's position is always its
//! time, because the window length is a whole number of frames.

/// Most levels a waveform has.
pub const MAX_LEVELS: usize = 1000;

/// Slots the accumulator keeps; about 128 KB.
pub const SLOT_COUNT: usize = 8192;

/// Sum of squares and sample count of one window of the track.
#[derive(Clone, Copy, Default)]
struct Slot {
    square_sum: f64,
    samples: u64,
}

impl Slot {
    fn merge(&mut self, other: Slot) {
        self.square_sum += other.square_sum;
        self.samples += other.samples;
    }

    fn rms(&self) -> f64 {
        if self.samples == 0 {
            0.0
        } else {
            (self.square_sum / self.samples as f64).sqrt()
        }
    }
}

/// Collects the loudness of a stream of interleaved samples.
pub struct LevelAccumulator {
    slots: Vec<Slot>,
    /// Frames each slot covers now; starts at 10 ms and doubles on a fold.
    window_frames: u64,
    /// Frames the first window had, to tell a clip too short to draw.
    first_window_frames: u64,
    /// Frames pushed so far.
    frames: u64,
}

impl LevelAccumulator {
    /// An accumulator for audio at `sample_rate` Hz (at least 100).
    pub fn new(sample_rate: u32) -> Self {
        Self::with_slots(sample_rate, SLOT_COUNT)
    }

    /// Like [`new`](Self::new) with `slot_count` slots (even, at least 2), so
    /// a folded run can be compared with an unfolded one.
    pub fn with_slots(sample_rate: u32, slot_count: usize) -> Self {
        let window = (u64::from(sample_rate) / 100).max(1);
        Self {
            slots: vec![Slot::default(); slot_count.max(2) & !1],
            window_frames: window,
            first_window_frames: window,
            frames: 0,
        }
    }

    /// Frames pushed so far.
    pub fn frames(&self) -> u64 {
        self.frames
    }

    /// Adds interleaved samples of `channels` channels. A trailing partial
    /// frame is ignored.
    pub fn push(&mut self, interleaved: &[f32], channels: usize) {
        if channels == 0 {
            return;
        }
        let mut rest = interleaved;
        while rest.len() >= channels {
            let index = (self.frames / self.window_frames) as usize;
            if index >= self.slots.len() {
                self.fold();
                continue;
            }
            let room = self.window_frames - self.frames % self.window_frames;
            let frames_here = ((rest.len() / channels) as u64).min(room) as usize;
            let (chunk, remaining) = rest.split_at(frames_here * channels);
            let sum: f64 = chunk.iter().map(|&s| f64::from(s) * f64::from(s)).sum();
            let slot = &mut self.slots[index];
            slot.square_sum += sum;
            slot.samples += chunk.len() as u64;
            self.frames += frames_here as u64;
            rest = remaining;
        }
    }

    /// Merges neighbouring slots pairwise and doubles the window, so the slots
    /// again cover the whole track with room for more.
    fn fold(&mut self) {
        let half = self.slots.len() / 2;
        for i in 0..half {
            let mut merged = self.slots[2 * i];
            merged.merge(self.slots[2 * i + 1]);
            self.slots[i] = merged;
        }
        self.slots[half..].fill(Slot::default());
        self.window_frames *= 2;
    }

    /// The levels and the frames they cover. Empty levels for a clip shorter
    /// than 10 ms. Otherwise `min(1000, used slots)` buckets: loudness is the
    /// RMS of the samples in the bucket, normalised to the loudest bucket and
    /// square-rooted so quiet parts stay visible, then scaled to 0..=255.
    /// Silence gives all zeros.
    pub fn finish(&self) -> (Vec<u8>, u64) {
        if self.frames < self.first_window_frames {
            return (Vec::new(), self.frames);
        }
        let used = self.frames.div_ceil(self.window_frames) as usize;
        let buckets = used.min(MAX_LEVELS);
        let rms: Vec<f64> = (0..buckets)
            .map(|i| {
                let mut total = Slot::default();
                for slot in &self.slots[i * used / buckets..(i + 1) * used / buckets] {
                    total.merge(*slot);
                }
                total.rms()
            })
            .collect();
        let loudest = rms.iter().copied().fold(0.0, f64::max);
        let levels = rms
            .iter()
            .map(|&r| {
                if loudest <= 0.0 {
                    0
                } else {
                    (255.0 * (r / loudest).sqrt()).round().clamp(0.0, 255.0) as u8
                }
            })
            .collect();
        (levels, self.frames)
    }
}
