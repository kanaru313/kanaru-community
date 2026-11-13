//! Hook chain after `init_app`: a guarded panic is caught by the bridge hook
//! and never reaches frb's backtrace capture; other panics still do. Own test
//! binary: the panic hook is process-wide.
#![allow(clippy::unwrap_used)]

use std::panic::catch_unwind;
use std::sync::atomic::{AtomicUsize, Ordering};

use flutter_rust_bridge::PanicBacktrace;
use kanaru_bridge::api::error::{NativeError, NativeErrorKind};
use kanaru_bridge::api::native_info::init_app;
use kanaru_bridge::guard::guarded;

const MARK: &str = "panic-quiet-test-marker";

/// Marker panics that reached the bottom of the hook chain.
static REACHED_BOTTOM: AtomicUsize = AtomicUsize::new(0);

fn reached() -> usize {
    REACHED_BOTTOM.load(Ordering::SeqCst)
}

#[test]
fn guarded_panics_stop_at_the_bridge_hook() {
    // Bottom of the chain: counts the marker, stays silent.
    // Other panics (a failed assertion) keep the default print.
    let default = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        // `panic!("{}", MARK)` carries a `String`.
        if info.payload().downcast_ref::<String>().map(String::as_str) == Some(MARK) {
            REACHED_BOTTOM.fetch_add(1, Ordering::SeqCst);
        } else {
            default(info);
        }
    }));
    // Twice: a hot restart must not stack a second frb hook.
    init_app();
    init_app();

    // (a) guarded panic: error, no capture, never reaches the bottom.
    let err = guarded(|| -> Result<(), NativeError> { panic!("{}", MARK) }).unwrap_err();
    assert_eq!(err.kind, NativeErrorKind::Panic);
    assert_eq!(err.detail, MARK);
    assert_eq!(reached(), 0);
    assert!(PanicBacktrace::take_last().is_none());

    // (b) a nested catch_unwind inside guarded is still marked.
    let ok = guarded(|| {
        assert!(catch_unwind(|| panic!("{}", MARK)).is_err());
        Ok(1)
    });
    assert_eq!(ok, Ok(1));
    assert_eq!(reached(), 0);
    assert!(PanicBacktrace::take_last().is_none());

    // (c) a bare panic goes through both lower hooks.
    assert!(catch_unwind(|| panic!("{}", MARK)).is_err());
    assert_eq!(reached(), 1);
    assert!(PanicBacktrace::take_last().is_some());

    // (d) the mark is gone after guarded returned.
    assert!(catch_unwind(|| panic!("{}", MARK)).is_err());
    assert_eq!(reached(), 2);
}
