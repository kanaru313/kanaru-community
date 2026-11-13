#![allow(unsafe_code)]
//! Heap cap for one script, with a record of whether it was hit.
//!
//! QuickJS' own `set_memory_limit` fails an allocation but gives the script
//! no reliable trace: when the engine cannot even allocate the error object,
//! the script sees `throw null`, which looks like a script's own `throw null`.
//! This allocator enforces the cap itself and sets a flag the host reads, so
//! the `memory` status cannot be faked or missed.
//!
//! QuickJS calls these methods through `extern "C"` functions, where an
//! unwinding panic would abort the whole app. Every callback body therefore
//! runs under `catch_unwind`: a panic answers like an out-of-memory (null, or
//! nothing for a free) and sets the flag, so the run ends `memory`.

use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use rquickjs::allocator::{Allocator, RustAllocator};

/// Rust allocator that refuses to grow past `limit` bytes of live QuickJS
/// memory. A refused allocation returns null (QuickJS throws "out of
/// memory") and sets `hit`.
pub struct LimitedAllocator {
    limit: usize,
    used: usize,
    hit: Arc<AtomicBool>,
}

impl LimitedAllocator {
    /// The allocator and the flag it sets when the cap is hit.
    pub fn new(limit: usize) -> (Self, Arc<AtomicBool>) {
        let hit = Arc::new(AtomicBool::new(false));
        (
            Self {
                limit,
                used: 0,
                hit: hit.clone(),
            },
            hit,
        )
    }

    fn refuse(&self) -> *mut u8 {
        self.hit.store(true, Ordering::SeqCst);
        std::ptr::null_mut()
    }

    /// Runs `body`; a panic in it gives `fallback` and sets the flag.
    fn guarded<R>(&mut self, fallback: R, body: impl FnOnce(&mut Self) -> R) -> R {
        match catch_unwind(AssertUnwindSafe(|| body(self))) {
            Ok(value) => value,
            Err(_) => {
                self.hit.store(true, Ordering::SeqCst);
                fallback
            }
        }
    }
}

// SAFETY: every pointer comes from `RustAllocator` (same alignment and size
// header rules); this wrapper only counts sizes and may refuse a request,
// which the trait allows by returning null. No panic leaves a method.
unsafe impl Allocator for LimitedAllocator {
    fn alloc(&mut self, size: usize) -> *mut u8 {
        self.guarded(std::ptr::null_mut(), |a| {
            if a.used.saturating_add(size) > a.limit {
                return a.refuse();
            }
            let ptr = RustAllocator.alloc(size);
            if !ptr.is_null() {
                // SAFETY: `ptr` was just returned by `RustAllocator`.
                a.used += unsafe { RustAllocator::usable_size(ptr) };
            }
            ptr
        })
    }

    fn calloc(&mut self, count: usize, size: usize) -> *mut u8 {
        self.guarded(std::ptr::null_mut(), |a| {
            let total = count.saturating_mul(size);
            if a.used.saturating_add(total) > a.limit {
                return a.refuse();
            }
            let ptr = RustAllocator.calloc(count, size);
            if !ptr.is_null() {
                // SAFETY: `ptr` was just returned by `RustAllocator`.
                a.used += unsafe { RustAllocator::usable_size(ptr) };
            }
            ptr
        })
    }

    unsafe fn dealloc(&mut self, ptr: *mut u8) {
        // A panic leaks the block (and sets the flag) instead of unwinding
        // into C.
        self.guarded((), |a| {
            // SAFETY: the caller promises `ptr` came from this allocator,
            // which hands out `RustAllocator` blocks.
            a.used = a
                .used
                .saturating_sub(unsafe { RustAllocator::usable_size(ptr) });
            // SAFETY: same pointer, freed once by the caller's contract.
            unsafe { RustAllocator.dealloc(ptr) };
        })
    }

    unsafe fn realloc(&mut self, ptr: *mut u8, new_size: usize) -> *mut u8 {
        // The cap check comes before the underlying call, so a refusal never
        // touches `ptr`; QuickJS keeps the old block on null.
        self.guarded(std::ptr::null_mut(), |a| {
            // SAFETY: the caller promises `ptr` came from this allocator.
            let old = unsafe { RustAllocator::usable_size(ptr) };
            if a.used.saturating_sub(old).saturating_add(new_size) > a.limit {
                return a.refuse();
            }
            // SAFETY: same pointer; on success the old block is replaced. After
            // this call nothing below may panic: `guarded` would return null
            // for a block that was already moved, and QuickJS would then keep
            // using the freed old one.
            let new_ptr = unsafe { RustAllocator.realloc(ptr, new_size) };
            if !new_ptr.is_null() {
                // SAFETY: `new_ptr` was just returned by `RustAllocator`.
                let new_usable = unsafe { RustAllocator::usable_size(new_ptr) };
                a.used = a.used.saturating_sub(old).saturating_add(new_usable);
            }
            new_ptr
        })
    }

