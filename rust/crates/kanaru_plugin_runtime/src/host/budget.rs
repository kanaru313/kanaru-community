//! The per-job cap on bytes the host keeps in Rust memory for the script
//! (unread fetch bodies, HTML arenas). QuickJS' heap cap does not see Rust
//! allocations, so every such holder charges this budget.

use std::cell::Cell;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

/// Bytes charged so far against a limit. Single-threaded (the JS thread).
pub struct ByteBudget {
    used: Cell<usize>,
    limit: usize,
    /// Set the first time a charge is refused. It stays set: a script that
    /// catches the resulting `RangeError` still ends with status `memory`.
    hit: Arc<AtomicBool>,
}

impl ByteBudget {
    pub fn new(limit: usize, hit: Arc<AtomicBool>) -> Self {
        Self {
            used: Cell::new(0),
            limit,
            hit,
        }
    }

    /// Charges `bytes`; false (and the `hit` flag set, nothing charged) when
    /// that would pass the limit.
    pub fn try_charge(&self, bytes: usize) -> bool {
        match self.used.get().checked_add(bytes) {
            Some(total) if total <= self.limit => {
                self.used.set(total);
                true
            }
            _ => {
                self.hit.store(true, Ordering::SeqCst);
                false
            }
        }
    }

    /// Marks the budget as overrun without charging, for a holder that
    /// refuses on its own limit (an oversized document) and wants the same
    /// outcome as a budget overrun: the call ends `memory`.
    #[cfg_attr(not(test), expect(dead_code, reason = "used by the HTML natives"))]
    pub fn mark_hit(&self) {
        self.hit.store(true, Ordering::SeqCst);
    }

    /// Gives `bytes` back (a holder was released).
    pub fn release(&self, bytes: usize) {
        self.used.set(self.used.get().saturating_sub(bytes));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn refusal_sets_the_flag_for_good_and_release_makes_room() {
        let hit = Arc::new(AtomicBool::new(false));
        let b = ByteBudget::new(100, hit.clone());
        assert!(b.try_charge(60));
        assert!(!b.try_charge(60));
        assert!(hit.load(Ordering::SeqCst));
        b.release(60);
        assert!(b.try_charge(100));
        assert!(hit.load(Ordering::SeqCst), "the flag is not reset");
        assert!(!b.try_charge(usize::MAX));
    }

    #[test]
    fn marking_the_budget_hit_charges_nothing() {
        let hit = Arc::new(AtomicBool::new(false));
        let b = ByteBudget::new(100, hit.clone());
        b.mark_hit();
        assert!(hit.load(Ordering::SeqCst));
        assert!(b.try_charge(100), "nothing was charged by the mark");
    }
}
