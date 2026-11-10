//! Tag reading with lofty. Plain Rust, no FFI. The caller opens the file
//! (the bridge rejects FIFOs and devices there), so this module never opens a
//! path itself.

pub mod errors;
pub mod language;
pub mod mapping;

use std::fs::File;
use std::io::BufReader;
use std::path::Path;
use std::time::Duration;

use lofty::config::{ParseOptions, ParsingMode};
use lofty::file::{AudioFile, FileType, TaggedFileExt};
use lofty::probe::Probe;

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
    // The deadline only stops further work: a parse that finished is kept.
    let tagged = probe(file, path, false)?;

    let mut tags = TrackTags {
        codec: codec_name(tagged.file_type()),
        ..TrackTags::default()
    };
    mapping::apply_properties(&mut tags, tagged.properties());
    if let Some(tag) = tagged.primary_tag().or_else(|| tagged.first_tag()) {
        mapping::apply_tag(&mut tags, tag);
    }
    if tags.language_tag.is_none() {
        tags.detected_language = tags
            .title
            .as_deref()
            .and_then(language::detect_title_language);
    }
    Ok(tags)
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

/// Parses `file` with lofty. The extension is only a hint: the content is
/// sniffed and decides. Pictures are read only when `with_pictures`.
pub(crate) fn probe(
    file: File,
    path: &Path,
    with_pictures: bool,
) -> Result<lofty::file::TaggedFile, MediaError> {
    let options = ParseOptions::new()
        .read_cover_art(with_pictures)
        .parsing_mode(ParsingMode::BestAttempt);
    let reader = BufReader::new(file);
    let probe = match FileType::from_path(path) {
        Some(file_type) => Probe::with_file_type(reader, file_type),
        None => Probe::new(reader),
    };
    probe
        .options(options)
        .guess_file_type()
        .map_err(|e| errors::from_sniff_error(&e))?
        .read()
        .map_err(|e| errors::from_parse_error(&e))
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
