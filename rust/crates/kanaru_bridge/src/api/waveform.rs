//! Dart API for waveform levels.
//!
//! One job per track: Dart makes a [`WaveformJob`], passes it to
//! [`waveform_levels`] and may call `cancel()` at any time (the track changed,
//! the seek bar went away, the Dart-side timeout fired). The decode runs only
//! on the single-thread waveform pool, so jobs queue there; a job that is
//! cancelled while queued ends as soon as it starts.

use std::path::Path;
use std::time::Duration;

use flutter_rust_bridge::frb;
use kanaru_media::waveform::{compute, Waveform};
use kanaru_media::Cancel;

use crate::error::NativeError;
use crate::guard::guarded;
use crate::pools;
use crate::source::{open_source, Source};

/// Longest a decode may run, whatever Dart does: 60 s covers a 24 h file on a
/// slow disk without letting a stuck decode hold the pool for good.
const DECODE_DEADLINE: Duration = Duration::from_secs(60);

/// Handle that cancels one [`waveform_levels`] call. Opaque to Dart.
#[frb(opaque)]
pub struct WaveformJob {
    cancel: Cancel,
}

impl WaveformJob {
    #[frb(sync)]
    pub fn new() -> WaveformJob {
        WaveformJob {
            cancel: Cancel::new(),
        }
    }

    /// Stops the decode at its next packet (about 200 ms at most). Safe to
    /// call before, during or after the decode, and more than once.
    #[frb(sync)]
    pub fn cancel(&self) {
        self.cancel.cancel();
    }
}

#[frb(ignore)]
impl Default for WaveformJob {
    fn default() -> Self {
        Self::new()
    }
}

/// Loudness of one track, ready to draw.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WaveformDto {
    /// At most 1000 values, 0..=255; empty for a track under 10 ms.
    pub levels: Vec<u8>,
    pub duration_ms: u32,
}

impl From<Waveform> for WaveformDto {
    fn from(w: Waveform) -> Self {
        WaveformDto {
            levels: w.levels,
            duration_ms: w.duration_ms,
        }
    }
}

/// Decodes the file at `path` into levels on the waveform pool.
///
/// Errors: `Cancelled` and `Timeout` are transient (retry later);
/// `Unsupported`, `Corrupt`, `TooLarge` and `Panic` are permanent for this
/// version of the file; I/O kinds follow `NativeError`.
pub fn waveform_levels(path: String, job: &WaveformJob) -> Result<WaveformDto, NativeError> {
    let cancel = job.cancel.with_timeout(DECODE_DEADLINE);
    run_on_pool(move || decode_path(&path, &cancel))
}

/// Runs `work` on the waveform pool; a panic in it becomes `Panic`.
fn run_on_pool<T: Send>(
    work: impl FnOnce() -> Result<T, NativeError> + Send,
) -> Result<T, NativeError> {
    pools::waveform().install(|| guarded(work))
}

fn decode_path(path: &str, cancel: &Cancel) -> Result<WaveformDto, NativeError> {
    // A job cancelled while it waited for the pool never opens the file.
    cancel.check()?;
    let file = open_source(&Source::Path(path.to_string()))?;
    let ext = Path::new(path).extension().and_then(|e| e.to_str());
    Ok(compute(Box::new(file), ext, cancel)?.into())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::error::NativeErrorKind;

    /// A mono 16-bit WAV of `seconds` of a 440 Hz sine at 8 kHz.
    fn wav_bytes(seconds: usize) -> Vec<u8> {
        let frames = 8000 * seconds;
        let mut out = Vec::new();
        out.extend(b"RIFF");
        out.extend(((36 + frames * 2) as u32).to_le_bytes());
        out.extend(b"WAVEfmt ");
        out.extend(16u32.to_le_bytes());
        out.extend(1u16.to_le_bytes());
        out.extend(1u16.to_le_bytes());
        out.extend(8000u32.to_le_bytes());
        out.extend(16_000u32.to_le_bytes());
        out.extend(2u16.to_le_bytes());
        out.extend(16u16.to_le_bytes());
        out.extend(b"data");
        out.extend(((frames * 2) as u32).to_le_bytes());
        for n in 0..frames {
            let v = (std::f32::consts::TAU * 440.0 * n as f32 / 8000.0).sin() * 0.5;
            out.extend(((v * 32767.0) as i16).to_le_bytes());
        }
        out
    }

    fn temp_wav(name: &str, seconds: usize) -> String {
        let path =
            std::env::temp_dir().join(format!("kanaru-waveform-{}-{name}.wav", std::process::id()));
        std::fs::write(&path, wav_bytes(seconds)).expect("write test wav");
        path.to_string_lossy().into_owned()
    }

    #[test]
    fn levels_come_back_through_the_pool() {
        let path = temp_wav("levels", 2);
        let dto = waveform_levels(path.clone(), &WaveformJob::new());
        std::fs::remove_file(&path).expect("remove test wav");
        let dto = dto.expect("decoded");
        assert_eq!(dto.levels.len(), 200);
        assert_eq!(dto.duration_ms, 2000);
    }

    #[test]
    fn a_cancelled_job_is_a_transient_cancelled_error() {
        let path = temp_wav("cancel", 2);
        let job = WaveformJob::new();
        job.cancel();
        let err = waveform_levels(path.clone(), &job).unwrap_err();
        std::fs::remove_file(&path).expect("remove test wav");
        assert_eq!(err.kind, NativeErrorKind::Cancelled);
        assert!(err.transient);
    }

    #[test]
    fn a_missing_file_is_a_permanent_not_found() {
        let err = waveform_levels("/nonexistent/kanaru/none.flac".into(), &WaveformJob::new())
            .unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::NotFound);
        assert!(!err.transient);
    }

    #[test]
    fn an_unsupported_format_is_permanent() {
        let path = std::env::temp_dir().join(format!("kanaru-waveform-{}.ape", std::process::id()));
        std::fs::write(&path, b"MAC 0000").expect("write test file");
        let result = waveform_levels(path.to_string_lossy().into_owned(), &WaveformJob::new());
        std::fs::remove_file(&path).expect("remove test file");
        let err = result.unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Unsupported);
        assert!(!err.transient);
    }

    #[test]
    fn a_panic_on_the_pool_is_a_permanent_panic_error() {
        let err = run_on_pool(|| -> Result<(), NativeError> { panic!("decoder bug") }).unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Panic);
        assert_eq!(err.detail, "decoder bug");
        assert!(!err.transient);
        // The single waveform thread still serves the next job.
        assert_eq!(run_on_pool(|| Ok::<_, NativeError>(7)), Ok(7));
    }
}
