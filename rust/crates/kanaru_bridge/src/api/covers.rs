//! Dart API for covers: thumbnails (`thumb` 256 px, `full` 1024 px) in the
//! cache folder, and their colours.
//!
//! Numbers are `i32`/`i64` only: flutter_rust_bridge maps `u64` to `BigInt`.
//! Colours are ARGB carried as `i64`.

use std::cell::RefCell;
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};

use kanaru_media::covers::key::{is_cover_key, relative_path, CoverSize};
use kanaru_media::covers::{colors, make_cover, CoverColors, CoverError, CoverOutcome, FolderMemo};
use kanaru_media::Cancel;
use rayon::prelude::*;

use super::tags::{native_error, opener};
use crate::error::{NativeError, NativeErrorKind};
use crate::guard::guarded;
use crate::pools;

/// Tracks of one folder handled together, at most. Tracks of an album share
/// one decode of their `cover.jpg` inside a chunk. Small, so a call of one
/// album (about 32 files) still spreads over the workers: a `cover.jpg` is at
/// worst decoded once per chunk, and the identical writes are atomic.
const CHUNK_TRACKS: usize = 8;

/// One audio file to find a cover for.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoverRequestDto {
    pub track_id: i64,
    pub path: String,
}

/// Seed and palette of a cover, opaque ARGB as `i64`; the palette is the most
/// common colour first.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoverColorsDto {
    pub seed: i64,
    pub palette: Vec<i64>,
}

/// Named `Found`, `NoCover`, `Failed` (not `None`) so it never reads as
/// `Option::None` on the Dart side.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CoverStatusDto {
    /// A cover is stored under `key`.
    Found,
    /// Every source was checked and none was usable.
    NoCover,
    /// See `error`; `error.transient` says whether to try again later.
    Failed,
}

/// Result for one request. `Found`: `key`, both relative paths (under the
/// cache folder), `made` (the files were written by this call) and `colors`
/// when this call made them. `Failed`: `error`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoverResultDto {
    pub track_id: i64,
    pub status: CoverStatusDto,
    pub key: Option<String>,
    pub made: bool,
    pub thumb_rel: Option<String>,
    pub full_rel: Option<String>,
    pub colors: Option<CoverColorsDto>,
    pub error: Option<NativeError>,
}

/// Colours of one cached `thumb`: `colors`, or `error` (a malformed key, a
/// missing or damaged file). Both null: a gray cover, which has no colours.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoverColorsResultDto {
    pub key: String,
    pub colors: Option<CoverColorsDto>,
    pub error: Option<NativeError>,
}

#[flutter_rust_bridge::frb(ignore)]
impl From<CoverColors> for CoverColorsDto {
    fn from(c: CoverColors) -> Self {
        Self {
            seed: i64::from(c.seed),
            palette: c.palette.into_iter().map(i64::from).collect(),
        }
    }
}

/// Finds and caches the cover of every item, one result per item in the same
/// order. Runs on the background pool; each item is worked under `guarded`.
/// `cache_dir` is the app cache folder. `sidecars` false skips image files
/// next to the audio.
///
/// A failure to write under `cache_dir` is reported as transient for that item
/// and stops the batch: items not started come back `Failed` (transient)
/// untouched.
pub fn extract_covers_batch(
    cache_dir: String,
    items: Vec<CoverRequestDto>,
    sidecars: bool,
) -> Vec<CoverResultDto> {
    if !Path::new(&cache_dir).is_absolute() {
        return items
            .iter()
            .map(|item| failed(item.track_id, relative_cache_error()))
            .collect();
    }
    let cache_dir = PathBuf::from(cache_dir);
    run_batch(items, |audio, memo| {
        let parked = RefCell::new(None);
        let open = opener(&parked);
        let result = make_cover(audio, &open, sidecars, &cache_dir, memo, &Cancel::new());
        result.map_err(|e| match e {
            CoverError::Source(e) => Failure::Item(native_error(&parked, audio, e)),
            CoverError::Cache(e) => Failure::Cache(cache_error(&e)),
            CoverError::Retry(m) => Failure::Item(NativeError::new(NativeErrorKind::Io, m, true)),
        })
    })
}

