//! Waveform levels from decoded audio.
//!
//! [`compute`] decodes a whole track with symphonia (pure Rust) and reduces it
//! to at most 1000 loudness levels, one byte each. Tracks the build cannot
//! decode (APE, WavPack, DSD, AIFF, Opus) are refused before any probing and
//! show a flat seek bar.

pub mod decode;
pub mod levels;
pub mod limits;

use symphonia::core::io::MediaSource;

use crate::{Cancel, MediaError};

/// Loudness of one track.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Waveform {
    /// 0..=255 loudness per bucket, at most [`levels::MAX_LEVELS`]; empty for
    /// a track shorter than 10 ms.
    pub levels: Vec<u8>,
    /// Decoded length in milliseconds.
    pub duration_ms: u32,
}

/// Decodes `source` and returns its levels. `ext_hint` is the file extension
/// without the dot. Stops with `Cancelled` or `Timeout` at the next packet
/// once `cancel` says so.
pub fn compute(
    source: Box<dyn MediaSource>,
    ext_hint: Option<&str>,
    cancel: &Cancel,
) -> Result<Waveform, MediaError> {
    let decoded = decode::decode_levels(source, ext_hint, cancel)?;
    let ms = decoded.frames.saturating_mul(1000) / u64::from(decoded.sample_rate.max(1));
    Ok(Waveform {
        levels: decoded.levels,
        duration_ms: u32::try_from(ms).unwrap_or(u32::MAX),
    })
}
