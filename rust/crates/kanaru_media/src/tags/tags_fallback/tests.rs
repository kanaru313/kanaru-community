//! Outcomes of `recover` that the public API cannot reach: a cancel or a
//! transient error between the steps. The recovered fields themselves are
//! tested through `read_tags` in `tests/tags_read.rs`.

use std::io::{self, Cursor, Read, Seek, SeekFrom};

use lofty::config::ParseOptions;
use lofty::file::FileType;

use super::recover;
use crate::{Cancel, MediaError};

fn syncsafe(n: usize) -> [u8; 4] {
    [21, 14, 7, 0].map(|shift| ((n >> shift) & 0x7f) as u8)
}

/// An ID3v2.4 tag whose `TIT2` lofty refuses (bad encoding byte) after a
/// readable `TALB`, then twenty MPEG frames.
fn broken_mp3() -> Vec<u8> {
    let mut body = b"TALB".to_vec();
    body.extend_from_slice(&syncsafe(6));
    body.extend_from_slice(&[0, 0]);
    body.extend_from_slice(b"\x03Album");
    body.extend_from_slice(b"TIT2");
    body.extend_from_slice(&syncsafe(2));
    body.extend_from_slice(&[0, 0]);
    body.extend_from_slice(b"\x09x");
    let mut file = b"ID3\x04\x00\x00".to_vec();
    file.extend_from_slice(&syncsafe(body.len()));
    file.extend_from_slice(&body);
    let mut frame = vec![0u8; 417];
    frame[..4].copy_from_slice(&[0xFF, 0xFB, 0x90, 0x00]);
    file.extend(frame.repeat(20));
    file
}

fn options() -> ParseOptions {
    ParseOptions::new().read_cover_art(false)
}

#[test]
fn a_broken_mp3_is_recovered() {
    let tags = recover(
        &mut Cursor::new(broken_mp3()),
        FileType::Mpeg,
        options(),
        &Cancel::new(),
    )
    .unwrap()
    .expect("recovered");
    assert_eq!(tags.album.as_deref(), Some("Album"));
    assert_eq!(tags.sample_rate, Some(44_100));
    assert_eq!(tags.codec.as_deref(), Some("MP3"));
}

#[test]
fn a_cancel_stops_before_the_file_is_read_again() {
    let cancel = Cancel::new();
    cancel.cancel();
    let result = recover(
        &mut Cursor::new(broken_mp3()),
        FileType::Mpeg,
        options(),
        &cancel,
    );
    assert_eq!(result, Err(MediaError::Cancelled));
}

#[test]
fn types_without_an_id3v2_place_are_not_recovered() {
    for file_type in [FileType::Mp4, FileType::Vorbis, FileType::Opus] {
        let result = recover(
            &mut Cursor::new(broken_mp3()),
            file_type,
            options(),
            &Cancel::new(),
        );
        assert_eq!(result, Ok(None), "{file_type:?}");
    }
}

/// `inner` whose reads fail with `kind` once `fail_from` bytes were read.
struct FailsAfter {
    inner: Cursor<Vec<u8>>,
    fail_from: u64,
    kind: io::ErrorKind,
}

impl Read for FailsAfter {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        if self.inner.position() >= self.fail_from {
            return Err(io::Error::from(self.kind));
        }
        self.inner.read(buf)
    }
}

impl Seek for FailsAfter {
    fn seek(&mut self, to: SeekFrom) -> io::Result<u64> {
        self.inner.seek(to)
    }
}

#[test]
fn a_transient_error_while_reading_the_audio_again_is_an_error() {
    let bytes = broken_mp3();
    // The tag reads; the audio after it does not.
    let tag_len = bytes.len() as u64 - 20 * 417;
    let mut reader = FailsAfter {
        inner: Cursor::new(bytes),
        fail_from: tag_len,
        kind: io::ErrorKind::TimedOut,
    };
    let result = recover(&mut reader, FileType::Mpeg, options(), &Cancel::new());
    assert_eq!(result, Err(MediaError::Io(io::ErrorKind::TimedOut)));
}

#[test]
fn a_lasting_error_while_reading_the_audio_again_keeps_the_tag() {
    let bytes = broken_mp3();
    let tag_len = bytes.len() as u64 - 20 * 417;
    let mut reader = FailsAfter {
        inner: Cursor::new(bytes),
        fail_from: tag_len,
        kind: io::ErrorKind::InvalidData,
    };
    let tags = recover(&mut reader, FileType::Mpeg, options(), &Cancel::new())
        .unwrap()
        .expect("recovered");
    assert_eq!(tags.album.as_deref(), Some("Album"));
    assert_eq!(tags.sample_rate, None);
}
