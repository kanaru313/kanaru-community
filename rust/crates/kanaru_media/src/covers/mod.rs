//! Finding, decoding and caching the cover of an audio file, and its colours.
//! Plain Rust, no FFI. Files are opened by the caller's `open` callback (the
//! bridge rejects FIFOs and devices there); only the cache folder is touched
//! directly.

pub mod cache;
pub mod colors;
pub mod decode_limits;
pub mod gate;
pub mod jpeg_header;
pub mod key;
pub mod sources;
pub mod thumbnail;
pub mod webp_exif;

use std::fs::File;
use std::path::Path;

use crate::{Cancel, MediaError};

pub use colors::CoverColors;
pub use sources::FolderMemo;

/// What `make_cover` found for one audio file.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CoverOutcome {
    /// A usable picture, stored under `key`. `made` is true when this call
    /// wrote the files (then `colors` are set when they could be worked out).
    Found {
        key: String,
        made: bool,
        colors: Option<CoverColors>,
    },
    /// Every source was checked and none was usable.
    NoCover,
}

/// Why `make_cover` failed.
#[derive(Debug)]
pub enum CoverError {
    /// The audio file (or a sidecar) could not be read. Transient or not as
    /// `MediaError::is_transient` says.
    Source(MediaError),
    /// Writing under the cache folder failed (full disk, read-only storage, a
    /// missing parent). Transient whatever its kind, and it will fail the
    /// same way for the next cover: callers stop the batch.
    Cache(std::io::Error),
    /// A sidecar or folder could not be read after it opened or listed, or a
    /// transient failure hit a sidecar. Nothing is known about the cover, and
    /// a sidecar has no change trigger of its own, so this is transient
    /// whatever its kind. Only this item is affected.
    Retry(String),
}

impl From<MediaError> for CoverError {
    fn from(e: MediaError) -> Self {
        CoverError::Source(e)
    }
}

impl std::fmt::Display for CoverError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CoverError::Source(e) => write!(f, "{e}"),
            CoverError::Cache(e) => write!(f, "cover cache: {e}"),
            CoverError::Retry(m) => write!(f, "cover source: {m}"),
        }
    }
}

impl std::error::Error for CoverError {}

/// Picks the cover of `audio` (see `sources` for the order), and unless both
/// sizes are cached already, decodes it once and writes
/// `<cache_dir>/covers/{thumb,full}/<key>.jpg`. `sidecars` false skips image
/// files next to the audio (no storage permission for them). `memo` carries
/// folder listings and sidecar results between the tracks of one chunk.
///
/// A bad embedded picture or sidecar falls through to the next source. When
/// the audio file itself cannot be parsed (permanent error) sidecars are
/// still tried, and the error is returned only if none is usable; a transient
/// error on the audio file or a sidecar ends the call at once.
pub fn make_cover(
    audio: &Path,
    open: &dyn Fn(&Path) -> Result<File, MediaError>,
    sidecars: bool,
    cache_dir: &Path,
    memo: &mut FolderMemo,
    cancel: &Cancel,
) -> Result<CoverOutcome, CoverError> {
    cancel.check()?;
    let mut audio_error = None;
    let embedded = match sources::embedded_pictures(audio, open, cancel) {
        Ok(pictures) => pictures,
        // The file is gone, or may read fine later: say so.
        Err(e) if e.is_transient() || e == MediaError::Io(std::io::ErrorKind::NotFound) => {
            return Err(e.into());
        }
        Err(e) => {
            audio_error = Some(e);
            Vec::new()
        }
    };
    for picture in embedded {
        cancel.check()?;
        if let Some(found) = store(&picture, cache_dir)? {
            return Ok(found);
        }
    }
    if sidecars {
        if let Some(found) = from_sidecars(audio, open, cache_dir, memo, cancel)? {
            return Ok(found);
        }
    }
    match audio_error {
        Some(e) => Err(e.into()),
        None => Ok(CoverOutcome::NoCover),
    }
}

fn from_sidecars(
    audio: &Path,
    open: &dyn Fn(&Path) -> Result<File, MediaError>,
    cache_dir: &Path,
    memo: &mut FolderMemo,
    cancel: &Cancel,
) -> Result<Option<CoverOutcome>, CoverError> {
    let Some(dir) = audio.parent() else {
        return Ok(None);
    };
    let candidates = sources::sidecar_candidates(audio, memo.listing(dir)?);
    // A candidate that cannot be read right now does not hide the next one;
    // the first such failure is returned only if no candidate gives a cover.
    let mut retry = None;
    for path in candidates {
        cancel.check()?;
        match memo.known_sidecar(&path) {
            Some(Some(key)) => {
                return Ok(Some(CoverOutcome::Found {
                    key: key.clone(),
                    made: false,
                    colors: None,
                }));
            }
            Some(None) => continue,
            None => {}
        }
        let found = match sources::read_sidecar(&path, open) {
            Ok(Some(bytes)) => store(&bytes, cache_dir)?,
            Ok(None) => None,
            Err(e @ CoverError::Retry(_)) => {
                retry.get_or_insert(e);
                continue;
            }
            Err(e) => return Err(e),
        };
        let key = match &found {
            Some(CoverOutcome::Found { key, .. }) => Some(key.clone()),
            _ => None,
        };
        memo.remember_sidecar(&path, key);
        if found.is_some() {
            return Ok(found);
        }
    }
    retry.map_or(Ok(None), Err)
}

/// Stores the picture `bytes` in the cache and returns its outcome, or `None`
/// when the picture is not usable (wrong format, over a limit, damaged).
fn store(bytes: &[u8], cache_dir: &Path) -> Result<Option<CoverOutcome>, CoverError> {
    let Some(header) = sources::validate_header(bytes) else {
        return Ok(None);
    };
    let key = key::cover_key(bytes);
    if cache::both_exist(cache_dir, &key) {
        return Ok(Some(CoverOutcome::Found {
            key,
            made: false,
            colors: None,
        }));
    }
    let Some(jpegs) = thumbnail::make_jpegs(bytes, header.format, header.pixels()) else {
        return Ok(None);
    };
    cache::write_both(cache_dir, &key, &jpegs.thumb, &jpegs.full).map_err(CoverError::Cache)?;
    // The files are written: a panic while working out colours must not fail
    // the cover.
    let colors = std::panic::catch_unwind(|| colors::colors_of_thumbnail(&jpegs.thumb))
        .ok()
        .flatten();
    Ok(Some(CoverOutcome::Found {
        key,
        made: true,
        colors,
    }))
}
