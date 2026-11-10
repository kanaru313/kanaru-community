//! Dart API for tags: a batch of paths in, one result per path out.
//!
//! Numbers are `i32`/`i64` only: flutter_rust_bridge maps `u64` to `BigInt`.

use std::cell::RefCell;
use std::fs::File;
use std::path::{Path, PathBuf};

use kanaru_media::tags::{read_tags, TrackTags};
use kanaru_media::{Cancel, MediaError};
use rayon::prelude::*;

use crate::error::{NativeError, NativeErrorKind};
use crate::guard::guarded;
use crate::pools;
use crate::source::{open_source, Source};

/// What one file says about itself. Mirrors `kanaru_media::tags::TrackTags`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TagFieldsDto {
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
    /// ISO 639-3 from the title; set only when the file has no language tag.
    pub detected_language: Option<String>,
    pub comment: Option<String>,
    pub duration_ms: Option<i64>,
    pub bitrate: Option<i32>,
    pub sample_rate: Option<i32>,
    pub bit_depth: Option<i32>,
    pub channels: Option<i32>,
    pub codec: Option<String>,
}

/// Result for one path: `fields` on success, `error` otherwise (never both).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TagReadDto {
    pub path: String,
    pub fields: Option<TagFieldsDto>,
    pub error: Option<NativeError>,
}

#[flutter_rust_bridge::frb(ignore)]
impl From<TrackTags> for TagFieldsDto {
    fn from(t: TrackTags) -> Self {
        Self {
            title: t.title,
            artists: t.artists,
            album: t.album,
            album_artists: t.album_artists,
            genres: t.genres,
            composer: t.composer,
            year: t.year,
            track_no: t.track_no,
            track_total: t.track_total,
            disc_no: t.disc_no,
            disc_total: t.disc_total,
            title_sort: t.title_sort,
            artist_sort: t.artist_sort,
            album_sort: t.album_sort,
            language_tag: t.language_tag,
            detected_language: t.detected_language,
            comment: t.comment,
            duration_ms: t.duration_ms,
            bitrate: t.bitrate,
            sample_rate: t.sample_rate,
            bit_depth: t.bit_depth,
            channels: t.channels,
            codec: t.codec,
        }
    }
}

/// Reads the tags of every path, one entry per path in the same order. Runs on
/// the background pool; each file is read under `guarded`, so a panic in one
/// parser is that entry's `Panic` error and the rest of the batch goes on.
pub fn read_tags_batch(paths: Vec<String>) -> Vec<TagReadDto> {
    read_batch_with(paths, read_file)
}

fn read_batch_with(
    paths: Vec<String>,
    read: impl Fn(&str) -> Result<TagFieldsDto, NativeError> + Sync,
) -> Vec<TagReadDto> {
    pools::background().install(|| {
        paths
            .into_par_iter()
            .map(|path| {
                let result = guarded(|| read(&path));
                match result {
                    Ok(fields) => TagReadDto {
                        path,
                        fields: Some(fields),
                        error: None,
                    },
                    Err(error) => TagReadDto {
                        path,
                        fields: None,
                        error: Some(error),
                    },
                }
            })
            .collect()
    })
}

fn read_file(path: &str) -> Result<TagFieldsDto, NativeError> {
    let parked = RefCell::new(None);
    let open = opener(&parked);
    let result = read_tags(Path::new(path), &open, &Cancel::new());
    result
        .map(TagFieldsDto::from)
        .map_err(|e| native_error(&parked, Path::new(path), e))
}

/// `open` callback for `kanaru_media`: opens through [`open_source`] (regular
/// files only, never blocks on a FIFO). `MediaError` cannot carry the exact
/// `NativeError`, so a failure is parked in `failure` and a stand-in with the
/// same class is returned; [`native_error`] swaps the parked error back in.
/// Only the first failure is kept; [`native_error`] matches it by path.
#[flutter_rust_bridge::frb(ignore)]
pub(crate) fn opener(
    failure: &RefCell<Option<(PathBuf, NativeError)>>,
) -> impl Fn(&Path) -> Result<File, MediaError> + '_ {
    move |path| {
        open_source(&Source::Path(path.to_string_lossy().into_owned())).map_err(|e| {
            let stand_in = media_error_of(&e);
            // The first failure stays: the audio file opens before any sidecar.
            failure.borrow_mut().get_or_insert((path.to_path_buf(), e));
            stand_in
        })
    }
}

/// The `NativeError` for `error` of the file at `path`: the one an [`opener`]
/// parked for that same path when `error` is its stand-in, otherwise the plain
/// conversion. A failure parked for another file (a skipped sidecar) never
/// stands in for this one.
#[flutter_rust_bridge::frb(ignore)]
pub(crate) fn native_error(
    failure: &RefCell<Option<(PathBuf, NativeError)>>,
    path: &Path,
    error: MediaError,
) -> NativeError {
    match failure.take() {
        Some((parked_path, parked)) if parked_path == path && media_error_of(&parked) == error => {
            parked
        }
        _ => error.into(),
    }
}

