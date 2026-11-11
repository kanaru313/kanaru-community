//! Limits that keep an untrusted audio file from exhausting time or memory
//! while it is decoded for a waveform.

use std::ops::RangeInclusive;

use crate::MediaError;

use super::levels::LevelAccumulator;

/// Sample rates accepted, in Hz.
pub const RATES: RangeInclusive<u32> = 8_000..=768_000;
/// Channel counts accepted.
pub const CHANNELS: RangeInclusive<usize> = 1..=32;
/// Longest decoded audio accepted, in seconds (24 hours).
pub const MAX_SECONDS: u64 = 24 * 60 * 60;
/// Packets that fail to decode in a row before the file counts as broken.
pub const MAX_CONSECUTIVE_ERRORS: u32 = 32;
/// Packets that fail to decode, plus container resets, before the file counts
/// as broken. A chained Ogg album needs one reset per track.
pub const MAX_TOTAL_ERRORS: u32 = 1000;

/// Extensions of formats symphonia has no demuxer or decoder for. Its MP3
/// reader would otherwise take compressed APE, WavPack or AIFF bytes for a few
/// MP3 frames and draw noise, so these are refused before any probing. Opus is
/// refused here too: an Ogg Opus file would only fail later, after a probe.
pub const NO_DECODER_EXTENSIONS: [&str; 7] = ["ape", "wv", "dsf", "dff", "aif", "aiff", "opus"];
/// The same formats by their first four bytes, for files with a wrong name.
pub const NO_DECODER_MAGIC: [&[u8; 4]; 5] = [b"MAC ", b"wvpk", b"DSD ", b"FRM8", b"FORM"];

/// `Unsupported` for a format this build cannot decode, by extension or by the
/// first four bytes of the file.
pub fn refuse_undecodable(ext_hint: Option<&str>, magic: &[u8; 4]) -> Result<(), MediaError> {
    let by_name = ext_hint.is_some_and(|e| {
        NO_DECODER_EXTENSIONS
            .iter()
            .any(|x| x.eq_ignore_ascii_case(e))
    });
    if by_name || NO_DECODER_MAGIC.contains(&magic) {
        Err(MediaError::Unsupported)
    } else {
        Ok(())
    }
}

fn corrupt(reason: &str) -> MediaError {
    MediaError::Corrupt(reason.to_string())
}

/// Rate and channel count within the limits, or `Corrupt`.
pub fn check_shape(rate: u32, channels: usize) -> Result<(), MediaError> {
    if RATES.contains(&rate) && CHANNELS.contains(&channels) {
        Ok(())
    } else {
        Err(corrupt("sample rate or channels out of range"))
    }
}

/// Counts packets that failed to decode and container resets.
#[derive(Default)]
pub struct ErrorBudget {
    consecutive: u32,
    total: u32,
}

impl ErrorBudget {
    /// A packet decoded: the run of failures is over.
    pub fn packet_decoded(&mut self) {
        self.consecutive = 0;
    }

    /// A packet failed to decode and was skipped.
    pub fn packet_failed(&mut self) -> Result<(), MediaError> {
        self.consecutive += 1;
        self.total += 1;
        if self.consecutive > MAX_CONSECUTIVE_ERRORS || self.total > MAX_TOTAL_ERRORS {
            return Err(corrupt("too many undecodable packets"));
        }
        Ok(())
    }

    /// The container asked for new decoders.
    pub fn reset(&mut self) -> Result<(), MediaError> {
        self.total += 1;
        if self.total > MAX_TOTAL_ERRORS {
            return Err(corrupt("too many stream resets"));
        }
        Ok(())
    }
}

/// Rate, channels and levels of the stream being decoded.
pub struct Streaming {
    shape: Option<(u32, usize)>,
    levels: Option<LevelAccumulator>,
    max_seconds: u64,
}

impl Streaming {
    pub fn new() -> Self {
        Self::with_max_seconds(MAX_SECONDS)
    }

    /// Like [`new`](Self::new) with a shorter duration limit.
    pub fn with_max_seconds(seconds: u64) -> Self {
        Self {
            shape: None,
            levels: None,
            max_seconds: seconds,
        }
    }

    /// Adds interleaved samples of a decoded buffer after checking its shape
    /// against the limits and against the buffers before it. A file over the
    /// duration limit is `TooLarge`.
    pub fn push(&mut self, rate: u32, channels: usize, samples: &[f32]) -> Result<(), MediaError> {
        match self.shape {
            None => {
                check_shape(rate, channels)?;
                self.shape = Some((rate, channels));
                self.levels = Some(LevelAccumulator::new(rate));
            }
            Some(shape) if shape != (rate, channels) => {
                return Err(corrupt("sample rate or channels changed"));
            }
            Some(_) => {}
        }
        let Some(levels) = self.levels.as_mut() else {
            return Err(corrupt("no audio decoded"));
        };
        levels.push(samples, channels);
        if levels.frames() > u64::from(rate) * self.max_seconds {
            return Err(MediaError::TooLarge);
        }
        Ok(())
    }

    /// Levels, frames and sample rate; `Corrupt` when nothing was decoded.
    pub fn finish(self) -> Result<(Vec<u8>, u64, u32), MediaError> {
        match (self.shape, self.levels) {
            (Some((rate, _)), Some(levels)) if levels.frames() > 0 => {
                let (levels, frames) = levels.finish();
                Ok((levels, frames, rate))
            }
            _ => Err(corrupt("no audio decoded")),
        }
    }
}

impl Default for Streaming {
    fn default() -> Self {
        Self::new()
    }
}