/// The colours of cached `thumb` files, for keys whose colours are missing.
/// One result per key in the same order. A key that fails the format check is
/// rejected without touching the disk.
pub fn cover_colors_for(cache_dir: String, keys: Vec<String>) -> Vec<CoverColorsResultDto> {
    if !Path::new(&cache_dir).is_absolute() {
        return keys
            .into_iter()
            .map(|key| CoverColorsResultDto {
                key,
                colors: None,
                error: Some(relative_cache_error()),
            })
            .collect();
    }
    let cache_dir = PathBuf::from(cache_dir);
    pools::background().install(|| {
        keys.into_par_iter()
            .map(|key| {
                let result = guarded(|| {
                    if !is_cover_key(&key) {
                        return Err(NativeError::new(
                            NativeErrorKind::Unsupported,
                            "not a cover key",
                            false,
                        ));
                    }
                    let parked = RefCell::new(None);
                    let open = opener(&parked);
                    let thumb = relative_path(&key, CoverSize::Thumb)
                        .map(|relative| cache_dir.join(relative))
                        .unwrap_or_default();
                    let result = colors::colors_of_cached_thumb(&cache_dir, &key, &open);
                    result.map_err(|e| native_error(&parked, &thumb, e))
                });
                match result {
                    // `None` without an error: a gray cover has no colours.
                    Ok(c) => CoverColorsResultDto {
                        key,
                        colors: c.map(Into::into),
                        error: None,
                    },
                    Err(error) => CoverColorsResultDto {
                        key,
                        colors: None,
                        error: Some(error),
                    },
                }
            })
            .collect()
    })
}

/// Why one item failed.
enum Failure {
    /// This item only.
    Item(NativeError),
    /// The cache folder: this item, and the batch stops.
    Cache(NativeError),
}

/// A relative `cache_dir` would write under the process's working directory.
fn relative_cache_error() -> NativeError {
    NativeError::new(
        NativeErrorKind::Unsupported,
        "cache_dir must be an absolute path",
        false,
    )
}

/// Start of the `detail` of every cache failure. The Dart scanner reads it
/// (`coverCacheErrorPrefix` in `native_cover_maker.dart`) to end the cover
/// pass early, so changing it needs the Dart constant changed too.
const CACHE_DETAIL_PREFIX: &str = "cover cache";

/// Any error writing under the cache folder is transient, whatever its kind:
/// the cover is fine, the folder is not.
fn cache_error(e: &std::io::Error) -> NativeError {
    NativeError::new(
        NativeErrorKind::Io,
        format!("{CACHE_DETAIL_PREFIX}: {e}"),
        true,
    )
}

/// Runs `work` for every item on the background pool. Items are grouped by
/// folder and cut into chunks; one chunk is one task with one [`FolderMemo`].
fn run_batch(
    items: Vec<CoverRequestDto>,
    work: impl Fn(&Path, &mut FolderMemo) -> Result<CoverOutcome, Failure> + Sync,
) -> Vec<CoverResultDto> {
    let cache_stopped = AtomicBool::new(false);
    let mut by_folder: BTreeMap<&Path, Vec<usize>> = BTreeMap::new();
    for (index, item) in items.iter().enumerate() {
        let folder = Path::new(&item.path).parent().unwrap_or(Path::new(""));
        by_folder.entry(folder).or_default().push(index);
    }
    let chunks: Vec<&[usize]> = by_folder
        .values()
        .flat_map(|indexes| indexes.chunks(CHUNK_TRACKS))
        .collect();

    let done: Vec<Vec<(usize, CoverResultDto)>> = pools::background().install(|| {
        chunks
            .par_iter()
            .map(|chunk| {
                let mut memo = FolderMemo::default();
                chunk
                    .iter()
                    .map(|&index| {
                        let result = run_item(&items[index], &mut memo, &cache_stopped, &work);
                        (index, result)
                    })
                    .collect()
            })
            .collect()
    });

    let mut out: Vec<Option<CoverResultDto>> = vec![None; items.len()];
    for (index, result) in done.into_iter().flatten() {
        out[index] = Some(result);
    }
    out.into_iter()
        .zip(&items)
        .map(|(result, item)| {
            result.unwrap_or_else(|| {
                failed(
                    item.track_id,
                    NativeError::new(NativeErrorKind::Io, "cover item was not run", true),
                )
            })
        })
        .collect()
}

