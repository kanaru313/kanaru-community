//! Reads the lyrics stored in one audio file with lofty. The caller opens the
//! file (the bridge rejects FIFOs and devices there); nothing here opens a
//! path.

use std::fs::File;
use std::io::{BufReader, Seek};

use lofty::config::{ParseOptions, ParsingMode};
use lofty::error::FileParseError;
use lofty::file::{AudioFile, FileType, TaggedFile, TaggedFileExt};
use lofty::flac::FlacFile;
use lofty::id3::v2::{Frame, Id3v2Tag};
use lofty::iff::aiff::AiffFile;
use lofty::iff::wav::WavFile;
use lofty::mpeg::MpegFile;
use lofty::ogg::tag::VorbisComments;
use lofty::ogg::{OpusFile, VorbisFile};
use lofty::probe::Probe;
use lofty::tag::ItemKey;

use super::errors::{from_parse_error, from_sniff_error};
use super::lyrics_sylt::synced_lines;
use crate::MediaError;

mod id3_bound;
mod id3_fallback;
pub use id3_fallback::MAX_ID3_FALLBACK_BYTES;

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
/// - an MP3 that fails the concrete read for a reason other than a transient
///   I/O error: the lyrics kept before the first structural error of its
///   ID3v2 tag (`id3_fallback`), else `Ok(None)`; plain text next to a broken
///   tag is dropped. This includes an empty or truncated file;
/// - a WAV or AIFF in the same case: `Ok(None)` for the whole file;
/// - a transient I/O error anywhere, a failure to sniff the content, or a
///   failed rewind before the concrete read: `Err` (mapped by `tags::errors`),
///   so the caller may retry when it is transient;
/// - FLAC, Ogg Vorbis, Opus and every other format whose parse fails
///   (unknown format, corrupt, empty or truncated, where lofty reports
///   `UnexpectedEof`): `Err`.
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
    let hinted = ext_hint.and_then(FileType::from_ext);
    let probe = match hinted {
        Some(file_type) => Probe::with_file_type(reader, file_type),
        None => Probe::new(reader),
    };
    let probe = probe
        .options(options)
        .guess_file_type()
        .map_err(|e| from_sniff_error(&e))?;

    // Formats with data the generic tag drops are read as their concrete
    // type: binary `SYLT` and `TXXX` frames of ID3v2 (MP3, WAV, AIFF), the
    // unmapped `UNSYNCED LYRICS` key of Vorbis comments (FLAC, Ogg, Opus).
    // A broken ID3 tag means no lyrics; a failed Vorbis parse is an error.
    let id3 = OnFailure::NoLyrics;
    let vorbis = OnFailure::Error;
    let concrete_read = match probe.file_type() {
        Some(FileType::Mpeg) => concrete::<MpegFile>(
            probe,
            options,
            id3,
            |f| of_id3v2(f.id3v2()),
            Some(id3_fallback::recover),
        ),
        Some(FileType::Wav) => {
            concrete::<WavFile>(probe, options, id3, |f| of_id3v2(f.id3v2()), None)
        }
        Some(FileType::Aiff) => {
            concrete::<AiffFile>(probe, options, id3, |f| of_id3v2(f.id3v2()), None)
        }
        Some(FileType::Flac) => concrete::<FlacFile>(
            probe,
            options,
            vorbis,
            |f| of_vorbis(f.vorbis_comments()),
            None,
        ),
        Some(FileType::Vorbis) => concrete::<VorbisFile>(
            probe,
            options,
            vorbis,
            |f| of_vorbis(Some(f.vorbis_comments())),
            None,
        ),
        Some(FileType::Opus) => concrete::<OpusFile>(
            probe,
            options,
            vorbis,
            |f| of_vorbis(Some(f.vorbis_comments())),
            None,
        ),
        _ => {
            let tagged = probe.read().map_err(|e| from_parse_error(&e))?;
            Ok((tagged, ConcreteLyrics::default()))
        }
    };
    let (tagged, concrete) = match concrete_read {
        Ok(read) => read,
        Err(Concrete::Fatal(error)) => return Err(error),
        Err(Concrete::Unreadable) => return Ok(None),
        Err(Concrete::Recovered(result)) => return result,
    };
    let text = lyrics_text(&tagged).or(concrete.fallback_text);
    let synced = concrete.synced;
    if text.is_none() && synced.is_empty() {
        return Ok(None);
    }
    Ok(Some(EmbeddedLyrics { text, synced }))
}

