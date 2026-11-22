//! Lyrics from a broken ID3v2 tag at the start of an MP3, read with
//! symphonia after lofty gave up on the file.
//!
//! lofty fails the whole tag at the first frame it rejects. symphonia's
//! ID3v2 reader keeps the frames read before a structural error and skips
//! the rest of the tag, so the lyrics stored before the damage survive.
//! Frames after the first fatal error are lost, and a content error inside
//! one frame (a bad text encoding byte) only skips that frame.
//!
//! Only runs after a failed concrete read of an MP3 (any non-transient
//! failure, not only a damaged ID3v2 tag), so files that read today never
//! reach it. WAV and AIFF (ID3v2 in a chunk) are not covered.
//!
//! symphonia logs a warning for every frame it skips and keeps reading, so a
//! hostile tag of millions of empty frames would flood the log. The copy
//! handed to it is therefore cut first (see `id3_bound`): at the first
//! empty frame or padding, after `MAX_ID3_FALLBACK_FRAMES` frames, or where a
//! frame header does not fit.

use std::fs::File;
use std::io::{BufReader, Cursor, Read, Seek};

use lofty::id3::v2::FrameFlags;
use symphonia::core::errors::Error as SymphoniaError;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::{MetadataOptions, MetadataReader, RawValue, Tag};
use symphonia::default::meta::Id3v2Reader;

use super::id3_bound::{bound_tag, declared_size, HEADER_LEN};
use super::{usable_text, EmbeddedLyrics};
use crate::tags::lyrics_sylt::best_synced;
use crate::MediaError;

/// Most bytes of the tag read into memory. A tag may declare up to 256 MiB;
/// real ones are a few hundred KiB (parity with lofty's allocation limit).
pub const MAX_ID3_FALLBACK_BYTES: usize = 16 * 1024 * 1024;

/// What survives of the ID3v2 tag at the start of `reader`, as lyrics.
/// `Ok(None)` when nothing usable is left or the tag cannot be read for a
/// reason that is not transient; `Err` for a transient I/O error.
pub(super) fn recover(reader: &mut BufReader<File>) -> Result<Option<EmbeddedLyrics>, MediaError> {
    let Some(tag_bytes) = load_tag(reader)? else {
        return Ok(None);
    };
    let source = MediaSourceStream::new(Box::new(Cursor::new(tag_bytes)), Default::default());
    let mut id3 = match Id3v2Reader::try_new(source, MetadataOptions::default()) {
        Ok(reader) => reader,
        Err(e) => return non_transient(symphonia_failure(&e)),
    };
    match id3.read_all() {
        Ok(buffer) => Ok(lyrics_of(&buffer.revision.media.tags)),
        Err(e) => non_transient(symphonia_failure(&e)),
    }
}

/// The 10-byte header and at most [`MAX_ID3_FALLBACK_BYTES`] of body, with
/// the declared size lowered to the bytes held. `Ok(None)`: no ID3v2 tag at
/// the start, or the file ended inside the header.
fn load_tag(reader: &mut BufReader<File>) -> Result<Option<Vec<u8>>, MediaError> {
    if let Err(e) = reader.rewind() {
        return non_transient(MediaError::from(e));
    }
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
    Ok(Some(bound_tag(bytes)))
}

/// First usable `USLT` text, else a `TXXX` named `LYRICS` or
/// `UNSYNCEDLYRICS` (ignoring ASCII case, `LYRICS` first), plus the best
/// `SYLT` frame.
fn lyrics_of(tags: &[Tag]) -> Option<EmbeddedLyrics> {
    let uslt = tags
        .iter()
        .filter(|tag| matches!(tag.raw.key.as_str(), "USLT" | "ULT"))
        .find_map(|tag| usable(&tag.raw.value));
    let text = uslt.or_else(|| {
        ["LYRICS", "UNSYNCEDLYRICS"].into_iter().find_map(|wanted| {
            tags.iter()
                .filter(|tag| {
                    matches!(tag.raw.key.as_str(), "TXXX" | "TXX")
                        && description(tag).is_some_and(|d| d.eq_ignore_ascii_case(wanted))
                })
                .find_map(|tag| usable(&tag.raw.value))
        })
    });
    let sylt = tags
        .iter()
        .filter(|tag| matches!(tag.raw.key.as_str(), "SYLT" | "SLT"));
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
