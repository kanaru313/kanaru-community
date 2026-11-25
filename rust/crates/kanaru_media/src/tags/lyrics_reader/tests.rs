use std::io::ErrorKind;

use lofty::error::SizeMismatchError;

use super::*;

#[test]
fn a_transient_io_error_is_fatal() {
    let e: FileParseError = std::io::Error::from(ErrorKind::TimedOut).into();
    assert!(matches!(
        concrete_failure(&e, OnFailure::NoLyrics),
        Concrete::Fatal(MediaError::Io(ErrorKind::TimedOut))
    ));
}

#[test]
fn a_non_transient_io_error_means_no_lyrics() {
    let e: FileParseError = std::io::Error::from(ErrorKind::UnexpectedEof).into();
    assert!(matches!(
        concrete_failure(&e, OnFailure::NoLyrics),
        Concrete::Unreadable
    ));
}

#[test]
fn a_parse_failure_means_no_lyrics() {
    let e: FileParseError = SizeMismatchError.into();
    assert!(matches!(
        concrete_failure(&e, OnFailure::NoLyrics),
        Concrete::Unreadable
    ));
}

#[test]
fn a_parse_failure_is_an_error_when_the_format_asks_for_it() {
    let e: FileParseError = SizeMismatchError.into();
    assert!(matches!(
        concrete_failure(&e, OnFailure::Error),
        Concrete::Fatal(_)
    ));
}
