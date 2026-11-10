//! lofty errors to [`MediaError`]. A parser failure is `Corrupt` or
//! `Unsupported`, never an `Io` error of kind `Other` (such an error would
//! say nothing about whether the file may pass later).

use std::error::Error;
use std::io::ErrorKind;

use lofty::error::{FileParseError, NotEnoughDataError, SizeMismatchError, UnknownFormatError};

use crate::MediaError;

/// Maps a failure of `Probe::read`. I/O errors found anywhere in the cause
/// chain keep their kind; an unknown format is `Unsupported`; a file that ends
/// early or disagrees with its own sizes, or any other parser error, is
/// `Corrupt`.
pub fn from_parse_error(error: &FileParseError) -> MediaError {
    if error.is_unknown_format() {
        return MediaError::Unsupported;
    }
    let mut source: Option<&(dyn Error + 'static)> = Some(error);
    while let Some(current) = source {
        if let Some(io) = current.downcast_ref::<std::io::Error>() {
            return from_io(io.kind(), error);
        }
        if current.is::<NotEnoughDataError>()
            || current.is::<SizeMismatchError>()
            || current.is::<UnknownFormatError>()
        {
            break;
        }
        source = current.source();
    }
    MediaError::Corrupt(describe(error))
}

/// Maps an I/O error from sniffing the content.
pub fn from_sniff_error(error: &std::io::Error) -> MediaError {
    match error.kind() {
        ErrorKind::Other | ErrorKind::InvalidData => MediaError::Corrupt(error.to_string()),
        kind => MediaError::Io(kind),
    }
}

fn from_io(kind: ErrorKind, error: &FileParseError) -> MediaError {
    match kind {
        ErrorKind::Other | ErrorKind::InvalidData => MediaError::Corrupt(describe(error)),
        kind => MediaError::Io(kind),
    }
}

/// The error and its causes on one line.
fn describe(error: &FileParseError) -> String {
    let mut text = error.to_string();
    let mut source = error.source();
    while let Some(s) = source {
        text.push_str(": ");
        text.push_str(&s.to_string());
        source = s.source();
    }
    text
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn io_error_keeps_its_kind() {
        let e: FileParseError = std::io::Error::from(ErrorKind::TimedOut).into();
        let mapped = from_parse_error(&e);
        assert_eq!(mapped, MediaError::Io(ErrorKind::TimedOut));
        assert!(mapped.is_transient());
        let nf: FileParseError = std::io::Error::from(ErrorKind::NotFound).into();
        assert_eq!(from_parse_error(&nf), MediaError::Io(ErrorKind::NotFound));
    }

    #[test]
    fn io_other_becomes_corrupt() {
        let e: FileParseError = std::io::Error::other("parser said so").into();
        assert!(matches!(from_parse_error(&e), MediaError::Corrupt(m) if m.contains("parser")));
    }

    #[test]
    fn unknown_format_is_unsupported() {
        let e: FileParseError = UnknownFormatError.into();
        assert_eq!(from_parse_error(&e), MediaError::Unsupported);
    }

    #[test]
    fn size_mismatch_is_permanent_corrupt() {
        let e: FileParseError = SizeMismatchError.into();
        let mapped = from_parse_error(&e);
        assert!(matches!(mapped, MediaError::Corrupt(_)));
        assert!(!mapped.is_transient());
    }

    #[test]
    fn sniff_errors_map_by_kind() {
        let e = std::io::Error::from(ErrorKind::Interrupted);
        assert!(from_sniff_error(&e).is_transient());
        let e = std::io::Error::other("x");
        assert!(matches!(from_sniff_error(&e), MediaError::Corrupt(_)));
    }
}
