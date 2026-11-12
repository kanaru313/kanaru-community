//! Dart API for the lyrics stored inside an audio file.
//!
//! Each call runs on its own thread, not on a pool: a read blocked in the
//! kernel (a dead network mount) cannot be cancelled, and a pool would let one
//! such read block every later one. The caller stops waiting after
//! [`READ_TIMEOUT`] and the stuck thread is left behind, but only
//! [`MAX_STUCK_THREADS`] of them are tolerated: while that many threads are
//! still blocked past their timeout, a new read fails at once with a transient
//! `Timeout` without spawning (retrying later is right: a mount may recover,
//! which frees its slot). The cap is checked when a read starts and running
//! reads are not counted, so reads started at the same time can push the stuck
//! count past the cap, up to the cap plus the reads in flight. Callers should
//! run one read at a time.

use std::path::Path;
use std::sync::atomic::{AtomicU8, AtomicUsize, Ordering};
use std::sync::{mpsc, Arc, LazyLock};
use std::time::Duration;

use kanaru_media::tags::lyrics_reader::{read_lyrics, EmbeddedLyrics, SyncedLine};

use crate::error::{NativeError, NativeErrorKind};
use crate::guard::guarded;
use crate::pools;
use crate::source::{open_source, Source};

/// Longest wait for one read.
const READ_TIMEOUT: Duration = Duration::from_secs(10);

/// Most lyrics threads left blocked past their timeout at one time.
const MAX_STUCK_THREADS: usize = 2;

/// Read still running, caller still waiting.
const RUNNING: u8 = 0;
/// Read ended (with any outcome).
const DONE: u8 = 1;
/// Caller timed out; the thread holds one slot of [`StuckThreads`].
const ABANDONED: u8 = 2;

/// Counts the threads abandoned after their timeout and still running.
#[derive(Clone)]
struct StuckThreads {
    cap: usize,
    count: Arc<AtomicUsize>,
}

impl StuckThreads {
    fn new(cap: usize) -> Self {
        Self {
            cap,
            count: Arc::new(AtomicUsize::new(0)),
        }
    }
}

static STUCK: LazyLock<StuckThreads> = LazyLock::new(|| StuckThreads::new(MAX_STUCK_THREADS));

/// Runs when a read thread ends however it ends (result, early return, panic
/// outside `guarded`): marks it done and gives back its slot if abandoned.
struct EndGuard {
    state: Arc<AtomicU8>,
    count: Arc<AtomicUsize>,
}

impl Drop for EndGuard {
    fn drop(&mut self) {
        if self.state.swap(DONE, Ordering::SeqCst) == ABANDONED {
            self.count.fetch_sub(1, Ordering::SeqCst);
        }
    }
}

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
/// file holds none. For MP3, WAV and AIFF any non-transient read failure,
/// including an empty or truncated file, also gives `Ok(None)` (a broken ID3
/// tag means no lyrics); an empty or truncated file of any other format is
/// `Io` (`UnexpectedEof`, permanent). Errors: `NotFound`, `PermissionDenied`, `Unsupported`
/// (not a regular file; a FIFO is never waited on), `Corrupt`, `Io`,
/// `Panic` (parser panic, permanent) and `Timeout` (no answer in 10 s,
/// transient; also returned at once while two earlier reads are still stuck).
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
        &STUCK,
    )
}

