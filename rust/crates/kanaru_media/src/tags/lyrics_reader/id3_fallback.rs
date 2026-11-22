//! Lyrics from a broken ID3v2 tag at the start of an MP3, read with
//! symphonia after lofty gave up on the file.
//!
//! lofty fails the whole tag at the first frame it rejects. symphonia's
//! ID3v2 reader keeps the frames read before a structural error and skips
//! the rest of the tag, so the lyrics stored before the damage survive.
//! Frames after the first fatal error are lost, and a content error inside
//! one frame (a bad text encoding byte) only skips that frame.
//!
//! Only runs after a failed concrete read of an MP3, so files that read
//! today never reach it. WAV and AIFF (ID3v2 in a chunk) are not covered.

use std::fs::File;
use std::io::{BufReader, Cursor, Read, Seek};

use lofty::id3::v2::FrameFlags;
use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::{MetadataOptions, MetadataReader, RawValue, Tag};
use symphonia::default::meta::Id3v2Reader;

use super::{usable_text, EmbeddedLyrics};
use crate::tags::errors::from_sniff_error;
use crate::tags::lyrics_sylt::best_synced;
use crate::MediaError;

/// Most bytes of the tag read into memory. A tag may declare up to 256 MiB;
/// real ones are a few hundred KiB (parity with lofty's allocation limit).
pub const MAX_ID3_FALLBACK_BYTES: usize = 16 * 1024 * 1024;

const HEADER_LEN: usize = 10;

/// What survives of the ID3v2 tag at the start of `reader`, as lyrics.
/// `Ok(None)` when nothing usable is left or the tag cannot be read for a
/// reason that is not transient; `Err` for a transient I/O error.
pub(super) fn recover(reader: &mut BufReader<File>) -> Result<Option<EmbeddedLyrics>, MediaError> {
    let Some(tag_bytes) = load_tag(reader)? else {
        return Ok(None);
    };
    let source = MediaSourceStream::new(Box::new(Cursor::new(tag_bytes)), Default::default());
    let mut id3 = Id3v2Reader::try_new(source, MetadataOptions::default())
        .map_err(|e| symphonia_failure(&e))?;
    let tags = match id3.read_all() {
        Ok(buffer) => buffer.revision.media.tags,
        Err(e) => return symphonia_failure_result(&e),
    };
    Ok(lyrics_of(&tags))
}

/// The 10-byte header and at most [`MAX_ID3_FALLBACK_BYTES`] of body, with
/// the declared size lowered to the bytes held. `Ok(None)`: no ID3v2 tag at
/// the start, or the file ended inside the header.
fn load_tag(reader: &mut BufReader<File>) -> Result<Option<Vec<u8>>, MediaError> {
    reader.rewind().map_err(|e| from_sniff_error(&e))?;
    let mut bytes = vec![0u8; HEADER_LEN];
    if let Err(e) = reader.read_exact(&mut bytes) {
        return non_transient(MediaError::from(e));
    }
    if &bytes[..3] != b"ID3" {
        return Ok(None);
    }
    let declared = declared_size(&bytes);
    let wanted = declared.min(MAX_ID3_FALLBACK_BYTES) as u64;
    if let Err(e) = reader.take(wanted).read_to_end(&mut bytes) {
        return non_transient(MediaError::from(e));
    }
    Ok(Some(with_held_size(bytes)))
}

/// The tag size in header bytes 6-9 (syncsafe: 7 bits per byte).
fn declared_size(header: &[u8]) -> usize {
    header[6..10]
        .iter()
        .fold(0usize, |size, byte| (size << 7) | usize::from(byte & 0x7f))
}

/// `tag` (header + the body bytes read) with the header's declared size
/// lowered to the body bytes held, so every size check inside symphonia is
/// against bytes that exist. Never raises the declared size.
fn with_held_size(mut tag: Vec<u8>) -> Vec<u8> {
    let held = tag.len() - HEADER_LEN;
    if held < declared_size(&tag) {
        for (i, byte) in tag[6..10].iter_mut().enumerate() {
            *byte = ((held >> (7 * (3 - i))) & 0x7f) as u8;
        }
    }
    tag
}

