//! Per-format extraction of the lyrics only the concrete file type keeps
//! (ID3v2 frames, Vorbis comments).

use lofty::id3::v2::{Frame, Id3v2Tag};
use lofty::ogg::tag::VorbisComments;

use super::{usable_text, SyncedLine};
use crate::tags::lyrics_sylt::synced_lines;

/// What only the concrete file holds: the generic tag drops binary `SYLT`
/// frames, user text frames with lyrics descriptions and unmapped Vorbis keys.
#[derive(Default)]
pub(super) struct ConcreteLyrics {
    pub(super) synced: Vec<SyncedLine>,
    /// Plain text used only when the generic tags give none: ID3
    /// `TXXX:LYRICS` / `TXXX:UNSYNCEDLYRICS`, Vorbis `UNSYNCED LYRICS`.
    pub(super) fallback_text: Option<String>,
}

pub(super) fn of_id3v2(tag: Option<&Id3v2Tag>) -> ConcreteLyrics {
    let Some(tag) = tag else {
        return ConcreteLyrics::default();
    };
    // lofty's `get_user_text` matches the description exactly; taggers
    // write `Lyrics` and `unsyncedlyrics` too, so match ignoring ASCII case.
    let fallback_text = ["LYRICS", "UNSYNCEDLYRICS"]
        .into_iter()
        .find_map(|wanted| {
            tag.into_iter()
                .filter_map(|frame| match frame {
                    Frame::UserText(text) if text.description.eq_ignore_ascii_case(wanted) => {
                        Some(text.content.as_ref())
                    }
                    _ => None,
                })
                .find(|text| usable_text(text))
        })
        .map(str::to_owned);
    ConcreteLyrics {
        synced: synced_lines(tag),
        fallback_text,
    }
}

/// foobar2000 writes `UNSYNCED LYRICS` (with a space), which lofty does not
/// map; the key is matched ignoring ASCII case.
pub(super) fn of_vorbis(comments: Option<&VorbisComments>) -> ConcreteLyrics {
    let fallback_text = comments
        .and_then(|c| c.get_all("UNSYNCED LYRICS").find(|text| usable_text(text)))
        .map(str::to_owned);
    ConcreteLyrics {
        synced: Vec::new(),
        fallback_text,
    }
}
