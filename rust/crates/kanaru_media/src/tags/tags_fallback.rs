//! The tags of a file whose lofty read failed for a reason that is not
//! transient and that keeps an ID3v2 tag where its format does: the frames
//! read before the damage (`id3_recovery`, always bounded) and the audio
//! properties of lofty reading the file again without that tag.
//!
//! - MP3: the tags at the start; read again from after them (ID3v1, APE).
//! - WAV, AIFF: the `id3 `/`ID3 ` chunks, read again with their ids as
//!   `JUNK` (RIFF INFO, AIFF text); if that fails, once more without tags.
//! - FLAC: the stream after the prefixes, read as a file of its own.
//!
//! As in a healthy file, the ID3v2 tag wins for MP3, WAV and AIFF, the
//! Vorbis comments for FLAC. Other types are not recovered.

use std::io::{self, Read, Seek, SeekFrom};

use lofty::config::ParseOptions;
use lofty::file::{AudioFile, FileType, TaggedFile, TaggedFileExt};
use lofty::flac::FlacFile;
use lofty::iff::aiff::AiffFile;
use lofty::iff::wav::WavFile;
use lofty::mpeg::MpegFile;
use lofty::tag::{Tag, TagExt};

use super::errors::from_parse_error;
use super::id3_recovery::iff::{id3_chunks, Iff};
use super::id3_recovery::prefix::{audio_start, flac_start, id3_prefixes, PrefixSpan};
use super::id3_recovery::views::{MaskedView, OffsetView};
use super::id3_recovery::{first_recovered, non_transient, to_lofty};
use super::{assemble, TrackTags};
use crate::{Cancel, MediaError};

/// What survived of the file.
#[derive(Default)]
struct Found {
    /// The tag rebuilt from the broken ID3v2 tag, when it holds any item.
    id3: Option<Tag>,
    /// lofty's read of the file without the broken tag.
    reread: Option<TaggedFile>,
}

/// The tags of a `file_type` file lofty refused, read again from `reader`
/// with `options`. `Ok(None)`: no tag item and no audio properties
/// recovered; the caller keeps lofty's error. `Err`: a transient I/O error,
/// or `cancel` fired.
pub(super) fn recover<R: Read + Seek>(
    reader: &mut R,
    file_type: FileType,
    options: ParseOptions,
    cancel: &Cancel,
) -> Result<Option<TrackTags>, MediaError> {
    let found = match file_type {
        FileType::Mpeg => mp3(reader, options, cancel)?,
        FileType::Wav => iff(reader, Iff::Riff, options, cancel)?,
        FileType::Aiff => iff(reader, Iff::Form, options, cancel)?,
        FileType::Flac => flac(reader, options, cancel)?,
        _ => return Ok(None),
    };
    let reread_tag = found.reread.as_ref().and_then(tag_of);
    let tag = if file_type == FileType::Flac {
        reread_tag.or(found.id3.as_ref())
    } else {
        found.id3.as_ref().or(reread_tag)
    };
    if tag.is_none() && found.reread.is_none() {
        return Ok(None);
    }
    let properties = found.reread.as_ref().map(TaggedFile::properties);
    Ok(Some(assemble(file_type, properties, tag)))
}

/// The tag a healthy read uses, when it holds anything.
fn tag_of(file: &TaggedFile) -> Option<&Tag> {
    file.primary_tag()
        .or_else(|| file.first_tag())
        .filter(|tag| !tag.is_empty())
}

fn mp3<R: Read + Seek>(
    r: &mut R,
    options: ParseOptions,
    cancel: &Cancel,
) -> Result<Found, MediaError> {
    let prefixes = id3_prefixes(r)?;
    if prefixes.is_empty() {
        return Ok(Found::default());
    }
    let id3 = prefix_tag(r, &prefixes)?;
    let reread = match audio_start(&prefixes) {
        Some(at) => {
            cancel.check()?;
            read_as::<MpegFile>(OffsetView::new(&mut *r, at), options)?
        }
        None => None,
    };
    Ok(Found { id3, reread })
}

fn iff<R: Read + Seek>(
    r: &mut R,
    kind: Iff,
    options: ParseOptions,
    cancel: &Cancel,
) -> Result<Found, MediaError> {
    let chunks = id3_chunks(r, kind)?;
    if chunks.is_empty() {
        return Ok(Found::default());
    }
    let id3 = first_tag(r, chunks.iter().map(|c| (c.body_at, c.body_len)))?;
    let masks: Vec<u64> = chunks.iter().map(|c| c.header_at).collect();
    let mut read = |options| {
        cancel.check()?;
        let view = r
            .seek(SeekFrom::Start(0))
            .and_then(|_| MaskedView::new(&mut *r, &masks));
        match kind {
            Iff::Riff => read_as::<WavFile>(view, options),
            Iff::Form => read_as::<AiffFile>(view, options),
        }
    };
    let mut reread = read(options)?;
    if reread.is_none() {
        // After a damaged chunk lofty's walk may differ from ours: read the
        // properties alone, which never looks at a tag chunk.
        let mut properties_only = options;
        reread = read(properties_only.read_tags(false))?;
    }
    Ok(Found { id3, reread })
}

fn flac<R: Read + Seek>(
    r: &mut R,
    options: ParseOptions,
    cancel: &Cancel,
) -> Result<Found, MediaError> {
    let prefixes = id3_prefixes(r)?;
    if prefixes.is_empty() {
        return Ok(Found::default());
    }
    let reread = match flac_start(r, &prefixes)? {
        Some(at) => {
            cancel.check()?;
            read_as::<FlacFile>(OffsetView::new(&mut *r, at), options)?
        }
        None => None,
    };
    // The prefixes' frames are read only when the stream has no tag.
    let id3 = match reread.as_ref().and_then(tag_of) {
        Some(_) => None,
        None => prefix_tag(r, &prefixes)?,
    };
    Ok(Found { id3, reread })
}

fn prefix_tag<R: Read + Seek>(
    r: &mut R,
    prefixes: &[PrefixSpan],
) -> Result<Option<Tag>, MediaError> {
    // The declared size bounds a prefix; one past the end of the file is
    // read as far as the file goes.
    first_tag(r, prefixes.iter().map(|p| (p.at, u64::MAX)))
}

/// The tag of the first ID3v2 tag whose frames hold any item lofty maps.
fn first_tag<R: Read + Seek>(
    r: &mut R,
    tags: impl IntoIterator<Item = (u64, u64)>,
) -> Result<Option<Tag>, MediaError> {
    first_recovered(r, tags, |frames| {
        Some(Tag::from(to_lofty(&frames))).filter(|tag| !tag.is_empty())
    })
}

/// lofty's read of an `F` file through `view`. `Ok(None)` when the view or
/// the read fails for a reason that is not transient.
fn read_as<F: AudioFile + Into<TaggedFile>>(
    view: io::Result<impl Read + Seek>,
    options: ParseOptions,
) -> Result<Option<TaggedFile>, MediaError> {
    let mut view = match view {
        Ok(view) => view,
        Err(e) => return non_transient(MediaError::from(e)),
    };
    match F::read_from(&mut view, options) {
        Ok(file) => Ok(Some(file.into())),
        Err(e) => non_transient(from_parse_error(&e)),
    }
}

#[cfg(test)]
mod tests;
