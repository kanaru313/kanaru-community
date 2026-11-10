#![allow(clippy::unwrap_used)]
use kanaru_bridge::api::error::{NativeError, NativeErrorKind};
use kanaru_bridge::guard::guarded;

#[test]
fn ok_passes_through() {
    assert_eq!(guarded(|| Ok(7)), Ok(7));
}

#[test]
fn error_passes_through() {
    let e = NativeError::new(NativeErrorKind::Corrupt, "x", false);
    assert_eq!(guarded(|| Err::<(), _>(e.clone())), Err(e));
}

#[test]
fn str_panic_becomes_panic_error() {
    let err = guarded(|| -> Result<(), NativeError> { panic!("boom") }).unwrap_err();
    assert_eq!(err.kind, NativeErrorKind::Panic);
    assert_eq!(err.detail, "boom");
    assert!(!err.transient);
}

#[test]
fn formatted_panic_keeps_message() {
    let n = 3;
    let err = guarded(|| -> Result<(), NativeError> { panic!("bad {n}") }).unwrap_err();
    assert_eq!(err.detail, "bad 3");
}
