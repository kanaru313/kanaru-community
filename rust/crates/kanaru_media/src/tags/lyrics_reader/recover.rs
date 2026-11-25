//! Lyrics left in a file whose concrete read failed for a reason that is not
//! transient, found where each container keeps its ID3v2 tag and read with
//! symphonia through `tags::id3_recovery` (always bounded there):
//!
//! - MP3: the ID3v2 tags at the start of the file;
//! - WAV and AIFF: the top-level `id3 `/`ID3 ` chunks;
//! - FLAC: the stream after its ID3v2 prefixes, read again with lofty as if
//!   they were not there (Vorbis lyrics), then the prefixes themselves.
//!
//! Each tag or chunk is looked at in file order and the first one with
//! lyrics wins; all of them share one byte budget
//! ([`MAX_ID3_FALLBACK_BYTES`](crate::tags::id3_recovery::MAX_ID3_FALLBACK_BYTES)).
//! Returns `None` when recovery does not apply to the file (the caller then
//! answers as without it), `Some(Err)` for a transient I/O error.

use std::io::{Read, Seek};

use lofty::config::ParseOptions;
use lofty::file::{AudioFile, TaggedFile};
use lofty::flac::FlacFile;

use super::extract::of_vorbis;
use super::id3_fallback::lyrics_of;
use super::{assemble, EmbeddedLyrics};
use crate::tags::errors::from_parse_error;
use crate::tags::id3_recovery::iff::{id3_chunks, Iff};
use crate::tags::id3_recovery::prefix::{flac_start, id3_prefixes, PrefixSpan};
use crate::tags::id3_recovery::views::OffsetView;
use crate::tags::id3_recovery::{first_recovered, non_transient};
use crate::MediaError;

/// What a recovery gives: `None` = not applicable, else the answer.
pub(super) type Recovered = Option<Result<Option<EmbeddedLyrics>, MediaError>>;

/// The lyrics of the first ID3v2 tag at the start of an MP3 that holds any.
/// Always applies: `Ok(None)` when nothing usable is left, also for an empty
/// or truncated file.
pub(super) fn recover_mp3<R: Read + Seek>(reader: &mut R, _: ParseOptions) -> Recovered {
    Some(id3_prefixes(reader).and_then(|prefixes| prefix_lyrics(reader, &prefixes)))
}

pub(super) fn recover_wav<R: Read + Seek>(reader: &mut R, _: ParseOptions) -> Recovered {
    Some(chunk_lyrics(reader, Iff::Riff))
}

pub(super) fn recover_aiff<R: Read + Seek>(reader: &mut R, _: ParseOptions) -> Recovered {
    Some(chunk_lyrics(reader, Iff::Form))
}

/// A FLAC stream behind broken ID3v2 prefixes. Not applicable without a
/// prefix. When `fLaC` and STREAMINFO sit exactly where the prefixes end and
/// the stream reads, the answer is the stream's, as for a healthy FLAC
/// (Vorbis lyrics, else the prefixes' lyrics, else `Ok(None)`). Otherwise
/// only the prefixes' lyrics, and nothing there is not applicable.
pub(super) fn recover_flac<R: Read + Seek>(reader: &mut R, options: ParseOptions) -> Recovered {
    let prefixes = match id3_prefixes(reader) {
        Ok(prefixes) if prefixes.is_empty() => return None,
        Ok(prefixes) => prefixes,
        Err(e) => return Some(Err(e)),
    };
    let stream = match flac_start(reader, &prefixes) {
        Ok(Some(at)) => match read_flac_at(reader, at, options) {
            Ok(stream) => stream,
            Err(e) => return Some(Err(e)),
        },
        Ok(None) => None,
        Err(e) => return Some(Err(e)),
    };
    if let Some(Some(lyrics)) = stream {
        return Some(Ok(Some(lyrics)));
    }
    match prefix_lyrics(reader, &prefixes) {
        Ok(Some(lyrics)) => Some(Ok(Some(lyrics))),
        // The stream read: a FLAC without lyrics.
        Ok(None) if stream.is_some() => Some(Ok(None)),
        Ok(None) => None,
        Err(e) => Some(Err(e)),
    }
}

/// The lyrics of the FLAC stream starting at `at`, read as a file of its
/// own. `Ok(None)` when it does not read for a reason that is not
/// transient; `Ok(Some(None))` when it reads but holds no lyrics.
fn read_flac_at<R: Read + Seek>(
    reader: &mut R,
    at: u64,
    options: ParseOptions,
) -> Result<Option<Option<EmbeddedLyrics>>, MediaError> {
    let mut view = match OffsetView::new(&mut *reader, at) {
        Ok(view) => view,
        Err(e) => return non_transient(MediaError::from(e)),
    };
    let file = match FlacFile::read_from(&mut view, options) {
        Ok(file) => file,
        Err(e) => return non_transient(from_parse_error(&e)),
    };
    let concrete = of_vorbis(file.vorbis_comments());
    let tagged: TaggedFile = file.into();
    Ok(Some(assemble(&tagged, concrete)))
}

fn prefix_lyrics<R: Read + Seek>(
    reader: &mut R,
    prefixes: &[PrefixSpan],
) -> Result<Option<EmbeddedLyrics>, MediaError> {
    // The declared size bounds a prefix; one past the end of the file is
    // read as far as the file goes.
    first_lyrics(reader, prefixes.iter().map(|p| (p.at, u64::MAX)))
}

fn chunk_lyrics<R: Read + Seek>(
    reader: &mut R,
    kind: Iff,
) -> Result<Option<EmbeddedLyrics>, MediaError> {
    let chunks = id3_chunks(reader, kind)?;
    first_lyrics(reader, chunks.iter().map(|c| (c.body_at, c.body_len)))
}

/// The lyrics of the first tag with any (see [`first_recovered`]).
fn first_lyrics<R: Read + Seek>(
    reader: &mut R,
    tags: impl IntoIterator<Item = (u64, u64)>,
) -> Result<Option<EmbeddedLyrics>, MediaError> {
    first_recovered(reader, tags, |frames| lyrics_of(&frames))
}

#[cfg(test)]
mod tests;
