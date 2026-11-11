//! Shared helpers of the waveform tests: generated PCM, in-memory WAV and a
//! source that records how it is read.
#![allow(dead_code)]

use std::io::{Cursor, Read, Seek, SeekFrom};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;

use kanaru_media::waveform::{compute, Waveform};
use kanaru_media::{Cancel, MediaError};
use symphonia::core::io::MediaSource;

/// `seconds` of a sine at `amplitude`, `channels` identical interleaved
/// channels. Eight samples per period at 8 kHz would alias; this uses 440 Hz.
pub fn sine(rate: u32, seconds: f64, amplitude: f32, channels: usize) -> Vec<f32> {
    let frames = (seconds * f64::from(rate)) as usize;
    (0..frames)
        .flat_map(|n| {
            let t = n as f32 / rate as f32;
            let v = amplitude * (std::f32::consts::TAU * 440.0 * t).sin();
            std::iter::repeat_n(v, channels)
        })
        .collect()
}

/// A 16-bit PCM WAV file of interleaved `samples`.
pub fn wav(rate: u32, channels: u16, samples: &[f32]) -> Vec<u8> {
    let data_len = (samples.len() * 2) as u32;
    let block = channels * 2;
    let mut out = Vec::with_capacity(44 + samples.len() * 2);
    out.extend(b"RIFF");
    out.extend((36 + data_len).to_le_bytes());
    out.extend(b"WAVEfmt ");
    out.extend(16u32.to_le_bytes());
    out.extend(1u16.to_le_bytes());
    out.extend(channels.to_le_bytes());
    out.extend(rate.to_le_bytes());
    out.extend((rate * u32::from(block)).to_le_bytes());
    out.extend(block.to_le_bytes());
    out.extend(16u16.to_le_bytes());
    out.extend(b"data");
    out.extend(data_len.to_le_bytes());
    for s in samples {
        out.extend(((s.clamp(-1.0, 1.0) * 32767.0) as i16).to_le_bytes());
    }
    out
}

pub fn compute_bytes(bytes: Vec<u8>, ext: Option<&str>) -> Result<Waveform, MediaError> {
    compute(Box::new(Cursor::new(bytes)), ext, &Cancel::new())
}

/// Levels of a mono WAV of `samples` at `rate`.
pub fn wav_levels(rate: u32, samples: &[f32]) -> Waveform {
    compute_bytes(wav(rate, 1, samples), Some("wav")).expect("wav decodes")
}

/// Wraps a source and counts how many `read` calls it served; `on_read` runs
/// before each read with the running count.
pub struct Probe<S> {
    inner: S,
    reads: Arc<AtomicUsize>,
    on_read: Box<dyn Fn(usize) + Send + Sync>,
}

impl<S> Probe<S> {
    pub fn new(
        inner: S,
        on_read: impl Fn(usize) + Send + Sync + 'static,
    ) -> (Self, Arc<AtomicUsize>) {
        let reads = Arc::new(AtomicUsize::new(0));
        (
            Self {
                inner,
                reads: Arc::clone(&reads),
                on_read: Box::new(on_read),
            },
            reads,
        )
    }
}

impl<S: Read> Read for Probe<S> {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        let n = self.reads.fetch_add(1, Ordering::SeqCst) + 1;
        (self.on_read)(n);
        self.inner.read(buf)
    }
}

impl<S: Seek> Seek for Probe<S> {
    fn seek(&mut self, pos: SeekFrom) -> std::io::Result<u64> {
        self.inner.seek(pos)
    }
}

impl<S: Read + Seek + Send + Sync> MediaSource for Probe<S> {
    fn is_seekable(&self) -> bool {
        true
    }
    fn byte_len(&self) -> Option<u64> {
        None
    }
}

pub fn fixture(name: &str) -> Vec<u8> {
    let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests/waveform_fixtures")
        .join(name);
    std::fs::read(&path).unwrap_or_else(|e| panic!("fixture {name}: {e}"))
}
