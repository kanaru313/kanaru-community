//! Silent panics for host callbacks.
//!
//! A host call that panics (the app's side threw) is an expected failure the
//! runtime turns into a `network` outcome; the default panic hook would still
//! print a message for it. Callbacks run under [`quietly_catching`], which
//! marks the thread, and the hook [`install_quiet_panic_hook`] installs stays
//! silent for marked threads and calls the previous hook for every other panic.

use std::cell::Cell;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::Once;

thread_local! {
    /// True while this thread runs a host callback: its panics are expected and silent.
    static QUIET: Cell<bool> = const { Cell::new(false) };
}

/// Installs (once per process) a panic hook that stays silent for threads
/// running a host callback and otherwise calls the hook that was there before.
/// The embedding app calls this at startup; the runtime itself never changes
/// process state.
pub fn install_quiet_panic_hook() {
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        let previous = std::panic::take_hook();
        std::panic::set_hook(Box::new(move |info| {
            if !QUIET.with(Cell::get) {
                previous(info);
            }
        }));
    });
}

/// Runs `f` with panics marked as expected; the panic payload if it panicked.
pub fn quietly_catching<T>(f: impl FnOnce() -> T) -> Result<T, Box<dyn std::any::Any + Send>> {
    let was = QUIET.with(|q| q.replace(true));
    let result = catch_unwind(AssertUnwindSafe(f));
    QUIET.with(|q| q.set(was));
    result
}

/// Runs `f` with callback panics silenced; `None` if it panicked.
pub fn quietly<T>(f: impl FnOnce() -> T) -> Option<T> {
    quietly_catching(f).ok()
}

#[cfg(test)]
mod tests {
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::Arc;

    use super::*;

    const MARK: &str = "quiet-hook-test-panic";

    fn panic_with_mark() {
        let _ = catch_unwind(|| panic!("{}", MARK));
    }

    /// The only test that installs the process-wide hook: it puts a counting
    /// hook (which still calls the default one) underneath, then checks that
    /// a quiet panic does not reach it and a normal one does.
    #[test]
    fn the_hook_chains_the_previous_one_and_is_silent_only_for_callbacks() {
        let seen = Arc::new(AtomicUsize::new(0));
        let counter = seen.clone();
        let default = std::panic::take_hook();
        std::panic::set_hook(Box::new(move |info| {
            let text = info
                .payload()
                .downcast_ref::<String>()
                .cloned()
                .or_else(|| {
                    info.payload()
                        .downcast_ref::<&str>()
                        .map(|s| (*s).to_owned())
                });
            if text.as_deref() == Some(MARK) {
                counter.fetch_add(1, Ordering::SeqCst);
            } else {
                default(info);
            }
        }));
        install_quiet_panic_hook();
        install_quiet_panic_hook(); // a second call changes nothing

        assert!(quietly_catching(panic_with_mark_inner).is_ok());
        assert_eq!(seen.load(Ordering::SeqCst), 0, "silent inside a callback");
        panic_with_mark();
        assert_eq!(
            seen.load(Ordering::SeqCst),
            1,
            "the previous hook still runs"
        );
        assert!(quietly(|| panic!("{}", MARK)).is_none());
        assert_eq!(seen.load(Ordering::SeqCst), 1, "still silent, and caught");
    }

    fn panic_with_mark_inner() {
        panic_with_mark();
    }

    #[test]
    fn the_quiet_mark_is_restored_after_a_nested_call() {
        let _ = quietly(|| {
            let _ = quietly(|| ());
            assert!(QUIET.with(Cell::get), "still inside the outer callback");
        });
        assert!(!QUIET.with(Cell::get));
    }
}
