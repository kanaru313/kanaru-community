//! The picture a cover-crop dialog shows: the chosen image decoded once in
//! Rust, turned upright and shrunk, so the dialog pans and crops in the same
//! orientation the import uses and never depends on the engine's EXIF
//! handling or on decoding the original again.

use std::fs::{self, File, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

use super::cache::{temp_name, TEMP_PREFIX};
use super::crop::upright_size;
use super::{sources, thumbnail, CoverError};
use crate::{Cancel, MediaError};

/// Start of the name of every preview file: the cover temp prefix, so the
/// sweep that removes leftovers of a crash (names starting with
/// [`TEMP_PREFIX`]) removes these too.
pub const PREVIEW_PREFIX: &str = ".kanaru-tmp-preview-";

/// A preview file and the upright size of the original.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoverPreview {
    /// `<out_dir>/.kanaru-tmp-preview-<unique>.jpg`, long side at most 1024.
    pub path: PathBuf,
    /// Upright size of the original image, not of the preview.
    pub width: u32,
    pub height: u32,
}

/// Reads the whole image at `path` (same size limit, format sniffing and
/// decode limits as `import_cover`), and writes its upright preview JPEG into
/// `out_dir` (created when missing). The caller owns the file and deletes it.
///
/// Errors as `import_cover`: `Source` for the file (`TooLarge`, `Unsupported`,
/// `Corrupt`, open failures), `Retry` for a read failure after open, `Cache`
/// for a write failure under `out_dir`.
pub fn prepare_preview(
    path: &Path,
    open: &dyn Fn(&Path) -> Result<File, MediaError>,
    out_dir: &Path,
    cancel: &Cancel,
) -> Result<CoverPreview, CoverError> {
    cancel.check()?;
    let bytes = sources::read_image_file(path, open)?;
    cancel.check()?;
    let header = sources::check_header(&bytes)?;
    let orientation = thumbnail::exif_orientation(&bytes, header.format);
    let (width, height) = upright_size(orientation, header.width, header.height);
    let Some(jpeg) = thumbnail::make_preview_jpeg(&bytes, header) else {
        return Err(MediaError::Corrupt("image does not decode".into()).into());
    };
    cancel.check()?;
    let path = write_unique(out_dir, &jpeg).map_err(CoverError::Cache)?;
    Ok(CoverPreview {
        path,
        width,
        height,
    })
}

/// Writes `data` to a new file under `dir`; a failed write leaves no file.
fn write_unique(dir: &Path, data: &[u8]) -> std::io::Result<PathBuf> {
    fs::create_dir_all(dir)?;
    let suffix = &temp_name()[TEMP_PREFIX.len()..];
    let path = dir.join(format!("{PREVIEW_PREFIX}{suffix}.jpg"));
    // `create_new` fails if the name exists: only a file made here is removed.
    let mut file = OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&path)?;
    // No fsync: the file is a throwaway that the caller deletes.
    if let Err(e) = file.write_all(data) {
        drop(file);
        let _ = fs::remove_file(&path);
        return Err(e);
    }
    Ok(path)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_prefix_extends_the_cover_temp_prefix() {
        assert!(PREVIEW_PREFIX.starts_with(TEMP_PREFIX));
    }

    #[test]
    fn unique_files_do_not_collide_and_failures_leave_nothing() {
        let dir = std::env::temp_dir().join(format!("kanaru-preview-{}", std::process::id()));
        let a = write_unique(&dir, b"a").unwrap();
        let b = write_unique(&dir, b"b").unwrap();
        assert_ne!(a, b);
        assert!(a
            .file_name()
            .unwrap()
            .to_string_lossy()
            .starts_with(PREVIEW_PREFIX));
        // A folder that is a file cannot be created.
        assert!(write_unique(&a, b"c").is_err());
        fs::remove_dir_all(&dir).unwrap();
    }
}
