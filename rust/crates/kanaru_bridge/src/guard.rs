//! Panic guard: a panic in one file's parser becomes an error for that file
//! instead of unwinding across the FFI boundary. Needs `panic = "unwind"`.

use std::cell::Cell;
use std::panic::{catch_unwind, AssertUnwindSafe, Location};
use std::sync::Once;

use crate::error::{NativeError, NativeErrorKind};

thread_local! {
    /// True while this thread runs inside [`guarded`]: its panics are caught
    /// and reported as an error, so [`install_hook`] logs one line for them.
    static GUARDED: Cell<bool> = const { Cell::new(false) };
}

/// Installs (once per process) a panic hook that, for threads inside
/// [`guarded`], writes [`panic_line`] and stops: the hooks below it (frb's
/// backtrace capture, std's full print) are skipped. Other panics go to the
/// previous hook. `init_app` installs it above frb's hook and below the plugin
/// runtime's quiet hook.
pub(crate) fn install_hook() {
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        let previous = std::panic::take_hook();
        std::panic::set_hook(Box::new(move |info| {
            if GUARDED.with(Cell::get) {
                let line = panic_line(&payload_text(info.payload()), info.location());
                log::warn!("{line}");
                // No logger off Android: logcat is the only sink there.
                #[cfg(not(target_os = "android"))]
                eprintln!("{line}");
            } else {
                previous(info);
            }
        }));
    });
}

/// The one line written for a guarded panic.
fn panic_line(payload: &str, location: Option<&Location<'_>>) -> String {
    match location {
        Some(l) => format!(
            "native panic caught: {payload} at {}:{}:{}",
            l.file(),
            l.line(),
            l.column()
        ),
        None => format!("native panic caught: {payload}"),
    }
}

fn payload_text(payload: &(dyn std::any::Any + Send)) -> String {
    payload
        .downcast_ref::<&str>()
        .map(|s| (*s).to_string())
        .or_else(|| payload.downcast_ref::<String>().cloned())
        .unwrap_or_else(|| "panic without message".to_string())
}

/// Runs `f`; a panic becomes `NativeErrorKind::Panic` carrying the payload
/// message. Captured state may be half-updated after a panic: discard it.
/// Not transient: the same file would panic again.
pub fn guarded<T>(f: impl FnOnce() -> Result<T, NativeError>) -> Result<T, NativeError> {
    let was = GUARDED.with(|g| g.replace(true));
    let caught = catch_unwind(AssertUnwindSafe(f));
    GUARDED.with(|g| g.set(was));
    match caught {
        Ok(result) => result,
        Err(payload) => Err(NativeError::new(
            NativeErrorKind::Panic,
            payload_text(payload.as_ref()),
            false,
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn line_names_payload_and_location() {
        let here = Location::caller();
        let line = panic_line("boom", Some(here));
        assert!(line.starts_with("native panic caught: boom at "));
        assert!(line.contains(&format!("guard.rs:{}:", here.line())));
    }

    #[test]
    fn line_without_location_has_no_at() {
        assert_eq!(panic_line("boom", None), "native panic caught: boom");
    }

    #[test]
    fn payload_text_handles_str_string_and_other() {
        assert_eq!(payload_text(&"a"), "a");
        assert_eq!(payload_text(&"b".to_string()), "b");
        assert_eq!(payload_text(&5_u8), "panic without message");
    }
}
