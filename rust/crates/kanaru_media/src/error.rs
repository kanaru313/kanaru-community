//! One error type for every media operation.

use std::io::ErrorKind;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MediaError {
    Io(ErrorKind),
    /// Format or codec this build does not read.
    Unsupported,
    /// The file is damaged or not what its extension says.
    Corrupt(String),
    /// Over one of the limits in `limits`.
    TooLarge,
    Cancelled,
    Timeout,
}

impl MediaError {
    /// A transient error says nothing about the file, so a scan must retry it
    /// later: record a pass result only on success or on a permanent error;
    /// for a transient one (including `Cancelled` and `Timeout`) leave the
    /// pass version alone, or the file stays hidden for good.
    ///
    /// Io kinds are an allowlist of the ones worth retrying (busy or dropped
    /// network mounts, interrupted calls). Everything else, such as a missing
    /// file, a refused read, a truncated or invalid file, is permanent until
    /// the file changes. `Other` is permanent too: libraries wrap parser and
    /// decoder failures as `Other`, and those must not be retried forever.
    /// Lanes map such failures to `Corrupt` or `Unsupported`, never through
    /// an io `Other`.
    pub fn is_transient(&self) -> bool {
        match self {
            MediaError::Io(kind) => matches!(
                kind,
                ErrorKind::TimedOut
                    | ErrorKind::Interrupted
                    | ErrorKind::WouldBlock
                    | ErrorKind::ResourceBusy
                    | ErrorKind::StaleNetworkFileHandle
                    | ErrorKind::ConnectionRefused
                    | ErrorKind::ConnectionReset
                    | ErrorKind::ConnectionAborted
                    | ErrorKind::NotConnected
                    | ErrorKind::NetworkDown
                    | ErrorKind::NetworkUnreachable
                    | ErrorKind::HostUnreachable
                    | ErrorKind::BrokenPipe
            ),
            MediaError::Timeout | MediaError::Cancelled => true,
            _ => false,
        }
    }
}

impl From<std::io::Error> for MediaError {
    fn from(e: std::io::Error) -> Self {
        MediaError::Io(e.kind())
    }
}

impl std::fmt::Display for MediaError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MediaError::Io(k) => write!(f, "io error: {k}"),
            MediaError::Unsupported => f.write_str("unsupported format"),
            MediaError::Corrupt(m) => write!(f, "corrupt file: {m}"),
            MediaError::TooLarge => f.write_str("file too large"),
            MediaError::Cancelled => f.write_str("cancelled"),
            MediaError::Timeout => f.write_str("timed out"),
        }
    }
}

impl std::error::Error for MediaError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn transient_classification() {
        assert!(MediaError::Io(ErrorKind::TimedOut).is_transient());
        assert!(MediaError::Io(ErrorKind::Interrupted).is_transient());
        assert!(MediaError::Timeout.is_transient());
        assert!(!MediaError::Io(ErrorKind::NotFound).is_transient());
        assert!(!MediaError::Io(ErrorKind::PermissionDenied).is_transient());
        assert!(!MediaError::Unsupported.is_transient());
        assert!(!MediaError::Corrupt("x".into()).is_transient());
        assert!(!MediaError::TooLarge.is_transient());
        assert!(MediaError::Cancelled.is_transient());
        assert!(!MediaError::Io(ErrorKind::Other).is_transient());
        assert!(!MediaError::Io(ErrorKind::UnexpectedEof).is_transient());
        assert!(!MediaError::Io(ErrorKind::InvalidData).is_transient());
        assert!(!MediaError::Io(ErrorKind::IsADirectory).is_transient());
    }

    #[test]
    fn io_error_converts_with_kind() {
        let e: MediaError = std::io::Error::from(ErrorKind::NotFound).into();
        assert_eq!(e, MediaError::Io(ErrorKind::NotFound));
    }
}