    unsafe fn usable_size(ptr: *mut u8) -> usize {
        // No instance here, so a panic cannot set the flag; 0 is only used
        // for statistics by the engine.
        // SAFETY: the caller promises `ptr` came from `RustAllocator`.
        catch_unwind(|| unsafe { RustAllocator::usable_size(ptr) }).unwrap_or(0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn refuses_past_the_limit_and_frees_back() {
        let (mut a, hit) = LimitedAllocator::new(1024);
        let p = a.alloc(600);
        assert!(!p.is_null());
        assert!(a.alloc(600).is_null(), "second block does not fit");
        assert!(hit.load(Ordering::SeqCst));
        hit.store(false, Ordering::SeqCst);
        // SAFETY: `p` came from this allocator and is freed once below.
        unsafe {
            assert!(
                a.realloc(p, 2000).is_null(),
                "growth past the limit is refused"
            );
            assert!(hit.load(Ordering::SeqCst));
            let p = a.realloc(p, 100);
            assert!(!p.is_null());
            a.dealloc(p);
        }
        assert_eq!(a.used, 0);
        let q = a.calloc(10, 10);
        assert!(!q.is_null());
        // SAFETY: `q` came from this allocator and is freed once.
        unsafe { a.dealloc(q) };
    }

    #[test]
    fn a_request_of_usize_max_is_refused_without_a_panic() {
        let (mut a, hit) = LimitedAllocator::new(1024);
        assert!(a.alloc(usize::MAX).is_null());
        assert!(hit.load(Ordering::SeqCst));
        assert_eq!(a.used, 0);
    }

    #[test]
    fn calloc_overflow_is_refused_without_a_panic() {
        let (mut a, hit) = LimitedAllocator::new(1024);
        assert!(a.calloc(usize::MAX, 2).is_null());
        assert!(a.calloc(usize::MAX / 2 + 1, 2).is_null());
        assert!(a.calloc(2, usize::MAX).is_null());
        assert!(hit.load(Ordering::SeqCst));
        assert_eq!(a.used, 0);
    }

    #[test]
    fn realloc_to_zero_and_back_does_not_panic() {
        let (mut a, hit) = LimitedAllocator::new(1024);
        let p = a.alloc(64);
        assert!(!p.is_null());
        // SAFETY: `p` came from this allocator; each call returns the live block.
        unsafe {
            let p = a.realloc(p, 0);
            assert!(!p.is_null(), "a zero-size block is still a block");
            let p = a.realloc(p, 128);
            assert!(!p.is_null());
            assert!(a.realloc(p, usize::MAX).is_null(), "huge growth is refused");
            a.dealloc(p);
        }
        assert!(hit.load(Ordering::SeqCst), "the refusal was recorded");
        assert_eq!(a.used, 0);
    }

    #[test]
    fn realloc_grow_past_the_cap_keeps_the_old_block_usable() {
        let (mut a, hit) = LimitedAllocator::new(256);
        let p = a.alloc(128);
        assert!(!p.is_null());
        // SAFETY: `p` is a live block of this allocator; a refused realloc
        // leaves it untouched, so writing and freeing it stays valid.
        unsafe {
            std::ptr::write_bytes(p, 7, 128);
            assert!(a.realloc(p, 1024).is_null());
            assert!(hit.load(Ordering::SeqCst));
            assert_eq!(*p, 7);
            a.dealloc(p);
        }
        assert_eq!(a.used, 0);
    }

    #[test]
    fn a_panic_in_a_callback_answers_like_out_of_memory() {
        let (mut a, hit) = LimitedAllocator::new(1024);
        let got = a.guarded(std::ptr::null_mut::<u8>(), |_| panic!("allocator bug"));
        assert!(got.is_null());
        assert!(hit.load(Ordering::SeqCst), "the memory flag is set");
        hit.store(false, Ordering::SeqCst);
        a.guarded((), |_| panic!("free bug"));
        assert!(hit.load(Ordering::SeqCst));
    }
}
