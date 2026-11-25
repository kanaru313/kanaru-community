//! Tag reading with lofty. Plain Rust, no FFI. The caller opens the file
//! (the bridge rejects FIFOs and devices there), so this module never opens a
//! path itself.

pub mod errors;
mod id3_recovery;
pub mod language;
pub mod lyrics_reader;
mod lyrics_sylt;
pub mod mapping;
mod parse;
mod tags_fallback;

pub(crate) use parse::probe;
use parse::{parse, parse_options};

use std::fs::File;
use std::io::BufReader;
use std::path::Path;
use std::time::Duration;

use lofty::file::{AudioFile, FileType, TaggedFileExt};
use lofty::properties::FileProperties;
use lofty::tag::Tag;

use crate::limits::MAX_TAG_FILE_SECONDS;
use crate::{Cancel, MediaError};

/// Extensions lofty cannot parse and that carry no tags worth reading. DSD
/// files give a filename-only result without an error (the scanner lists
/// them; their folder cover still applies).
const NO_TAG_EXTENSIONS: [&str; 2] = ["dsf", "dff"];

/// Extensions lofty cannot parse and the library does not index.
const UNSUPPORTED_EXTENSIONS: [&str; 1] = ["wma"];

/// What one file says about itself. Numbers are `i32`/`i64` so the bridge
/// can hand them to Dart as they are.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct TrackTags {
    pub title: Option<String>,
    pub artists: Vec<String>,
    pub album: Option<String>,
    pub album_artists: Vec<String>,
    pub genres: Vec<String>,
    pub composer: Option<String>,
    pub year: Option<i32>,
    /// Most precise raw date (`YYYY`, `YYYY-MM`, `YYYY-MM-DD...`) whose year
    /// is `year`.
    pub release_date: Option<String>,
    pub track_no: Option<i32>,
    pub track_total: Option<i32>,
    pub disc_no: Option<i32>,
    pub disc_total: Option<i32>,
    pub title_sort: Option<String>,
    pub artist_sort: Option<String>,
    pub album_sort: Option<String>,
    /// The language tag as written in the file.
    pub language_tag: Option<String>,
    /// ISO 639-3, from the title; only set when the file has no language tag.
    pub detected_language: Option<String>,
    pub comment: Option<String>,
    /// Long description (Vorbis `DESCRIPTION`, MP4 `desc`, ID3 `COMM` with
    /// descriptor `description`), apart from the comment.
    pub description: Option<String>,
    pub duration_ms: Option<i64>,
    pub bitrate: Option<i32>,
    pub sample_rate: Option<i32>,
    pub bit_depth: Option<i32>,
    pub channels: Option<i32>,
    /// `FLAC`, `MP3`, ...: the container lofty recognised.
    pub codec: Option<String>,
}

/// Reads the tags of `path` through `open`, without pictures. The extension
/// is a hint only: the content decides (`.oga` may hold Opus, files are often
/// mislabeled). A panic inside lofty is the caller's to catch.
///
/// lofty caps each allocation (16 MiB by default), which stops a corrupt
/// length field from asking for gigabytes.
pub fn read_tags(
    path: &Path,
    open: &dyn Fn(&Path) -> Result<File, MediaError>,
    cancel: &Cancel,
) -> Result<TrackTags, MediaError> {
    let cancel = cancel.with_timeout(Duration::from_secs(MAX_TAG_FILE_SECONDS));
    cancel.check()?;

    match extension_rule(path) {
        ExtensionRule::Unsupported => return Err(MediaError::Unsupported),
        ExtensionRule::NoTags => {
            open(path)?;
            return Ok(TrackTags::default());
        }
        ExtensionRule::Normal => {}
    }
    let file = open(path)?;
    cancel.check()?;
    // The deadline only stops further work: a parse that finished is kept,
    // and so is the error of one that failed (the recovery checks the
    // deadline itself and keeps that error when it passed).
    let mut reader = BufReader::new(file);
    let options = parse_options(false);
    let (file_type, parsed) = parse(&mut reader, path, options)?;
    let tagged = match parsed {
        Ok(tagged) => tagged,
        Err(e) => {
            let error = errors::from_parse_error(&e);
            if error.is_transient() {
                return Err(error);
            }
            let Some(file_type) = file_type else {
                return Err(error);
            };
            let tag_failed = errors::is_tag_failure(&e);
            return tags_fallback::recover(&mut reader, file_type, tag_failed, options, &cancel)?
                .ok_or(error);
        }
    };
    Ok(assemble(
        tagged.file_type(),
        Some(tagged.properties()),
        tagged.primary_tag().or_else(|| tagged.first_tag()),
    ))
}

/// The tags of a file of `file_type` from its audio `properties` and its
/// `tag`, as the library stores them.
fn assemble(
    file_type: FileType,
    properties: Option<&FileProperties>,
    tag: Option<&Tag>,
) -> TrackTags {
    let mut tags = TrackTags {
        codec: codec_name(file_type),
        ..TrackTags::default()
    };
    if let Some(properties) = properties {
        mapping::apply_properties(&mut tags, properties);
    }
    if let Some(tag) = tag {
        mapping::apply_tag(&mut tags, tag);
    }
    if tags.language_tag.is_none() {
        tags.detected_language = tags
            .title
            .as_deref()
            .and_then(language::detect_title_language);
    }
    tags
}

/// How the extension changes what is read.
pub(crate) enum ExtensionRule {
    /// Read the file.
    Normal,
    /// DSD: no tags worth reading, no error.
    NoTags,
    /// Format lofty cannot read and the library does not index.
    Unsupported,
}

pub(crate) fn extension_rule(path: &Path) -> ExtensionRule {
    let extension = path
        .extension()
        .and_then(|e| e.to_str())
        .map(str::to_ascii_lowercase)
        .unwrap_or_default();
    if UNSUPPORTED_EXTENSIONS.contains(&extension.as_str()) {
        ExtensionRule::Unsupported
    } else if NO_TAG_EXTENSIONS.contains(&extension.as_str()) {
        ExtensionRule::NoTags
    } else {
        ExtensionRule::Normal
    }
}

fn codec_name(file_type: FileType) -> Option<String> {
    let name = match file_type {
        FileType::Aac => "AAC",
        FileType::Aiff => "AIFF",
        FileType::Ape => "APE",
        FileType::Flac => "FLAC",
        FileType::Mpeg => "MP3",
        FileType::Mp4 => "MP4",
        FileType::Mpc => "MPC",
        FileType::Opus => "Opus",
        FileType::Vorbis => "Vorbis",
        FileType::Speex => "Speex",
        FileType::Wav => "WAV",
        FileType::WavPack => "WavPack",
        _ => return None,
    };
    Some(name.to_owned())
}
