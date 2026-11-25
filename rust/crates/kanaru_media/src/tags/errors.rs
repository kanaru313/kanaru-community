//! lofty errors to [`MediaError`]. A parser failure is `Corrupt` or
//! `Unsupported`, never an `Io` error of kind `Other` (such an error would
//! say nothing about whether the file may pass later).

use std::error::Error;
use std::io::ErrorKind;

use lofty::error::{
    FileParseError, NotEnoughDataError, SizeMismatchError, TagParseError, TextDecodingError,
    UnknownFormatError,
};
use lofty::id3::v2::error::{
    BadSyncTextContentTypeError, BadTimestampFormatError, FrameIdParseError, FrameParseError,
    Id3v2HeaderError,
};
use lofty::tag::items::timestamp::TimestampParseError;

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

/// Whether lofty refused the file because of a tag rather than its audio:
/// `error` or one of its causes is a tag failure.
///
/// lofty wraps every tag failure of MP3, WAV, AIFF and FLAC in a
/// `TagParseError` (ID3v2 header, frame, text and size failures, and the
/// APE, ID3v1, RIFF INFO and AIFF text tags). The ID3v2 causes it wraps count
/// on their own too, should a later lofty pass one up unwrapped. Not counted:
/// I/O, size and allocation errors and `FakeTagError`, which lofty also
/// raises for the audio (bare `FakeTagError`: `APET` junk at the start of an
/// MP3).
pub(crate) fn is_tag_failure(error: &(dyn Error + 'static)) -> bool {
    let mut source = Some(error);
    while let Some(current) = source {
        if current.is::<TagParseError>()
            || current.is::<FrameParseError>()
            || current.is::<FrameIdParseError>()
            || current.is::<Id3v2HeaderError>()
            || current.is::<TextDecodingError>()
            || current.is::<TimestampParseError>()
            || current.is::<BadTimestampFormatError>()
            || current.is::<BadSyncTextContentTypeError>()
        {
            return true;
        }
        source = current.source();
    }
    false
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

    /// An error caused by `cause`, as lofty's wrappers are.
    #[derive(Debug)]
    struct CausedBy(Box<dyn Error + Send + Sync>);

    impl std::fmt::Display for CausedBy {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            f.write_str("failed")
        }
    }

    impl Error for CausedBy {
        fn source(&self) -> Option<&(dyn Error + 'static)> {
            Some(self.0.as_ref())
        }
    }

    fn caused_by(cause: impl Error + Send + Sync + 'static) -> bool {
        is_tag_failure(&CausedBy(Box::new(cause)))
    }

    fn syncsafe(n: usize) -> [u8; 4] {
        [21, 14, 7, 0].map(|shift| ((n >> shift) & 0x7f) as u8)
    }

    /// lofty's error for an MP3 holding an ID3v2.4 tag of one `frame` (id +
    /// body) in front of `audio`.
    fn mp3_error(frame: Option<(&[u8; 4], &[u8])>, audio: &[u8]) -> FileParseError {
        let mut body = Vec::new();
        if let Some((id, content)) = frame {
            body.extend_from_slice(id);
            body.extend_from_slice(&syncsafe(content.len()));
            body.extend_from_slice(&[0, 0]);
            body.extend_from_slice(content);
        }
        let mut bytes = b"ID3\x04\x00\x00".to_vec();
        bytes.extend_from_slice(&syncsafe(body.len()));
        bytes.extend_from_slice(&body);
        bytes.extend_from_slice(audio);
        let options = lofty::config::ParseOptions::new();
        let read = <lofty::mpeg::MpegFile as lofty::file::AudioFile>::read_from(
            &mut std::io::Cursor::new(bytes),
            options,
        );
        read.err().expect("lofty refuses the file")
    }

    fn mp3_frames() -> Vec<u8> {
        let mut frame = vec![0u8; 417];
        frame[..4].copy_from_slice(&[0xFF, 0xFB, 0x90, 0x00]);
        frame.repeat(4)
    }

    /// The cause of type `T` in the chain of `error`, as a chain of its own.
    fn cause<T: Error + 'static>(error: &FileParseError) -> &(dyn Error + 'static) {
        let mut source: Option<&(dyn Error + 'static)> = Some(error);
        while let Some(current) = source {
            if current.is::<T>() {
                return current;
            }
            source = current.source();
        }
        panic!("no {} in {error:?}", std::any::type_name::<T>());
    }

    #[test]
    fn a_broken_id3v2_frame_is_a_tag_failure_at_every_level() {
        // An unknown text encoding byte.
        let e = mp3_error(Some((b"TIT2", b"\x09x")), &mp3_frames());
        assert!(is_tag_failure(&e));
        assert!(is_tag_failure(cause::<TagParseError>(&e)));
        assert!(is_tag_failure(cause::<FrameParseError>(&e)));
    }

    #[test]
    fn text_that_does_not_decode_is_a_tag_failure() {
        // UTF-16 text one byte long.
        let e = mp3_error(Some((b"TIT2", b"\x01\xAB")), &mp3_frames());
        assert!(is_tag_failure(&e));
        assert!(is_tag_failure(cause::<TextDecodingError>(&e)));
    }

    #[test]
    fn id3v2_causes_are_tag_failures_on_their_own() {
        assert!(caused_by(Id3v2HeaderError::V2Compression));
        assert!(caused_by(Id3v2HeaderError::BadExtendedHeaderSize));
        assert!(caused_by(Id3v2HeaderError::BadId3v2Version(9, 0)));
        assert!(caused_by(
            lofty::id3::v2::FrameId::new("bad id").expect_err("invalid id")
        ));
        assert!(caused_by(TimestampParseError::Empty));
        assert!(caused_by(BadTimestampFormatError));
        assert!(caused_by(BadSyncTextContentTypeError));
    }

    #[test]
    fn audio_failures_are_not_tag_failures() {
        // A healthy tag in front of bytes holding no MPEG frame.
        let garbage = mp3_error(Some((b"TIT2", b"\x03Healthy")), &[0x41; 4000]);
        assert!(!is_tag_failure(&garbage));
        let io: FileParseError = std::io::Error::from(ErrorKind::UnexpectedEof).into();
        assert!(!is_tag_failure(&io));
        let size: FileParseError = SizeMismatchError.into();
        assert!(!is_tag_failure(&size));
        assert!(!caused_by(lofty::error::FakeTagError));
    }

    #[test]
    fn sniff_errors_map_by_kind() {
        let e = std::io::Error::from(ErrorKind::Interrupted);
        assert!(from_sniff_error(&e).is_transient());
        let e = std::io::Error::other("x");
        assert!(matches!(from_sniff_error(&e), MediaError::Corrupt(_)));
    }
}