/// Runs `work` on its own named thread under `guarded` and waits `timeout`.
/// Refuses without spawning while `stuck` is at its cap.
fn read_with<T: Send + 'static>(
    work: impl FnOnce() -> Result<T, NativeError> + Send + 'static,
    timeout: Duration,
    stuck: &StuckThreads,
) -> Result<T, NativeError> {
    if stuck.count.load(Ordering::SeqCst) >= stuck.cap {
        return Err(NativeError::new(
            NativeErrorKind::Timeout,
            "too many stuck lyrics reads",
            true,
        ));
    }
    let (sender, receiver) = mpsc::channel();
    let state = Arc::new(AtomicU8::new(RUNNING));
    let end = EndGuard {
        state: state.clone(),
        count: stuck.count.clone(),
    };
    // On a spawn failure the closure (and `end`) is dropped: the state is
    // swapped to DONE from RUNNING, so the counter is untouched.
    std::thread::Builder::new()
        .name("kanaru-lyrics".into())
        .stack_size(pools::config::STACK_BYTES)
        .spawn(move || {
            let _end = end;
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
        Err(mpsc::RecvTimeoutError::Timeout) => {
            // Count first, then claim: the thread frees the slot only after
            // seeing ABANDONED, so the counter never underflows.
            stuck.count.fetch_add(1, Ordering::SeqCst);
            if state
                .compare_exchange(RUNNING, ABANDONED, Ordering::SeqCst, Ordering::SeqCst)
                .is_err()
            {
                // The thread finished just now; nothing is stuck. It sends its
                // result before it ends, so the result is already waiting.
                stuck.count.fetch_sub(1, Ordering::SeqCst);
                if let Ok(result) = receiver.try_recv() {
                    return result;
                }
            }
            Err(NativeError::new(
                NativeErrorKind::Timeout,
                "lyrics read did not finish in time",
                true,
            ))
        }
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

    use std::sync::atomic::AtomicBool;
    use std::time::Instant;

    fn quick(stuck: &StuckThreads) -> Result<i32, NativeError> {
        read_with(|| Ok(7), Duration::from_secs(5), stuck)
    }

    /// Starts a read blocked until `release` is sent; returns its timeout error.
    fn blocked_read(stuck: &StuckThreads) -> mpsc::Sender<()> {
        let (release, wait) = mpsc::channel::<()>();
        let err = read_with(
            move || {
                let _ = wait.recv();
                Ok(1)
            },
            Duration::from_millis(30),
            stuck,
        )
        .unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Timeout);
        release
    }

    fn wait_for_count(stuck: &StuckThreads, want: usize) {
        for _ in 0..500 {
            if stuck.count.load(Ordering::SeqCst) == want {
                return;
            }
            std::thread::sleep(Duration::from_millis(10));
        }
        panic!("count never reached {want}");
    }

    #[test]
    fn slow_read_times_out_as_transient() {
        let stuck = StuckThreads::new(2);
        let started = Instant::now();
        let err = read_with(
            || {
                std::thread::sleep(Duration::from_millis(600));
                Ok(1)
            },
            Duration::from_millis(50),
            &stuck,
        )
        .unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Timeout);
        assert!(err.transient);
        assert!(started.elapsed() < Duration::from_millis(500));
        wait_for_count(&stuck, 0);
    }

    #[test]
    fn panic_is_permanent_panic_error() {
        let stuck = StuckThreads::new(2);
        let err = read_with::<()>(|| panic!("parser exploded"), Duration::from_secs(5), &stuck)
            .unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Panic);
        assert!(!err.transient);
        assert!(err.detail.contains("parser exploded"));
    }

    #[test]
    fn normal_read_returns_value_and_leaves_no_stuck_thread() {
        let stuck = StuckThreads::new(2);
        assert_eq!(quick(&stuck), Ok(7));
        assert_eq!(stuck.count.load(Ordering::SeqCst), 0);
    }

    #[test]
    fn reads_are_refused_while_the_cap_of_stuck_threads_is_reached() {
        let stuck = StuckThreads::new(2);
        let releases = [blocked_read(&stuck), blocked_read(&stuck)];
        assert_eq!(stuck.count.load(Ordering::SeqCst), 2);

        let ran = Arc::new(AtomicBool::new(false));
        let flag = ran.clone();
        let started = Instant::now();
        let err = read_with(
            move || {
                flag.store(true, Ordering::SeqCst);
                Ok(1)
            },
            Duration::from_secs(5),
            &stuck,
        )
        .unwrap_err();
        assert_eq!(err.kind, NativeErrorKind::Timeout);
        assert!(err.transient);
        assert!(err.detail.contains("too many stuck"));
        assert!(started.elapsed() < Duration::from_millis(500));
        // Give a wrongly spawned thread time to run before checking.
        std::thread::sleep(Duration::from_millis(50));
        assert!(!ran.load(Ordering::SeqCst));

        for release in releases {
            let _ = release.send(());
        }
        wait_for_count(&stuck, 0);
    }

    #[test]
    fn a_recovered_thread_frees_its_slot() {
        let stuck = StuckThreads::new(1);
        let release = blocked_read(&stuck);
        assert_eq!(stuck.count.load(Ordering::SeqCst), 1);
        assert!(quick(&stuck).is_err());

        release.send(()).unwrap();
        wait_for_count(&stuck, 0);
        assert_eq!(quick(&stuck), Ok(7));
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