fn run_item(
    item: &CoverRequestDto,
    memo: &mut FolderMemo,
    cache_stopped: &AtomicBool,
    work: &(impl Fn(&Path, &mut FolderMemo) -> Result<CoverOutcome, Failure> + Sync),
) -> CoverResultDto {
    if cache_stopped.load(Ordering::Relaxed) {
        return failed(
            item.track_id,
            NativeError::new(
                NativeErrorKind::Io,
                format!("{CACHE_DETAIL_PREFIX} is not writable; item skipped"),
                true,
            ),
        );
    }
    let result = guarded(|| match work(Path::new(&item.path), memo) {
        Ok(outcome) => Ok(outcome),
        Err(Failure::Item(e)) => Err(e),
        Err(Failure::Cache(e)) => {
            cache_stopped.store(true, Ordering::Relaxed);
            Err(e)
        }
    });
    match result {
        Ok(outcome) => found_or_none(item.track_id, outcome),
        Err(error) => {
            if error.kind == NativeErrorKind::Panic {
                // The memo may be half-updated: start over.
                *memo = FolderMemo::default();
            }
            failed(item.track_id, error)
        }
    }
}

fn found_or_none(track_id: i64, outcome: CoverOutcome) -> CoverResultDto {
    match outcome {
        CoverOutcome::Found { key, made, colors } => CoverResultDto {
            track_id,
            status: CoverStatusDto::Found,
            thumb_rel: relative_path(&key, CoverSize::Thumb),
            full_rel: relative_path(&key, CoverSize::Full),
            key: Some(key),
            made,
            colors: colors.map(Into::into),
            error: None,
        },
        CoverOutcome::NoCover => CoverResultDto {
            track_id,
            status: CoverStatusDto::NoCover,
            key: None,
            made: false,
            thumb_rel: None,
            full_rel: None,
            colors: None,
            error: None,
        },
    }
}

