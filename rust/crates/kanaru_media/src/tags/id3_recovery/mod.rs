//! What survives of a broken ID3v2 tag, read with symphonia after lofty gave
//! up on the file. Shared by the lyrics reader and the tag reader.
//!
//! lofty fails the whole tag at the first frame it rejects. symphonia's
//! ID3v2 reader keeps the frames read before a structural error and skips
//! the rest of the tag; a content error inside one frame (a bad text
//! encoding byte) only skips that frame.
//!
//! [`read_frames`] is the only code that hands bytes to symphonia, and it
//! always cuts them with [`bound::bound_tag`] first: symphonia logs a warning
//! for every frame it skips and keeps reading, so a hostile tag of millions
//! of empty frames would otherwise flood the log, and a declared size past
//! the bytes held would make the whole read fail.

use std::io::{Cursor, Read, Seek, SeekFrom};

use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::{MetadataOptions, MetadataReader, Tag};
use symphonia::default::meta::Id3v2Reader;

use crate::MediaError;

mod bound;
pub(crate) mod iff;
pub(crate) mod prefix;
pub(crate) mod views;

pub use bound::MAX_ID3_FALLBACK_FRAMES;
use bound::{bound_tag, declared_size, HEADER_LEN};

/// Most bytes of ID3v2 tags read into memory for one file, headers
/// included. A tag may declare up to 256 MiB; real ones are a few hundred
/// KiB (parity with lofty's allocation limit).
pub const MAX_ID3_FALLBACK_BYTES: usize = 16 * 1024 * 1024;

/// Most ID3 chunks of one WAV or AIFF file looked at (and masked when the
/// file is read again).
pub(crate) const MAX_ID3_CHUNKS: usize = 4;

/// Most top-level chunk headers of one WAV or AIFF file walked while looking
/// for ID3 chunks. Real files have a handful.
#[cfg_attr(
    not(test),
    expect(dead_code, reason = "used once the container recovery lands")
)]
const MAX_IFF_CHUNKS: usize = 1024;

/// Most ID3v2 tags looked at in a row at the start of an MP3 or FLAC file.
#[cfg_attr(
    not(test),
    expect(dead_code, reason = "used once the container recovery lands")
)]
const MAX_ID3_PREFIXES: usize = 4;

/// The ID3v2 tag whose header starts at `at`: the 10-byte header and as much
/// of the body as the tag declares, `limit` allows and `budget` has left,
/// never reading past `at + limit` (a tag inside a chunk cannot spill into
/// the next chunk). `budget` goes down by the bytes read.
///
/// `Ok(None)`: no room for a header (`limit` or `budget` below 10 bytes), no
/// `ID3` at `at`, the stream ended inside the header, or a read failed for a
/// reason that is not transient. `Err`: a transient I/O error.
pub(crate) fn load_tag<R: Read + Seek>(
    reader: &mut R,
    at: u64,
    limit: u64,
    budget: &mut usize,
) -> Result<Option<Vec<u8>>, MediaError> {
    if limit < HEADER_LEN as u64 || *budget < HEADER_LEN {
        return Ok(None);
    }
    if let Err(e) = reader.seek(SeekFrom::Start(at)) {
        return non_transient(MediaError::from(e));
    }
    let mut bytes = vec![0u8; HEADER_LEN];
    if let Err(e) = reader.read_exact(&mut bytes) {
        return non_transient(MediaError::from(e));
    }
    *budget -= HEADER_LEN;
    if &bytes[..3] != b"ID3" {
        return Ok(None);
    }
    let wanted = (declared_size(&bytes) as u64)
        .min(limit - HEADER_LEN as u64)
        .min(*budget as u64);
    let read = reader.by_ref().take(wanted).read_to_end(&mut bytes);
    // Whatever was read counts, also when the read failed half-way.
    *budget -= bytes.len() - HEADER_LEN;
    if let Err(e) = read {
        return non_transient(MediaError::from(e));
    }
    Ok(Some(bytes))
}

/// The frames symphonia reads from `tag_bytes` (an ID3v2 header and the body
/// bytes held, as [`load_tag`] gives them), after cutting the copy down to
/// the part worth parsing. The only way bytes reach symphonia's ID3v2
/// reader.
///
/// `Err` is the reason symphonia gave up: an I/O kind or `Unsupported`.
/// Bytes that are not an ID3v2 header are `Unsupported` too.
pub(crate) fn read_frames(tag_bytes: Vec<u8>) -> Result<Vec<Tag>, MediaError> {
    if tag_bytes.len() < HEADER_LEN || &tag_bytes[..3] != b"ID3" {
        return Err(MediaError::Unsupported);
    }
    let bounded = bound_tag(tag_bytes);
    let source = MediaSourceStream::new(Box::new(Cursor::new(bounded)), Default::default());
    let mut id3 = Id3v2Reader::try_new(source, MetadataOptions::default())
        .map_err(|e| symphonia_failure(&e))?;
    let buffer = id3.read_all().map_err(|e| symphonia_failure(&e))?;
    Ok(buffer.revision.media.tags)
}

/// A failure that says nothing about the file is retried; any other means
/// nothing was recovered.
pub(crate) fn non_transient<T>(error: MediaError) -> Result<Option<T>, MediaError> {
    if error.is_transient() {
        Err(error)
    } else {
        Ok(None)
    }
}

/// The spans a locator `found` before `walked` ended: a transient I/O error
/// is retried by the caller; any other failure (the file ends inside a
/// header) only ends the walk.
#[cfg_attr(
    not(test),
    expect(dead_code, reason = "used once the container recovery lands")
)]
fn keep_found<T>(walked: std::io::Result<()>, found: Vec<T>) -> Result<Vec<T>, MediaError> {
    match walked.map_err(MediaError::from) {
        Err(e) if e.is_transient() => Err(e),
        _ => Ok(found),
    }
}

