//! Lyrics from a broken ID3v2 tag at the start of an MP3, read with
//! symphonia after lofty gave up on the file (see `tags::id3_recovery`).
//! Frames after the first fatal error are lost, and a content error inside
//! one frame (a bad text encoding byte) only skips that frame.
//!
//! Only runs after a failed concrete read of an MP3 (any non-transient
//! failure, not only a damaged ID3v2 tag), so files that read today never
//! reach it. WAV and AIFF (ID3v2 in a chunk) are not covered.

use std::fs::File;
use std::io::BufReader;

use lofty::id3::v2::FrameFlags;
use symphonia::core::meta::{RawValue, Tag};

use super::{usable_text, EmbeddedLyrics};
use crate::tags::id3_recovery::{load_tag, non_transient, read_frames, MAX_ID3_FALLBACK_BYTES};
use crate::tags::lyrics_sylt::best_synced;
use crate::MediaError;

/// What survives of the ID3v2 tag at the start of `reader`, as lyrics.
/// `Ok(None)` when nothing usable is left or the tag cannot be read for a
/// reason that is not transient; `Err` for a transient I/O error.
pub(super) fn recover_mp3(
    reader: &mut BufReader<File>,
) -> Result<Option<EmbeddedLyrics>, MediaError> {
    let mut budget = MAX_ID3_FALLBACK_BYTES;
    let Some(tag_bytes) = load_tag(reader, 0, u64::MAX, &mut budget)? else {
        return Ok(None);
    };
    match read_frames(tag_bytes) {
        Ok(tags) => Ok(lyrics_of(&tags)),
        Err(e) => non_transient(e),
    }
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
