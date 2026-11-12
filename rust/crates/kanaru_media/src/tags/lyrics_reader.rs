//! Reads the lyrics stored in one audio file with lofty. The caller opens the
//! file (the bridge rejects FIFOs and devices there); nothing here opens a
//! path.

use std::fs::File;
use std::io::{BufReader, Seek};

use lofty::config::{ParseOptions, ParsingMode};
use lofty::file::{AudioFile, FileType, TaggedFile, TaggedFileExt};
use lofty::id3::v2::Id3v2Tag;
use lofty::iff::aiff::AiffFile;
use lofty::iff::wav::WavFile;
use lofty::mpeg::MpegFile;
use lofty::probe::Probe;
use lofty::tag::ItemKey;

use super::errors::{from_parse_error, from_sniff_error};
use super::lyrics_sylt::synced_lines;
use crate::MediaError;

/// Largest lyrics text kept, in bytes. A song's lyrics are a few KiB; a
/// larger value is junk or an attack and is dropped.
pub const MAX_LYRICS_TEXT_BYTES: usize = 1024 * 1024;

/// The lyrics one file holds. At least one of the two parts is present.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EmbeddedLyrics {
    /// Plain or LRC text, as stored.
    pub text: Option<String>,
    /// Timed lines from an ID3v2 `SYLT` frame, sorted by time.
    pub synced: Vec<SyncedLine>,
}

/// One timed line of a `SYLT` frame.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyncedLine {
    pub time_ms: u32,
    pub text: String,
}

/// The lyrics of `file`, or `Ok(None)` when it holds none that are usable.
/// `ext_hint` (extension without the dot) only picks the format to try
/// first: the content decides. May panic inside lofty; the caller catches it.
///
/// Outcomes:
/// - no lyrics, blank or oversized lyrics, no tag at all: `Ok(None)`;
/// - an ID3v2-capable file (MP3, WAV, AIFF) that fails the concrete read for
///   a reason other than a transient I/O error: `Ok(None)` for the whole file,
///   as plain text next to a broken tag is dropped too;
/// - a transient I/O error anywhere, or a failure to sniff the content:
///   `Err` (mapped by `tags::errors`), so the caller may retry;
/// - any other format whose parse fails (unknown format, corrupt): `Err`.
pub fn read_lyrics(
    file: File,
    ext_hint: Option<&str>,
) -> Result<Option<EmbeddedLyrics>, MediaError> {
    let options = ParseOptions::new()
        .read_cover_art(false)
        .read_properties(false)
        .parsing_mode(ParsingMode::BestAttempt);
    // Content first, as the tag reader does; the extension is the fallback.
    let reader = BufReader::new(file);
    let hinted = ext_hint.and_then(|ext| FileType::from_ext(ext.to_ascii_lowercase()));
    let probe = match hinted {
        Some(file_type) => Probe::with_file_type(reader, file_type),
        None => Probe::new(reader),
    };
    let probe = probe
        .options(options)
        .guess_file_type()
        .map_err(|e| from_sniff_error(&e))?;

    // Formats whose ID3v2 tag may hold SYLT are read as their concrete type,
    // which keeps the binary frames the generic tag drops.
    let concrete_read = match probe.file_type() {
        Some(FileType::Mpeg) => concrete::<MpegFile>(probe, options, |f| f.id3v2()),
        Some(FileType::Wav) => concrete::<WavFile>(probe, options, |f| f.id3v2()),
        Some(FileType::Aiff) => concrete::<AiffFile>(probe, options, |f| f.id3v2()),
        _ => {
            let tagged = probe.read().map_err(|e| from_parse_error(&e))?;
            Ok((tagged, Id3v2Lyrics::default()))
        }
    };
    let (tagged, id3v2) = match concrete_read {
        Ok(read) => read,
        Err(Concrete::Fatal(error)) => return Err(error),
        Err(Concrete::Unreadable) => return Ok(None),
    };
    let text = lyrics_text(&tagged).or(id3v2.user_text);
    let synced = id3v2.synced;
    if text.is_none() && synced.is_empty() {
        return Ok(None);
    }
    Ok(Some(EmbeddedLyrics { text, synced }))
}

/// Why a concrete read gave nothing.
enum Concrete {
    /// The tag or file did not parse: the whole file has no lyrics.
    Unreadable,
    /// An error worth retrying, which says nothing about the file.
    Fatal(MediaError),
}

/// What only the concrete ID3v2 tag holds: the generic tag drops binary
/// `SYLT` frames and user text frames with lyrics descriptions.
#[derive(Default)]
struct Id3v2Lyrics {
    synced: Vec<SyncedLine>,
    /// `TXXX:LYRICS` or `TXXX:UNSYNCEDLYRICS`, as some taggers write.
    user_text: Option<String>,
}

impl Id3v2Lyrics {
    fn of(tag: &Id3v2Tag) -> Self {
        let user_text = ["LYRICS", "UNSYNCEDLYRICS"]
            .into_iter()
            .filter_map(|description| tag.get_user_text(description))
            .find(|text| usable_text(text))
            .map(str::to_owned);
        Self {
            synced: synced_lines(tag),
            user_text,
        }
    }
}

/// Reads the probed file as `F` and takes what its ID3v2 tag holds before
/// turning it into a generic [`TaggedFile`] (which consumes the file).
fn concrete<F>(
    probe: Probe<BufReader<File>>,
    options: ParseOptions,
    id3v2: impl Fn(&F) -> Option<&Id3v2Tag>,
) -> Result<(TaggedFile, Id3v2Lyrics), Concrete>
where
    F: AudioFile + Into<TaggedFile>,
{
    let mut reader = probe.into_inner();
    reader
        .rewind()
        .map_err(|e| Concrete::Fatal(MediaError::from(e)))?;
    let file = F::read_from(&mut reader, options).map_err(|e| {
        let mapped = from_parse_error(&e);
        if mapped.is_transient() {
            Concrete::Fatal(mapped)
        } else {
            Concrete::Unreadable
        }
    })?;
    let lyrics = id3v2(&file).map(Id3v2Lyrics::of).unwrap_or_default();
    Ok((file.into(), lyrics))
}

/// Text worth showing: not blank and within [`MAX_LYRICS_TEXT_BYTES`].
fn usable_text(text: &str) -> bool {
    text.len() <= MAX_LYRICS_TEXT_BYTES && !text.trim().is_empty()
}

/// The first usable lyrics text, looking at `Lyrics` then `UnsyncLyrics`
/// in the primary tag first, then in the other tags. Keys lofty does not
/// map (foobar2000's Vorbis `UNSYNCED LYRICS`) never reach the generic tag.
fn lyrics_text(tagged: &TaggedFile) -> Option<String> {
    let primary = tagged.primary_tag();
    let others = tagged
        .tags()
        .iter()
        .filter(|tag| Some(tag.tag_type()) != primary.map(|p| p.tag_type()));
    let tags = primary.into_iter().chain(others);
    for tag in tags {
        for key in [ItemKey::Lyrics, ItemKey::UnsyncLyrics] {
            if let Some(text) = tag.get_strings(key).find(|text| usable_text(text)) {
                return Some(text.to_owned());
            }
        }
    }
    None
}
