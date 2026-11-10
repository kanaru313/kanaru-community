//! Panic guard: a panic in one file's parser becomes an error for that file
//! instead of unwinding across the FFI boundary. Needs `panic = "unwind"`.

use std::panic::{catch_unwind, AssertUnwindSafe};

use crate::error::{NativeError, NativeErrorKind};

/// Runs `f`; a panic becomes `NativeErrorKind::Panic` carrying the payload
/// message. Captured state may be half-updated after a panic: discard it.
/// Not transient: the same file would panic again.
pub fn guarded<T>(f: impl FnOnce() -> Result<T, NativeError>) -> Result<T, NativeError> {
    match catch_unwind(AssertUnwindSafe(f)) {
        Ok(result) => result,
        Err(payload) => {
            let detail = payload
                .downcast_ref::<&str>()
                .map(|s| (*s).to_string())
                .or_else(|| payload.downcast_ref::<String>().cloned())
                .unwrap_or_else(|| "panic without message".to_string());
            Err(NativeError::new(NativeErrorKind::Panic, detail, false))
        }
    }
}