fn symphonia_failure(error: &SymphoniaError) -> MediaError {
    match error {
        SymphoniaError::IoError(e) => MediaError::Io(e.kind()),
        _ => MediaError::Unsupported,
    }
}

#[cfg(test)]
mod tests {
    use std::io::{self, Cursor};

    use super::*;

    /// An ID3v2.4 tag declaring `declared` bytes, with `body` after it.
    fn tag(declared: usize, body: &[u8]) -> Vec<u8> {
        let mut bytes = b"ID3\x04\x00\x00".to_vec();
        bytes.extend([21, 14, 7, 0].map(|shift| ((declared >> shift) & 0x7f) as u8));
        bytes.extend_from_slice(body);
        bytes
    }

    #[test]
    fn a_tag_is_read_at_its_offset_up_to_its_declared_size() {
        let mut file = b"junk".to_vec();
        file.extend(tag(3, b"abcdef"));
        let mut budget = 100;
        let bytes = load_tag(&mut Cursor::new(file), 4, u64::MAX, &mut budget)
            .unwrap()
            .unwrap();
        assert_eq!(bytes, tag(3, b"abc"));
        assert_eq!(budget, 100 - 13);
    }

    #[test]
    fn a_tag_is_not_read_past_its_limit() {
        let mut budget = 100;
        let bytes = load_tag(&mut Cursor::new(tag(6, b"abcdef")), 0, 12, &mut budget)
            .unwrap()
            .unwrap();
        assert_eq!(bytes, tag(6, b"ab"));
        assert_eq!(budget, 100 - 12);
    }

    #[test]
    fn a_tag_is_not_read_past_the_budget() {
        let mut budget = 14;
        let bytes = load_tag(
            &mut Cursor::new(tag(6, b"abcdef")),
            0,
            u64::MAX,
            &mut budget,
        )
        .unwrap()
        .unwrap();
        assert_eq!(bytes, tag(6, b"abcd"));
        assert_eq!(budget, 0);
    }

    #[test]
    fn a_tag_cut_short_by_the_file_counts_only_the_bytes_read() {
        let mut budget = 100;
        let bytes = load_tag(&mut Cursor::new(tag(50, b"ab")), 0, u64::MAX, &mut budget)
            .unwrap()
            .unwrap();
        assert_eq!(bytes, tag(50, b"ab"));
        assert_eq!(budget, 100 - 12);
    }

    #[test]
    fn no_room_for_a_header_reads_nothing() {
        let file = tag(2, b"ab");
        let mut budget = 100;
        assert_eq!(
            load_tag(&mut Cursor::new(file.clone()), 0, 9, &mut budget),
            Ok(None)
        );
        assert_eq!(budget, 100);
        let mut budget = 9;
        assert_eq!(
            load_tag(&mut Cursor::new(file), 0, u64::MAX, &mut budget),
            Ok(None)
        );
        assert_eq!(budget, 9);
    }

    #[test]
    fn no_tag_or_a_cut_header_is_none() {
        let mut budget = 100;
        let not_a_tag = b"RIFF\x04\x00\x00\x00\x00\x00abcd".to_vec();
        assert_eq!(
            load_tag(&mut Cursor::new(not_a_tag), 0, u64::MAX, &mut budget),
            Ok(None)
        );
        let cut = tag(2, b"")[..7].to_vec();
        assert_eq!(
            load_tag(&mut Cursor::new(cut), 0, u64::MAX, &mut budget),
            Ok(None)
        );
        let mut budget = 100;
        assert_eq!(
            load_tag(&mut Cursor::new(tag(0, b"")), 99, u64::MAX, &mut budget),
            Ok(None)
        );
    }

    /// A reader whose reads fail with `kind`.
    struct Failing(io::ErrorKind);

    impl Read for Failing {
        fn read(&mut self, _: &mut [u8]) -> io::Result<usize> {
            Err(io::Error::from(self.0))
        }
    }

    impl Seek for Failing {
        fn seek(&mut self, _: SeekFrom) -> io::Result<u64> {
            Ok(0)
        }
    }

    #[test]
    fn a_transient_read_error_is_an_error_and_any_other_is_none() {
        let mut budget = 100;
        let transient = load_tag(
            &mut Failing(io::ErrorKind::TimedOut),
            0,
            u64::MAX,
            &mut budget,
        );
        assert_eq!(transient, Err(MediaError::Io(io::ErrorKind::TimedOut)));
        let lasting = load_tag(
            &mut Failing(io::ErrorKind::InvalidData),
            0,
            u64::MAX,
            &mut budget,
        );
        assert_eq!(lasting, Ok(None));
    }

    #[test]
    fn frames_are_read_from_a_tag() {
        let mut frame = b"TIT2".to_vec();
        frame.extend_from_slice(&[0, 0, 0, 4, 0, 0]);
        frame.extend_from_slice(b"\x03abc");
        let tags = read_frames(tag(frame.len(), &frame)).unwrap();
        assert_eq!(tags.len(), 1);
        assert_eq!(tags[0].raw.key, "TIT2");
    }

    #[test]
    fn bytes_that_are_not_a_tag_are_refused() {
        assert_eq!(read_frames(Vec::new()).err(), Some(MediaError::Unsupported));
        assert_eq!(
            read_frames(b"ID3\x04".to_vec()).err(),
            Some(MediaError::Unsupported)
        );
        assert_eq!(
            read_frames(b"RIFF\x04\x00\x00\x00\x00\x00".to_vec()).err(),
            Some(MediaError::Unsupported)
        );
    }
}
