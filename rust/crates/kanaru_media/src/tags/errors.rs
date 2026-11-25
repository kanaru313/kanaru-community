//! lofty errors to [`MediaError`]. A parser failure is `Corrupt` or
//! `Unsupported`, never an `Io` error of kind `Other` (such an error would
//! say nothing about whether the file may pass later).

use std::error::Error;
use std::io::ErrorKind;

use lofty::error::{
    FileParseError, NotEnoughDataError, SizeMismatchError, TagParseError, UnknownFormatError,
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
/// `error` or one of its causes is a tag failure, and no I/O error comes
/// before an ID3v2 frame error in the chain.
///
/// lofty wraps every tag failure of MP3, WAV, AIFF and FLAC in a
/// `TagParseError` (ID3v2 header, frame, text and size failures, and the
/// APE, ID3v1, RIFF INFO and AIFF text tags). The ID3v2-only causes it wraps
/// count on their own too. A `FrameParseError` counts even when an I/O error
/// caused it: lofty reads a frame's fixed fields (the `COMM` language, for
/// one) from a reader limited to the frame, so a frame too short for them
/// ends in an end-of-file inside a broken tag. An I/O error outside a frame
/// means the file ended or could not be read, not that the tag is broken:
/// lofty reads a FLAC file's ID3v2 prefix with one exact-size read and wraps
/// its end-of-file in a `TagParseError`, so a file cut inside a healthy
/// prefix is not counted.
/// Not counted either: size and allocation errors, a bare
/// `TextDecodingError` (lofty raises one for an AIFC compression name that
/// is not UTF-8, an audio property) and `FakeTagError`, which lofty also
/// raises for the audio (bare `FakeTagError`: `APET` junk at the start of an
/// MP3).
pub(crate) fn is_tag_failure(error: &(dyn Error + 'static)) -> bool {
    let mut tag = false;
    let mut source = Some(error);
    while let Some(current) = source {
        // Checked before the I/O rule: the I/O error below a frame error is
        // that frame's content ending early.
        if current.is::<FrameParseError>() {
            return true;
        }
        if current.is::<std::io::Error>() {
            return false;
        }
        if current.is::<TagParseError>()
            || current.is::<FrameIdParseError>()
            || current.is::<Id3v2HeaderError>()
            || current.is::<TimestampParseError>()
            || current.is::<BadTimestampFormatError>()
            || current.is::<BadSyncTextContentTypeError>()
        {
            tag = true;
        }
        source = current.source();
    }
    tag
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
    use lofty::error::TextDecodingError;

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

    /// lofty's error for an MP3 holding an ID3v2.4 tag of `frames` (id +
    /// body each) in front of `audio`.
    fn mp3_error(frames: &[(&[u8; 4], &[u8])], audio: &[u8]) -> FileParseError {
        let mut body = Vec::new();
        for &(id, content) in frames {
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
        let e = mp3_error(&[(b"TIT2", b"\x09x")], &mp3_frames());
        assert!(is_tag_failure(&e));
        assert!(is_tag_failure(cause::<TagParseError>(&e)));
        assert!(is_tag_failure(cause::<FrameParseError>(&e)));
    }

    #[test]
    fn text_that_does_not_decode_is_a_tag_failure() {
        // UTF-16 text one byte long.
        let e = mp3_error(&[(b"TIT2", b"\x01\xAB")], &mp3_frames());
        assert!(is_tag_failure(&e));
        assert!(is_tag_failure(cause::<TagParseError>(&e)));
        // The decoding error alone may come from audio properties.
        assert!(!is_tag_failure(cause::<TextDecodingError>(&e)));
    }

    #[test]
    fn a_frame_too_short_for_its_fixed_fields_is_a_tag_failure() {
        // A healthy title, then a COMM frame ending inside its language.
        let e = mp3_error(
            &[(b"TIT2", b"\x03Title"), (b"COMM", b"\x00e")],
            &mp3_frames(),
        );
        // The chain ends in the end-of-file inside the frame.
        let frame = cause::<FrameParseError>(&e);
        let io = frame
            .source()
            .and_then(|s| s.downcast_ref::<std::io::Error>())
            .expect("an I/O error under the frame error");
        assert_eq!(io.kind(), ErrorKind::UnexpectedEof);
        assert!(is_tag_failure(&e));
        assert!(is_tag_failure(cause::<TagParseError>(&e)));
        assert!(is_tag_failure(frame));
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
        let garbage = mp3_error(&[(b"TIT2", b"\x03Healthy")], &[0x41; 4000]);
        assert!(!is_tag_failure(&garbage));
        let io: FileParseError = std::io::Error::from(ErrorKind::UnexpectedEof).into();
        assert!(!is_tag_failure(&io));
        // A FLAC file ending inside its ID3v2 prefix: lofty wraps the
        // end-of-file in a tag error.
        let mut cut = b"ID3\x04\x00\x00".to_vec();
        cut.extend_from_slice(&syncsafe(100));
        cut.extend_from_slice(&[0; 20]);
        let cut = <lofty::flac::FlacFile as lofty::file::AudioFile>::read_from(
            &mut std::io::Cursor::new(cut),
            lofty::config::ParseOptions::new(),
        )
        .err()
        .expect("lofty refuses the file");
        cause::<TagParseError>(&cut);
        assert!(!is_tag_failure(&cut));
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