/// A `MediaError` of the same class as `e`: the same transient/permanent
/// verdict and, where media code looks at it, the same kind.
fn media_error_of(e: &NativeError) -> MediaError {
    match e.kind {
        NativeErrorKind::NotFound => MediaError::Io(std::io::ErrorKind::NotFound),
        NativeErrorKind::PermissionDenied => MediaError::Io(std::io::ErrorKind::PermissionDenied),
        NativeErrorKind::Unsupported => MediaError::Unsupported,
        NativeErrorKind::Corrupt => MediaError::Corrupt(e.detail.clone()),
        NativeErrorKind::TooLarge => MediaError::TooLarge,
        NativeErrorKind::Cancelled => MediaError::Cancelled,
        NativeErrorKind::Timeout => MediaError::Timeout,
        NativeErrorKind::Io | NativeErrorKind::Panic if e.transient => {
            MediaError::Io(std::io::ErrorKind::TimedOut)
        }
        NativeErrorKind::Io | NativeErrorKind::Panic => MediaError::Io(std::io::ErrorKind::Other),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    fn temp_path(name: &str) -> std::path::PathBuf {
        std::env::temp_dir().join(format!("kanaru-tags-api-{}-{name}", std::process::id()))
    }

    /// 100 ms of 16-bit mono 8 kHz silence.
    fn tiny_wav() -> Vec<u8> {
        let data_len: u32 = 1600;
        let mut b = b"RIFF".to_vec();
        b.extend_from_slice(&(36 + data_len).to_le_bytes());
        b.extend_from_slice(b"WAVEfmt ");
        b.extend_from_slice(&16u32.to_le_bytes());
        b.extend_from_slice(&1u16.to_le_bytes());
        b.extend_from_slice(&1u16.to_le_bytes());
        b.extend_from_slice(&8000u32.to_le_bytes());
        b.extend_from_slice(&16000u32.to_le_bytes());
        b.extend_from_slice(&2u16.to_le_bytes());
        b.extend_from_slice(&16u16.to_le_bytes());
        b.extend_from_slice(b"data");
        b.extend_from_slice(&data_len.to_le_bytes());
        b.resize(b.len() + data_len as usize, 0);
        b
    }

    fn write(path: &Path, bytes: &[u8]) {
        std::fs::File::create(path)
            .and_then(|mut f| f.write_all(bytes))
            .expect("write fixture");
    }

    #[test]
    fn missing_file_is_not_found() {
        let out = read_tags_batch(vec!["/nonexistent/kanaru/none.mp3".into()]);
        assert_eq!(out.len(), 1);
        let err = out[0].error.as_ref().expect("error");
        assert_eq!(err.kind, NativeErrorKind::NotFound);
        assert!(!err.transient);
        assert!(out[0].fields.is_none());
    }

    #[test]
    fn corrupt_and_good_files_each_get_an_entry_in_order() {
        let good = temp_path("good.wav");
        let bad = temp_path("bad.mp3");
        write(&good, &tiny_wav());
        write(&bad, &[7u8; 2048]);
        let paths: Vec<String> = [&bad, &good]
            .iter()
            .map(|p| p.to_string_lossy().into_owned())
            .collect();
        let out = read_tags_batch(paths.clone());
        let _ = std::fs::remove_file(&good);
        let _ = std::fs::remove_file(&bad);
        assert_eq!(out.len(), 2);
        assert_eq!(out[0].path, paths[0]);
        assert_eq!(out[1].path, paths[1]);
        let err = out[0].error.as_ref().expect("corrupt file has an error");
        assert!(matches!(
            err.kind,
            NativeErrorKind::Corrupt | NativeErrorKind::Unsupported
        ));
        assert!(!err.transient);
        let fields = out[1].fields.as_ref().expect("good file has fields");
        assert_eq!(fields.codec.as_deref(), Some("WAV"));
        assert_eq!(fields.sample_rate, Some(8000));
        assert_eq!(fields.duration_ms, Some(100));
        assert!(out[1].error.is_none());
    }

    #[test]
    fn a_panic_is_reported_for_that_entry_only() {
        let out = read_batch_with(
            vec!["a".into(), "boom".into(), "c".into()],
            |path| match path {
                "boom" => panic!("parser exploded"),
                _ => Ok(TrackTags::default().into()),
            },
        );
        assert_eq!(out.len(), 3);
        assert!(out[0].fields.is_some());
        assert!(out[2].fields.is_some());
        let err = out[1].error.as_ref().expect("panic error");
        assert_eq!(err.kind, NativeErrorKind::Panic);
        assert!(err.detail.contains("parser exploded"));
        assert!(!err.transient);
    }

    #[test]
    fn a_directory_is_rejected_by_the_source() {
        let dir = std::env::temp_dir().to_string_lossy().into_owned();
        let out = read_tags_batch(vec![dir]);
        let err = out[0].error.as_ref().expect("error");
        assert_eq!(err.kind, NativeErrorKind::Unsupported);
    }

    #[test]
    fn empty_batch_gives_empty_result() {
        assert!(read_tags_batch(Vec::new()).is_empty());
    }
}
