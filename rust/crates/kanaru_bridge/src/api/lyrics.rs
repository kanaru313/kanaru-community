//! Dart API for the lyrics stored inside an audio file.
//!
//! Each call runs on its own thread, not on a pool: a read blocked in the
//! kernel (a dead network mount) cannot be cancelled, and a pool would let one
//! such read block every later one. The caller stops waiting after
//! [`READ_TIMEOUT`] and the stuck thread is left behind (accepted leak).

use std::path::Path;
use std::sync::mpsc;
use std::time::Duration;

use kanaru_media::tags::lyrics_reader::{read_lyrics, EmbeddedLyrics, SyncedLine};

use crate::error::{NativeError, NativeErrorKind};
use crate::guard::guarded;
use crate::pools;
use crate::source::{open_source, Source};

/// Longest wait for one read.
const READ_TIMEOUT: Duration = Duration::from_secs(10);

/// The lyrics stored in one audio file. At least one part is present.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EmbeddedLyricsDto {
    /// Plain or LRC text as stored in the file; the caller parses LRC.
    pub text: Option<String>,
    /// Lines of an ID3v2 `SYLT` frame, sorted by time; empty when none.
    pub synced: Vec<SyncedLyricLineDto>,
}

/// One timed line of synchronized lyrics.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyncedLyricLineDto {
    /// Start of the line in milliseconds from the start of the track.
    pub time_ms: i64,
    pub text: String,
}

#[flutter_rust_bridge::frb(ignore)]
impl From<SyncedLine> for SyncedLyricLineDto {
    fn from(line: SyncedLine) -> Self {
        Self {
            time_ms: i64::from(line.time_ms),
            text: line.text,
        }
    }
}

#[flutter_rust_bridge::frb(ignore)]
impl From<EmbeddedLyrics> for EmbeddedLyricsDto {
    fn from(lyrics: EmbeddedLyrics) -> Self {
        Self {
            text: lyrics.text,
            synced: lyrics.synced.into_iter().map(Into::into).collect(),
        }
    }
}

/// Reads the lyrics embedded in the audio file at `path`: `Ok(None)` when the
/// file holds none. Errors: `NotFound`, `PermissionDenied`, `Unsupported`
/// (not a regular file; a FIFO is never waited on), `Corrupt`, `Io`,
/// `Panic` (parser panic, permanent) and `Timeout` (no answer in 10 s,
/// transient).
pub fn read_embedded_lyrics(path: String) -> Result<Option<EmbeddedLyricsDto>, NativeError> {
    read_with(
        move || {
            let ext = Path::new(&path)
                .extension()
                .map(|e| e.to_string_lossy().to_ascii_lowercase());
            let file = open_source(&Source::Path(path))?;
            read_lyrics(file, ext.as_deref())
                .map(|found| found.map(Into::into))
                .map_err(Into::into)
        },
        READ_TIMEOUT,
    )
}

/// Runs `work` on its own named thread under `guarded` and waits `timeout`.
fn read_with<T: Send + 'static>(
    work: impl FnOnce() -> Result<T, NativeError> + Send + 'static,
    timeout: Duration,
) -> Result<T, NativeError> {
    let (sender, receiver) = mpsc::channel();
    std::thread::Builder::new()
        .name("kanaru-lyrics".into())
        .stack_size(pools::config::STACK_BYTES)
        .spawn(move || {
            // The caller may have stopped waiting; nothing to do then.
            let _ = sender.send(guarded(work));
        })
        .map_err(|e| {
            NativeError::new(
                NativeErrorKind::Io,
                format!("cannot start lyrics thread: {e}"),
                true,
            )
        })?;
    match receiver.recv_timeout(timeout) {
        Ok(result) => result,
        Err(mpsc::RecvTimeoutError::Timeout) => Err(NativeError::new(
            NativeErrorKind::Timeout,
            "lyrics read did not finish in time",
            true,
        )),
        // The thread ended without a result, which `guarded` rules out for a
        // panic: an internal failure that says nothing about the file, so retry.
        Err(mpsc::RecvTimeoutError::Disconnected) => Err(NativeError::new(
            NativeErrorKind::Io,
            "lyrics thread ended without a result",
            true,
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn slow_read_times_out_as_transient() {
        let started = std::time::Instant::now();
        let err = read_with(
            || {
                std::thread::sleep(Duration::from_millis(600));
                Ok(1)
            },
            Duration::from_millis(50),
        )
        .unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Timeout);
        assert!(err.transient);
        assert!(started.elapsed() < Duration::from_millis(500));
    }

    #[test]
    fn panic_is_permanent_panic_error() {
        let err =
            read_with::<()>(|| panic!("parser exploded"), Duration::from_secs(5)).unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Panic);
        assert!(!err.transient);
        assert!(err.detail.contains("parser exploded"));
    }

    #[test]
    fn normal_read_returns_value() {
        assert_eq!(read_with(|| Ok(7), Duration::from_secs(5)), Ok(7));
    }

    #[test]
    fn dto_maps_time_and_text() {
        let dto: EmbeddedLyricsDto = EmbeddedLyrics {
            text: Some("la".into()),
            synced: vec![SyncedLine {
                time_ms: u32::MAX,
                text: "line".into(),
            }],
        }
        .into();
        assert_eq!(dto.text.as_deref(), Some("la"));
        assert_eq!(dto.synced[0].time_ms, i64::from(u32::MAX));
        assert_eq!(dto.synced[0].text, "line");
    }
}