/// First usable `USLT` text, else a `TXXX` named `LYRICS` or
/// `UNSYNCEDLYRICS` (ignoring ASCII case, `LYRICS` first), plus the best
/// `SYLT` frame.
fn lyrics_of(tags: &[Tag]) -> Option<EmbeddedLyrics> {
    let uslt = tags
        .iter()
        .filter(|tag| tag.raw.key == "USLT")
        .find_map(|tag| usable(&tag.raw.value));
    let text = uslt.or_else(|| {
        ["LYRICS", "UNSYNCEDLYRICS"].into_iter().find_map(|wanted| {
            tags.iter()
                .filter(|tag| {
                    tag.raw.key == "TXXX"
                        && description(tag).is_some_and(|d| d.eq_ignore_ascii_case(wanted))
                })
                .find_map(|tag| usable(&tag.raw.value))
        })
    });
    let sylt = tags.iter().filter(|tag| tag.raw.key == "SYLT");
    let synced = best_synced(sylt.filter_map(|tag| match &tag.raw.value {
        RawValue::Binary(data) => Some((&data[..], FrameFlags::default())),
        _ => None,
    }));
    if text.is_none() && synced.is_empty() {
        return None;
    }
    Some(EmbeddedLyrics { text, synced })
}

/// The description of a `TXXX` tag.
fn description(tag: &Tag) -> Option<&str> {
    let fields = tag.raw.sub_fields.as_deref()?;
    let field = fields.iter().find(|f| f.field == "DESCRIPTION")?;
    match &field.value {
        RawValue::String(text) => Some(text.as_str()),
        _ => None,
    }
}

fn usable(value: &RawValue) -> Option<String> {
    match value {
        RawValue::String(text) => Some(text.as_str()),
        RawValue::StringList(list) => list.iter().map(String::as_str).find(|t| usable_text(t)),
        _ => None,
    }
    .filter(|text| usable_text(text))
    .map(str::to_owned)
}

/// A failure that says nothing about the file is retried; any other means
/// no lyrics.
fn non_transient<T>(error: MediaError) -> Result<Option<T>, MediaError> {
    if error.is_transient() {
        Err(error)
    } else {
        Ok(None)
    }
}

fn symphonia_failure(error: &SymphoniaError) -> MediaError {
    match error {
        SymphoniaError::IoError(e) => MediaError::Io(e.kind()),
        _ => MediaError::Unsupported,
    }
}

fn symphonia_failure_result(error: &SymphoniaError) -> Result<Option<EmbeddedLyrics>, MediaError> {
    non_transient(symphonia_failure(error))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn header(declared: usize) -> Vec<u8> {
        let mut bytes = b"ID3\x04\x00\x00".to_vec();
        for shift in [21, 14, 7, 0] {
            bytes.push(((declared >> shift) & 0x7f) as u8);
        }
        bytes
    }

    #[test]
    fn declared_size_round_trips() {
        assert_eq!(declared_size(&header(0)), 0);
        assert_eq!(declared_size(&header(257)), 257);
        assert_eq!(declared_size(&header(250 * 1024 * 1024)), 250 * 1024 * 1024);
    }

    #[test]
    fn a_declared_size_above_the_bytes_held_is_lowered() {
        let mut tag = header(250 * 1024 * 1024);
        tag.extend_from_slice(&[0u8; 5]);
        let patched = with_held_size(tag);
        assert_eq!(declared_size(&patched), 5);
        assert_eq!(&patched[..6], b"ID3\x04\x00\x00");
    }

    #[test]
    fn a_tag_read_at_the_cap_declares_at_most_the_cap() {
        let mut tag = header(250 * 1024 * 1024);
        tag.resize(HEADER_LEN + MAX_ID3_FALLBACK_BYTES, 0);
        assert!(declared_size(&with_held_size(tag)) <= MAX_ID3_FALLBACK_BYTES);
    }

    #[test]
    fn a_declared_size_within_the_bytes_held_is_kept() {
        let mut tag = header(3);
        tag.extend_from_slice(&[0u8; 8]);
        assert_eq!(declared_size(&with_held_size(tag)), 3);
    }
}
