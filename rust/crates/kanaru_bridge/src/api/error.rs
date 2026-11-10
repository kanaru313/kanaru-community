//! Error DTO sent to Dart. Plain data, so every lane reports failures alike.
//! Pass-result rule: record a result only on success or a permanent kind;
//! when `transient` is true (including `Cancelled` and `Timeout`) leave the
//! pass version alone. `Panic` is permanent.

use kanaru_media::MediaError;
use std::io::ErrorKind;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NativeErrorKind {
    Io,
    NotFound,
    PermissionDenied,
    Unsupported,
    Corrupt,
    TooLarge,
    Cancelled,
    Timeout,
    Panic,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NativeError {
    pub kind: NativeErrorKind,
    pub detail: String,
    /// Retry later; do not record the file as processed.
    pub transient: bool,
}

#[flutter_rust_bridge::frb(ignore)]
impl NativeError {
    pub fn new(kind: NativeErrorKind, detail: impl Into<String>, transient: bool) -> Self {
        Self {
            kind,
            detail: detail.into(),
            transient,
        }
    }
}

#[flutter_rust_bridge::frb(ignore)]
impl From<MediaError> for NativeError {
    fn from(e: MediaError) -> Self {
        let transient = e.is_transient();
        let kind = match &e {
            MediaError::Io(ErrorKind::NotFound) => NativeErrorKind::NotFound,
            MediaError::Io(ErrorKind::PermissionDenied) => NativeErrorKind::PermissionDenied,
            MediaError::Io(_) => NativeErrorKind::Io,
            MediaError::Unsupported => NativeErrorKind::Unsupported,
            MediaError::Corrupt(_) => NativeErrorKind::Corrupt,
            MediaError::TooLarge => NativeErrorKind::TooLarge,
            MediaError::Cancelled => NativeErrorKind::Cancelled,
            MediaError::Timeout => NativeErrorKind::Timeout,
        };
        Self {
            kind,
            detail: e.to_string(),
            transient,
        }
    }
}

#[flutter_rust_bridge::frb(ignore)]
impl From<std::io::Error> for NativeError {
    fn from(e: std::io::Error) -> Self {
        MediaError::from(e).into()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn media_errors_map_to_kinds() {
        let nf: NativeError = MediaError::Io(ErrorKind::NotFound).into();
        assert_eq!(nf.kind, NativeErrorKind::NotFound);
        assert!(!nf.transient);
        let io: NativeError = MediaError::Io(ErrorKind::TimedOut).into();
        assert_eq!(io.kind, NativeErrorKind::Io);
        assert!(io.transient);
        let t: NativeError = MediaError::Timeout.into();
        assert_eq!((t.kind, t.transient), (NativeErrorKind::Timeout, true));
        let c: NativeError = MediaError::Cancelled.into();
        assert_eq!((c.kind, c.transient), (NativeErrorKind::Cancelled, true));
        let eof: NativeError = MediaError::Io(ErrorKind::UnexpectedEof).into();
        assert!(!eof.transient);
        let corrupt: NativeError = MediaError::Corrupt("bad".into()).into();
        assert_eq!(corrupt.kind, NativeErrorKind::Corrupt);
        assert!(corrupt.detail.contains("bad"));
    }
}
