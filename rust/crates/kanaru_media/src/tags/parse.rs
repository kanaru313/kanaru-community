//! The single lofty parse of a file: the content is sniffed (the extension is
//! a hint) and parsed once, through a borrowed reader that outlives a failed
//! parse.

use std::fs::File;
use std::io::BufReader;
use std::path::Path;

use lofty::config::{ParseOptions, ParsingMode};
use lofty::error::FileParseError;
use lofty::file::{FileType, TaggedFile};
use lofty::probe::Probe;

use super::errors::{from_parse_error, from_sniff_error, is_tag_failure};
use crate::MediaError;

/// Parses `file` with lofty. The extension is only a hint: the content is
/// sniffed and decides. Pictures are read only when `with_pictures`.
/// `Ok(None)`: lofty failed on a tag, not on the audio, for a lasting
/// reason; the file has no tag to use.
pub(crate) fn probe(
    file: File,
    path: &Path,
    with_pictures: bool,
) -> Result<Option<TaggedFile>, MediaError> {
    let mut reader = BufReader::new(file);
    let (_, parsed) = parse(&mut reader, path, parse_options(with_pictures))?;
    match parsed {
        Ok(tagged) => Ok(Some(tagged)),
        Err(e) => {
            let error = from_parse_error(&e);
            if !error.is_transient() && is_tag_failure(&e) {
                Ok(None)
            } else {
                Err(error)
            }
        }
    }
}

pub(super) fn parse_options(with_pictures: bool) -> ParseOptions {
    ParseOptions::new()
        .read_cover_art(with_pictures)
        .parsing_mode(ParsingMode::BestAttempt)
}

/// The file type sniffed from the content of `reader` (the extension of
/// `path` as a hint) and lofty's parse of it. The reader is borrowed, so it
/// is still there after a failed parse. `Err`: the sniff itself failed.
pub(super) fn parse(
    reader: &mut BufReader<File>,
    path: &Path,
    options: ParseOptions,
) -> Result<(Option<FileType>, Result<TaggedFile, FileParseError>), MediaError> {
    let probe = match FileType::from_path(path) {
        Some(file_type) => Probe::with_file_type(reader, file_type),
        None => Probe::new(reader),
    };
    let probe = probe
        .options(options)
        .guess_file_type()
        .map_err(|e| from_sniff_error(&e))?;
    let file_type = probe.file_type();
    Ok((file_type, probe.read()))
}
