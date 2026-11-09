//! Worker pools. Created on first use, never torn down.
//!
//! - `background`: scans (tags, covers); low priority so the UI stays smooth.
//! - `interactive`: work the user waits for (one cover, one track's tags).
//! - `waveform`: one thread; a waveform job decodes a whole track.

use std::sync::OnceLock;

use rayon::{ThreadPool, ThreadPoolBuilder};

use crate::os;

/// Thread counts and stack size in one place.
pub mod config {
    /// Parsers recurse on nested containers (MP4 atoms, Ogg pages); lofty
    /// overflowed the 2 MiB default stack in the old app.
    pub const STACK_BYTES: usize = 8 * 1024 * 1024;
    pub const INTERACTIVE_THREADS: usize = 2;
    pub const WAVEFORM_THREADS: usize = 1;
    /// Android keeps the background pool between 1 and 4 threads.
    pub const ANDROID_MAX_BACKGROUND: usize = 4;

    /// Background threads for `cores` logical cores: desktop leaves one core
    /// to the UI; Android uses half the cores, at most 4 (big.LITTLE phones
    /// throttle when every core is busy).
    pub fn background_threads(cores: usize, android: bool) -> usize {
        if android {
            (cores / 2).clamp(1, ANDROID_MAX_BACKGROUND)
        } else {
            cores.saturating_sub(1).max(1)
        }
    }
}

fn cores() -> usize {
    std::thread::available_parallelism().map_or(1, usize::from)
}

fn builder(name: &'static str, threads: usize, low_priority: bool) -> ThreadPoolBuilder {
    let builder = ThreadPoolBuilder::new()
        .num_threads(threads)
        .stack_size(config::STACK_BYTES)
        .thread_name(move |i| format!("kanaru-{name}-{i}"))
        // A panic in a `spawn`ed job would otherwise abort the process.
        // Jobs that return results go through `guarded`; this is the net.
        .panic_handler(move |payload| {
            let message = payload
                .downcast_ref::<&str>()
                .map(|s| (*s).to_string())
                .or_else(|| payload.downcast_ref::<String>().cloned())
                .unwrap_or_else(|| "panic without message".to_string());
            eprintln!("kanaru {name} pool: job panicked: {message}");
        });
    if low_priority {
        builder.start_handler(|_| os::lower_current_thread_priority())
    } else {
        builder
    }
}

fn build(name: &'static str, threads: usize, low_priority: bool) -> ThreadPool {
    // Building fails only when the OS refuses to start threads; a pool with a
    // single thread (same name, priority and panic handling) is the fallback,
    // and if even that fails there is nothing left to run on.
    builder(name, threads, low_priority)
        .build()
        .or_else(|_| builder(name, 1, low_priority).build())
        .expect("cannot start a worker thread")
}

pub fn background() -> &'static ThreadPool {
    static POOL: OnceLock<ThreadPool> = OnceLock::new();
    POOL.get_or_init(|| {
        build(
            "background",
            config::background_threads(cores(), cfg!(target_os = "android")),
            true,
        )
    })
}

pub fn interactive() -> &'static ThreadPool {
    static POOL: OnceLock<ThreadPool> = OnceLock::new();
    POOL.get_or_init(|| build("interactive", config::INTERACTIVE_THREADS, false))
}

pub fn waveform() -> &'static ThreadPool {
    static POOL: OnceLock<ThreadPool> = OnceLock::new();
    POOL.get_or_init(|| build("waveform", config::WAVEFORM_THREADS, false))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn desktop_leaves_a_core_free() {
        assert_eq!(config::background_threads(8, false), 7);
        assert_eq!(config::background_threads(2, false), 1);
        assert_eq!(config::background_threads(1, false), 1);
    }

    #[test]
    fn android_uses_half_up_to_four() {
        assert_eq!(config::background_threads(8, true), 4);
        assert_eq!(config::background_threads(16, true), 4);
        assert_eq!(config::background_threads(4, true), 2);
        assert_eq!(config::background_threads(1, true), 1);
    }

    #[test]
    fn pools_have_their_sizes() {
        assert_eq!(
            interactive().current_num_threads(),
            config::INTERACTIVE_THREADS
        );
        assert_eq!(waveform().current_num_threads(), config::WAVEFORM_THREADS);
        assert_eq!(
            background().current_num_threads(),
            config::background_threads(cores(), cfg!(target_os = "android"))
        );
    }

    #[test]
    fn jobs_run_on_named_pool_threads_with_the_big_stack() {
        // Probe the stack from a pool thread: grow it by recursion, 64 KiB per
        // frame, 64 frames = 4 MiB, which overflows rayon's default 2 MiB.
        fn grow(depth: usize) -> usize {
            let frame = [depth as u8; 64 * 1024];
            let below = if depth == 0 { 0 } else { grow(depth - 1) };
            below + usize::from(std::hint::black_box(&frame)[0] == depth as u8)
        }
        let (name, depth) = interactive().install(|| {
            let name = std::thread::current().name().map(str::to_owned);
            (name, grow(63))
        });
        assert_eq!(
            name.as_deref()
                .map(|n| n.starts_with("kanaru-interactive-")),
            Some(true)
        );
        assert_eq!(depth, 64);
    }

    #[test]
    fn pool_survives_a_panicking_spawned_job() {
        let pool = build("test", 1, false);
        pool.spawn(|| panic!("job failure"));
        // The single worker must still run work after the panic.
        assert_eq!(pool.install(|| 40 + 2), 42);
    }
}
