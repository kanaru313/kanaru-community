//! Reads the lyrics stored in one audio file with lofty. The caller opens the
//! file (the bridge rejects FIFOs and devices there); nothing here opens a
//! path.

use std::fs::File;
use std::io::{BufReader, Seek};

use lofty::config::{ParseOptions, ParsingMode};
use lofty::error::FileParseError;
use lofty::file::{AudioFile, FileType, TaggedFile, TaggedFileExt};
use lofty::flac::FlacFile;
use lofty::iff::aiff::AiffFile;
use lofty::iff::wav::WavFile;
use lofty::mpeg::MpegFile;
use lofty::ogg::{OpusFile, VorbisFile};
use lofty::probe::Probe;
use lofty::tag::ItemKey;

use super::errors::{from_parse_error, from_sniff_error};
use crate::MediaError;

mod extract;
mod id3_fallback;
mod recover;
pub use super::id3_recovery::{MAX_ID3_FALLBACK_BYTES, MAX_ID3_FALLBACK_FRAMES};
use extract::{of_id3v2, of_vorbis, ConcreteLyrics};

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
/// - an MP3, WAV or AIFF that fails the concrete read for a reason other
///   than a transient I/O error: the lyrics kept before the first structural
///   error of its first ID3v2 tag (MP3 prefix, WAV/AIFF `id3 ` chunk) that
///   still holds any (`recover`), else `Ok(None)`; plain text next to a
///   broken tag is dropped. This includes an empty or truncated file;
/// - a FLAC in the same case behind ID3v2 prefixes: when the stream starts
///   exactly where they end and reads, the answer of a healthy FLAC (Vorbis
///   lyrics, else the prefixes' lyrics, else `Ok(None)`); otherwise the
///   prefixes' lyrics, and `Err` when they hold none;
/// - a transient I/O error anywhere, a failure to sniff the content, or a
///   failed rewind before the concrete read: `Err` (mapped by `tags::errors`),
///   so the caller may retry when it is transient;
/// - FLAC without an ID3v2 prefix, Ogg Vorbis, Opus and every other format
///   whose parse fails (unknown format, corrupt, empty or truncated, where
///   lofty reports `UnexpectedEof`): `Err`.
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
    // A broken ID3 tag keeps what `recover` finds; a failed Vorbis parse is
    // an error unless a broken ID3 prefix caused it.
    let id3 = OnFailure::NoLyrics;
    let vorbis = OnFailure::Error;
    let concrete_read = match probe.file_type() {
        Some(FileType::Mpeg) => concrete::<MpegFile>(
            probe,
            options,
            id3,
            |f| of_id3v2(f.id3v2()),
            Some(recover::recover_mp3),
        ),
        Some(FileType::Wav) => concrete::<WavFile>(
            probe,
            options,
            id3,
            |f| of_id3v2(f.id3v2()),
            Some(recover::recover_wav),
        ),
        Some(FileType::Aiff) => concrete::<AiffFile>(
            probe,
            options,
            id3,
            |f| of_id3v2(f.id3v2()),
            Some(recover::recover_aiff),
        ),
        Some(FileType::Flac) => concrete::<FlacFile>(
            probe,
            options,
            vorbis,
            |f| of_vorbis(f.vorbis_comments()),
            Some(recover::recover_flac),
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
    Ok(assemble(&tagged, concrete))
}

/// The lyrics of a read file: the generic tags' text first, then what only
/// the concrete type held.
fn assemble(tagged: &TaggedFile, concrete: ConcreteLyrics) -> Option<EmbeddedLyrics> {
    let text = lyrics_text(tagged).or(concrete.fallback_text);
    let synced = concrete.synced;
    if text.is_none() && synced.is_empty() {
        return None;
    }
    Some(EmbeddedLyrics { text, synced })
}

/// Why a concrete read gave nothing.
enum Concrete {
    /// The tag or file did not parse: the whole file has no lyrics.
    Unreadable,
    /// The concrete read failed and the recovery already gave the answer.
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

/// Reads the lyrics left in a file whose concrete read failed for good;
/// `None` when that does not apply to the file.
type Recover = fn(&mut BufReader<File>, ParseOptions) -> recover::Recovered;

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
    // Only a failed read reaches the recovery: a file that reads costs no
    // extra I/O, and a transient failure is retried instead.
    let file = F::read_from(&mut reader, options).map_err(|e| {
        match recover
            .filter(|_| should_recover(&e))
            .and_then(|r| r(&mut reader, options))
        {
            Some(result) => Concrete::Recovered(result),
            None => concrete_failure(&e, on_failure),
        }
    })?;
    let lyrics = extract(&file);
    Ok((file.into(), lyrics))
}

/// Whether a failed concrete read goes to the recovery: only a lasting
/// failure does; a transient one is retried by the caller instead.
fn should_recover(error: &FileParseError) -> bool {
    !from_parse_error(error).is_transient()
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
mod tests;