/// Why a concrete read gave nothing.
enum Concrete {
    /// The tag or file did not parse: the whole file has no lyrics.
    Unreadable,
    /// The concrete read failed and the fallback already gave the answer.
    Recovered(Result<Option<EmbeddedLyrics>, MediaError>),
    /// An error worth retrying, which says nothing about the file.
    Fatal(MediaError),
}

/// What a failed concrete read means for the file.
#[derive(Clone, Copy)]
enum OnFailure {
    /// The whole file has no lyrics (ID3 formats: a broken tag drops all).
    NoLyrics,
    /// The read is an error, like any generic read (Vorbis formats).
    Error,
}

/// What only the concrete file holds: the generic tag drops binary `SYLT`
/// frames, user text frames with lyrics descriptions and unmapped Vorbis keys.
#[derive(Default)]
struct ConcreteLyrics {
    synced: Vec<SyncedLine>,
    /// Plain text used only when the generic tags give none: ID3
    /// `TXXX:LYRICS` / `TXXX:UNSYNCEDLYRICS`, Vorbis `UNSYNCED LYRICS`.
    fallback_text: Option<String>,
}

fn of_id3v2(tag: Option<&Id3v2Tag>) -> ConcreteLyrics {
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
fn of_vorbis(comments: Option<&VorbisComments>) -> ConcreteLyrics {
    let fallback_text = comments
        .and_then(|c| c.get_all("UNSYNCED LYRICS").find(|text| usable_text(text)))
        .map(str::to_owned);
    ConcreteLyrics {
        synced: Vec::new(),
        fallback_text,
    }
}

/// Reads the lyrics left in a file whose concrete read failed for good.
type Recover = fn(&mut BufReader<File>) -> Result<Option<EmbeddedLyrics>, MediaError>;

/// Reads the probed file as `F` and takes what only the concrete type holds
/// before turning it into a generic [`TaggedFile`] (which consumes the file).
fn concrete<F>(
    probe: Probe<BufReader<File>>,
    options: ParseOptions,
    on_failure: OnFailure,
    extract: impl Fn(&F) -> ConcreteLyrics,
    recover: Option<Recover>,
) -> Result<(TaggedFile, ConcreteLyrics), Concrete>
where
    F: AudioFile + Into<TaggedFile>,
{
    let mut reader = probe.into_inner();
    reader
        .rewind()
        .map_err(|e| Concrete::Fatal(from_sniff_error(&e)))?;
    let file = F::read_from(&mut reader, options).map_err(|e| {
        match (concrete_failure(&e, on_failure), recover) {
            // A broken tag: keep what can still be read before the damage.
            (Concrete::Unreadable, Some(recover)) => Concrete::Recovered(recover(&mut reader)),
            (failure, _) => failure,
        }
    })?;
    let lyrics = extract(&file);
    Ok((file.into(), lyrics))
}

/// Splits a failed concrete read: a transient error is worth retrying; any
/// other failure follows `on_failure`.
fn concrete_failure(error: &FileParseError, on_failure: OnFailure) -> Concrete {
    let mapped = from_parse_error(error);
    if mapped.is_transient() || matches!(on_failure, OnFailure::Error) {
        Concrete::Fatal(mapped)
    } else {
        Concrete::Unreadable
    }
}

/// Text worth showing: not blank and within [`MAX_LYRICS_TEXT_BYTES`].
fn usable_text(text: &str) -> bool {
    text.len() <= MAX_LYRICS_TEXT_BYTES && !text.trim().is_empty()
}

/// The first usable lyrics text, looking at `Lyrics` then `UnsyncLyrics`
/// in the primary tag first, then in the other tags.
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

#[cfg(test)]
mod tests {
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
}
