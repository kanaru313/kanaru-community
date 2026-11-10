//! The cover files on disk: `<cache>/covers/{thumb,full}/<key>.jpg`.
//!
//! Every failure here is a failure of the cache folder (full disk, read-only
//! storage, a missing parent) and says nothing about the cover, so callers
//! report it as transient. The layout marker `.layout-v1` is not written
//! here: Dart owns it.

use std::fs::{self, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use super::key::{relative_path, CoverSize};

/// Prefix of a file being written (Dart's `coverTempPrefix`). A leftover from
/// a crash is never read: files are found by their exact final name.
pub const TEMP_PREFIX: &str = ".kanaru-tmp-";

fn path_of(cache_dir: &Path, key: &str, size: CoverSize) -> io::Result<PathBuf> {
    relative_path(key, size)
        .map(|relative| cache_dir.join(relative))
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "not a cover key"))
}

/// Whether both sizes of `key` exist and are not empty (a zero-byte file is
/// what a crash leaves behind).
pub fn both_exist(cache_dir: &Path, key: &str) -> bool {
    [CoverSize::Thumb, CoverSize::Full].into_iter().all(|size| {
        path_of(cache_dir, key, size)
            .ok()
            .and_then(|p| fs::metadata(p).ok())
            .is_some_and(|m| m.is_file() && m.len() > 0)
    })
}

/// Writes both sizes of `key`, creating the shard folders. `full` goes first,
/// so a `thumb` on disk implies its `full` was written before it.
pub fn write_both(cache_dir: &Path, key: &str, thumb: &[u8], full: &[u8]) -> io::Result<()> {
    write_atomic(&path_of(cache_dir, key, CoverSize::Full)?, full)?;
    write_atomic(&path_of(cache_dir, key, CoverSize::Thumb)?, thumb)
}

/// Writes through a temp file in the destination's own folder, then renames,
/// so a reader never sees a half-written file. The temp file is removed on
/// error.
fn write_atomic(dest: &Path, data: &[u8]) -> io::Result<()> {
    let shard = dest
        .parent()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "no folder"))?;
    fs::create_dir_all(shard)?;
    let temp = shard.join(temp_name());
    let result = (|| {
        let mut file = OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&temp)?;
        file.write_all(data)?;
        file.flush()?;
        drop(file);
        fs::rename(&temp, dest)
    })();
    if result.is_err() {
        let _ = fs::remove_file(&temp);
    }
    result
}

/// `.kanaru-tmp-<hex>`: unique per process, call and moment.
fn temp_name() -> String {
    static NEXT: AtomicU64 = AtomicU64::new(0);
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |d| d.as_nanos());
    let n = NEXT.fetch_add(1, Ordering::Relaxed);
    format!("{TEMP_PREFIX}{:x}-{:x}-{nanos:x}", std::process::id(), n)
}

#[cfg(test)]
mod tests {
    use super::*;

    const KEY: &str = "ab/0123456789abcdef0123456789abcdef";

    fn temp_dir(name: &str) -> PathBuf {
        let dir =
            std::env::temp_dir().join(format!("kanaru-cover-cache-{}-{name}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).expect("create dir");
        dir
    }

    fn file_of(dir: &Path, size: &str) -> PathBuf {
        dir.join(format!("covers/{size}/{KEY}.jpg"))
    }

    #[test]
    fn creates_shard_folders_and_writes_both_files() {
        let dir = temp_dir("write");
        assert!(!both_exist(&dir, KEY));
        write_both(&dir, KEY, b"thumb", b"full").expect("write");
        assert!(both_exist(&dir, KEY));
        assert_eq!(fs::read(file_of(&dir, "thumb")).unwrap(), b"thumb");
        assert_eq!(fs::read(file_of(&dir, "full")).unwrap(), b"full");
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn leaves_no_temp_files_and_ignores_stale_ones() {
        let dir = temp_dir("temp");
        let shard = dir.join("covers/thumb/ab");
        fs::create_dir_all(&shard).unwrap();
        fs::write(shard.join(".kanaru-tmp-stale"), b"half").unwrap();
        assert!(!both_exist(&dir, KEY));
        write_both(&dir, KEY, b"t", b"f").expect("write");
        let temps: Vec<_> = ["thumb", "full"]
            .iter()
            .flat_map(|s| fs::read_dir(dir.join(format!("covers/{s}/ab"))).unwrap())
            .map(|e| e.unwrap().file_name().to_string_lossy().into_owned())
            .filter(|n| n.starts_with(TEMP_PREFIX))
            .collect();
        assert_eq!(temps, [".kanaru-tmp-stale"]);
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn one_missing_or_empty_file_is_not_both() {
        let dir = temp_dir("partial");
        write_both(&dir, KEY, b"t", b"f").unwrap();
        fs::write(file_of(&dir, "full"), b"").unwrap();
        assert!(!both_exist(&dir, KEY));
        fs::remove_file(file_of(&dir, "full")).unwrap();
        assert!(!both_exist(&dir, KEY));
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn overwriting_replaces_the_file() {
        let dir = temp_dir("overwrite");
        write_both(&dir, KEY, b"old", b"old").unwrap();
        write_both(&dir, KEY, b"new", b"new").unwrap();
        assert_eq!(fs::read(file_of(&dir, "thumb")).unwrap(), b"new");
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn a_cache_dir_that_is_a_file_fails_without_partial_files() {
        let dir = temp_dir("notadir");
        let blocker = dir.join("cache");
        fs::write(&blocker, b"i am a file").unwrap();
        assert!(write_both(&blocker, KEY, b"t", b"f").is_err());
        assert!(!both_exist(&blocker, KEY));
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn a_bad_key_never_builds_a_path() {
        let dir = temp_dir("badkey");
        assert!(write_both(&dir, "../evil", b"t", b"f").is_err());
        assert!(!both_exist(&dir, "../evil"));
        assert_eq!(fs::read_dir(&dir).unwrap().count(), 0);
        fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn temp_names_are_unique() {
        assert_ne!(temp_name(), temp_name());
    }
}
