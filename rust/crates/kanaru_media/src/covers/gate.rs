//! Process-wide gate: one decode of a large image at a time. A few decodes
//! of 8+ MP images side by side can use more memory than a phone has; small
//! covers never wait.

use std::sync::{Condvar, Mutex, PoisonError};

/// Images with more pixels than this wait for the gate.
pub const LARGE_DECODE_PIXELS: u64 = 8_000_000;

pub struct Gate {
    busy: Mutex<bool>,
    freed: Condvar,
}

/// Holds the gate until dropped, also when the holder panics.
pub struct GateGuard<'a>(&'a Gate);

impl Gate {
    pub const fn new() -> Self {
        Self {
            busy: Mutex::new(false),
            freed: Condvar::new(),
        }
    }

    /// Blocks until no other guard of this gate lives.
    pub fn enter(&self) -> GateGuard<'_> {
        let mut busy = self.busy.lock().unwrap_or_else(PoisonError::into_inner);
        while *busy {
            busy = self
                .freed
                .wait(busy)
                .unwrap_or_else(PoisonError::into_inner);
        }
        *busy = true;
        GateGuard(self)
    }
}

impl Default for Gate {
    fn default() -> Self {
        Self::new()
    }
}

impl Drop for GateGuard<'_> {
    fn drop(&mut self) {
        *self.0.busy.lock().unwrap_or_else(PoisonError::into_inner) = false;
        self.0.freed.notify_one();
    }
}

static LARGE_DECODES: Gate = Gate::new();

/// The guard for decoding an image of `pixels` pixels, or `None` when the
/// image is small enough to decode without waiting.
pub fn enter_for(pixels: u64) -> Option<GateGuard<'static>> {
    (pixels > LARGE_DECODE_PIXELS).then(|| LARGE_DECODES.enter())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::time::Duration;

    #[test]
    fn at_most_one_holder_at_a_time() {
        let gate = Gate::new();
        let inside = AtomicUsize::new(0);
        let peak = AtomicUsize::new(0);
        std::thread::scope(|scope| {
            for _ in 0..6 {
                scope.spawn(|| {
                    let _guard = gate.enter();
                    let now = inside.fetch_add(1, Ordering::SeqCst) + 1;
                    peak.fetch_max(now, Ordering::SeqCst);
                    std::thread::sleep(Duration::from_millis(5));
                    inside.fetch_sub(1, Ordering::SeqCst);
                });
            }
        });
        assert_eq!(peak.load(Ordering::SeqCst), 1);
    }

    #[test]
    fn a_panicking_holder_frees_the_gate() {
        let gate = Gate::new();
        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            let _guard = gate.enter();
            panic!("decoder gave up");
        }));
        assert!(result.is_err());
        drop(gate.enter());
    }

    #[test]
    fn only_large_images_wait() {
        assert!(enter_for(LARGE_DECODE_PIXELS).is_none());
        assert!(enter_for(LARGE_DECODE_PIXELS + 1).is_some());
    }
}