fn failed(track_id: i64, error: NativeError) -> CoverResultDto {
    CoverResultDto {
        track_id,
        status: CoverStatusDto::Failed,
        key: None,
        made: false,
        thumb_rel: None,
        full_rel: None,
        colors: None,
        error: Some(error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    /// A valid 1x1 PNG.
    const PNG_1X1: [u8; 70] = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44,
        0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F,
        0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x64,
        0x60, 0xF8, 0x5F, 0x0F, 0x00, 0x02, 0x87, 0x01, 0x80, 0xEB, 0x47, 0xBA, 0x92, 0x00, 0x00,
        0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ];

    fn temp_dir(name: &str) -> PathBuf {
        let dir =
            std::env::temp_dir().join(format!("kanaru-covers-api-{}-{name}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).expect("create dir");
        dir
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

    fn request(id: i64, path: &Path) -> CoverRequestDto {
        CoverRequestDto {
            track_id: id,
            path: path.to_string_lossy().into_owned(),
        }
    }

    fn cache_of(dir: &Path) -> String {
        dir.join("cache").to_string_lossy().into_owned()
    }

    #[test]
    fn sidecar_cover_is_made_once_and_found_again() {
        let dir = temp_dir("sidecar");
        write(&dir.join("a.wav"), &tiny_wav());
        write(&dir.join("b.wav"), &tiny_wav());
        write(&dir.join("cover.png"), &PNG_1X1);
        let items = vec![
            request(1, &dir.join("a.wav")),
            request(2, &dir.join("b.wav")),
        ];

        let first = extract_covers_batch(cache_of(&dir), items.clone(), true);
        assert_eq!(first.len(), 2);
        assert_eq!(first[0].track_id, 1);
        assert_eq!(first[1].track_id, 2);
        assert!(
            first.iter().all(|r| r.status == CoverStatusDto::Found),
            "{first:?}"
        );
        assert_eq!(first[0].key, first[1].key);
        // The album shares one decode: only the first track made the files.
        assert!(first[0].made && !first[1].made);
        assert!(first[0].colors.is_some());
        let key = first[0].key.clone().expect("key");
        assert_eq!(
            first[0].thumb_rel.as_deref(),
            Some(format!("covers/thumb/{key}.jpg").as_str())
        );
        assert!(dir
            .join("cache")
            .join(first[0].full_rel.as_deref().expect("full"))
            .is_file());

        let second = extract_covers_batch(cache_of(&dir), items, true);
        assert!(second
            .iter()
            .all(|r| r.status == CoverStatusDto::Found && !r.made));
        assert!(second.iter().all(|r| r.colors.is_none()));

        let colors = cover_colors_for(cache_of(&dir), vec![key.clone(), "../evil".into()]);
        assert_eq!(colors.len(), 2);
        assert!(colors[0]
            .colors
            .as_ref()
            .is_some_and(|c| !c.palette.is_empty()));
        let bad = colors[1].error.as_ref().expect("rejected");
        assert_eq!(bad.kind, NativeErrorKind::Unsupported);
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn sidecars_off_ignores_images_next_to_the_audio() {
        let dir = temp_dir("nosidecar");
        write(&dir.join("a.wav"), &tiny_wav());
        write(&dir.join("cover.png"), &PNG_1X1);
        let out = extract_covers_batch(cache_of(&dir), vec![request(1, &dir.join("a.wav"))], false);
        assert_eq!(out[0].status, CoverStatusDto::NoCover);
        assert!(!dir.join("cache").exists());
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn missing_audio_is_a_permanent_not_found() {
        let dir = temp_dir("missing");
        let out = extract_covers_batch(
            cache_of(&dir),
            vec![request(7, &dir.join("gone.mp3"))],
            true,
        );
        let err = out[0].error.as_ref().expect("error");
        assert_eq!(out[0].status, CoverStatusDto::Failed);
        assert_eq!(err.kind, NativeErrorKind::NotFound);
        assert!(!err.transient);
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn a_fifo_named_cover_is_skipped_without_blocking() {
        let dir = temp_dir("fifo");
        write(&dir.join("a.wav"), &tiny_wav());
        let fifo = dir.join("cover.jpg");
        let made = std::process::Command::new("mkfifo")
            .arg(&fifo)
            .status()
            .is_ok_and(|s| s.success());
        if !made {
            eprintln!("skipped: mkfifo is not available");
            return;
        }
        let out = extract_covers_batch(cache_of(&dir), vec![request(1, &dir.join("a.wav"))], true);
        assert_eq!(out[0].status, CoverStatusDto::NoCover, "{out:?}");
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn a_cache_failure_is_transient_and_stops_the_rest_of_the_batch() {
        let dir = temp_dir("cachefail");
        let items: Vec<_> = (0..4)
            .map(|i| request(i, &dir.join(format!("{i}.mp3"))))
            .collect();
        let out = run_batch(items, |audio, _| {
            let name = audio
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or_default();
            match name {
                "1.mp3" => Err(Failure::Cache(cache_error(&std::io::Error::from(
                    std::io::ErrorKind::PermissionDenied,
                )))),
                _ => Ok(CoverOutcome::NoCover),
            }
        });
        assert_eq!(out[0].status, CoverStatusDto::NoCover);
        for failed in &out[1..] {
            assert_eq!(failed.status, CoverStatusDto::Failed);
            let err = failed.error.as_ref().expect("error");
            assert!(err.transient, "{err:?}");
        }
        assert!(out[1]
            .error
            .as_ref()
            .is_some_and(|e| e.detail.contains("cover cache")));
        std::fs::remove_dir_all(&dir).unwrap();
    }

    /// The Dart scanner matches this literal; both cache failure details must
    /// keep starting with it.
    #[test]
    fn cache_failure_details_start_with_the_prefix_dart_matches() {
        assert_eq!(CACHE_DETAIL_PREFIX, "cover cache");
        let first = cache_error(&std::io::Error::from(std::io::ErrorKind::PermissionDenied));
        assert!(first.detail.starts_with("cover cache"), "{first:?}");
        let dir = temp_dir("cacheprefix");
        let items: Vec<_> = (0..2)
            .map(|i| request(i, &dir.join(format!("{i}.mp3"))))
            .collect();
        let out = run_batch(items, |_, _| {
            Err(Failure::Cache(cache_error(&std::io::Error::from(
                std::io::ErrorKind::PermissionDenied,
            ))))
        });
        for r in &out {
            let err = r.error.as_ref().expect("error");
            assert!(err.detail.starts_with("cover cache"), "{err:?}");
        }
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn a_real_unwritable_cache_is_transient() {
        let dir = temp_dir("unwritable");
        write(&dir.join("a.wav"), &tiny_wav());
        write(&dir.join("cover.png"), &PNG_1X1);
        // The cache folder is a regular file, so nothing can be created in it.
        write(&dir.join("cache"), b"not a folder");
        let out = extract_covers_batch(cache_of(&dir), vec![request(1, &dir.join("a.wav"))], true);
        assert_eq!(out[0].status, CoverStatusDto::Failed);
        assert!(out[0].error.as_ref().is_some_and(|e| e.transient));
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn a_panic_is_reported_for_that_item_only() {
        let items = vec![
            request(1, Path::new("/m/a/1.mp3")),
            request(2, Path::new("/m/a/boom.mp3")),
            request(3, Path::new("/m/b/3.mp3")),
        ];
        let out = run_batch(items, |audio, _| {
            if audio.ends_with("boom.mp3") {
                panic!("decoder exploded");
            }
            Ok(CoverOutcome::NoCover)
        });
        assert_eq!(out[0].status, CoverStatusDto::NoCover);
        assert_eq!(out[2].status, CoverStatusDto::NoCover);
        let err = out[1].error.as_ref().expect("panic error");
        assert_eq!(err.kind, NativeErrorKind::Panic);
        assert!(!err.transient);
        assert_eq!(
            out.iter().map(|r| r.track_id).collect::<Vec<_>>(),
            [1, 2, 3]
        );
    }

    #[test]
    fn results_keep_the_order_of_the_items_across_folders() {
        let items: Vec<_> = (0..300)
            .map(|i| request(i, Path::new(&format!("/m/{}/{i}.mp3", i % 7))))
            .collect();
        let out = run_batch(items, |_, _| Ok(CoverOutcome::NoCover));
        assert_eq!(out.len(), 300);
        assert!(out.iter().enumerate().all(|(i, r)| r.track_id == i as i64));
    }

    #[test]
    fn a_relative_cache_dir_is_rejected_for_every_item() {
        let items = vec![
            request(1, Path::new("/m/a.mp3")),
            request(2, Path::new("/m/b.mp3")),
        ];
        let out = extract_covers_batch("covers-cache".into(), items, true);
        assert_eq!(out.len(), 2);
        for r in &out {
            assert_eq!(r.status, CoverStatusDto::Failed);
            let err = r.error.as_ref().expect("error");
            assert_eq!(err.kind, NativeErrorKind::Unsupported);
            assert!(!err.transient);
        }
        let colors = cover_colors_for(
            String::new(),
            vec!["ab/0123456789abcdef0123456789abcdef".into()],
        );
        assert_eq!(
            colors[0].error.as_ref().map(|e| e.kind.clone()),
            Some(NativeErrorKind::Unsupported)
        );
    }

    #[test]
    fn a_retry_from_a_sidecar_is_transient_for_that_item_only() {
        let items = vec![
            request(1, Path::new("/m/a.mp3")),
            request(2, Path::new("/m/b.mp3")),
        ];
        let out = run_batch(items, |audio, _| {
            if audio.ends_with("a.mp3") {
                Err(Failure::Item(NativeError::new(
                    NativeErrorKind::Io,
                    "EIO",
                    true,
                )))
            } else {
                Ok(CoverOutcome::NoCover)
            }
        });
        assert!(out[0].error.as_ref().is_some_and(|e| e.transient));
        assert_eq!(out[1].status, CoverStatusDto::NoCover);
    }

    #[test]
    fn empty_inputs_give_empty_results() {
        assert!(extract_covers_batch("/tmp/none".into(), Vec::new(), true).is_empty());
        assert!(cover_colors_for("/tmp/none".into(), Vec::new()).is_empty());
    }
}
