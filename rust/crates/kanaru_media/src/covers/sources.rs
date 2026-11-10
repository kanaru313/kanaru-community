//! Where the cover of one audio file can come from, in order: pictures
//! embedded in the tags (front covers first), then an image next to the file
//! named after it (`<stem>.jpg|jpeg|png`), then `cover`, `folder`, `front`
//! with the same extensions. Names match without regard to case. A source
//! that fails a check is skipped and the next one is tried.

use std::collections::HashMap;
use std::ffi::OsString;
use std::fs::File;
use std::io::{self, Cursor, Read};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::{Path, PathBuf};

use image::{ImageFormat, ImageReader};
use lofty::file::{TaggedFile, TaggedFileExt};
use lofty::picture::PictureType;
use lofty::tag::TagExt;

use super::CoverError;
use crate::limits::{MAX_COVER_BYTES, MAX_COVER_PIXELS};
use crate::tags::{extension_rule, probe, ExtensionRule};
use crate::{Cancel, MediaError};

const SIDECAR_EXTENSIONS: [&str; 3] = ["jpg", "jpeg", "png"];
const FOLDER_NAMES: [&str; 3] = ["cover", "folder", "front"];

/// Lowercased file name to real file name, for the image files in one folder.
pub type ImageListing = HashMap<String, OsString>;

/// Format and size of an image that passed [`validate_header`].
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ImageHeader {
    pub format: ImageFormat,
    pub width: u32,
    pub height: u32,
}

impl ImageHeader {
    pub fn pixels(&self) -> u64 {
        u64::from(self.width) * u64::from(self.height)
    }
}

/// The header of `bytes` when it is a JPEG, PNG or WebP of at most
/// `MAX_COVER_BYTES` whose header declares a size of at most
/// `MAX_COVER_PIXELS`. Nothing is decoded and no pixel buffer is allocated.
/// Other formats (GIF, BMP, TIFF, AVIF, HEIC, URL pictures) are rejected: the
/// MIME type in a tag is often wrong, so only the content counts. A header the
/// parser panics on counts as invalid.
pub fn validate_header(bytes: &[u8]) -> Option<ImageHeader> {
    if bytes.len() as u64 > MAX_COVER_BYTES {
        return None;
    }
    let format = match bytes {
        [0xFF, 0xD8, 0xFF, ..] => ImageFormat::Jpeg,
        [0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A, ..] => ImageFormat::Png,
        [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'E', b'B', b'P', ..] => ImageFormat::WebP,
        _ => return None,
    };
    let (width, height) = catch_unwind(AssertUnwindSafe(|| {
        ImageReader::with_format(Cursor::new(bytes), format).into_dimensions()
    }))
    .ok()?
    .ok()?;
    let header = ImageHeader {
        format,
        width,
        height,
    };
    (width > 0 && height > 0 && header.pixels() <= MAX_COVER_PIXELS).then_some(header)
}

/// The embedded pictures of `path`, best first. Empty for a format that
/// carries none (DSD). Errors are about the audio file itself.
pub fn embedded_pictures(
    path: &Path,
    open: &dyn Fn(&Path) -> Result<File, MediaError>,
    cancel: &Cancel,
) -> Result<Vec<Vec<u8>>, MediaError> {
    match extension_rule(path) {
        ExtensionRule::Unsupported => return Err(MediaError::Unsupported),
        ExtensionRule::NoTags => {
            open(path)?;
            return Ok(Vec::new());
        }
        ExtensionRule::Normal => {}
    }
    let file = open(path)?;
    cancel.check()?;
    // A parser panic is this file's problem: report it like any damaged file,
    // so the sidecars are still tried.
    catch_unwind(AssertUnwindSafe(|| {
        probe(file, path, true).map(take_embedded_pictures)
    }))
    .unwrap_or_else(|_| Err(MediaError::Corrupt("tag parser panicked".into())))
}

/// Takes every embedded picture out of `tagged`, without copying the bytes.
/// Order: the primary tag, then the others; within that, front covers first,
/// then the rest in file order (MP4 `covr` is always `Other`).
fn take_embedded_pictures(mut tagged: TaggedFile) -> Vec<Vec<u8>> {
    let primary = tagged.primary_tag_type();
    let mut tag_types: Vec<_> = tagged.tags().iter().map(TagExt::tag_type).collect();
    tag_types.sort_by_key(|tag_type| *tag_type != primary);

    let mut front = Vec::new();
    let mut rest = Vec::new();
    for tag_type in tag_types {
        let Some(mut tag) = tagged.remove(tag_type) else {
            continue;
        };
        while !tag.pictures().is_empty() {
            let picture = tag.remove_picture(0);
            if picture.pic_type() == PictureType::CoverFront {
                front.push(picture.into_data());
            } else {
                rest.push(picture.into_data());
            }
        }
    }
    front.extend(rest);
    front
}

/// Lists the JPEG/PNG files in `dir`.
fn list_images(dir: &Path) -> io::Result<ImageListing> {
    let entries = std::fs::read_dir(dir)?;
    Ok(entries
        .filter_map(Result::ok)
        .filter_map(|entry| {
            let name = entry.file_name();
            let lower = name.to_string_lossy().to_lowercase();
            let extension = Path::new(&lower).extension()?.to_str()?;
            SIDECAR_EXTENSIONS
                .contains(&extension)
                .then(|| (lower.clone(), name))
        })
        .collect())
}

/// Sidecar images for `audio`, best first, from the listing of its folder.
pub fn sidecar_candidates(audio: &Path, listing: &ImageListing) -> Vec<PathBuf> {
    let Some(dir) = audio.parent() else {
        return Vec::new();
    };
    let stem = audio
        .file_stem()
        .map(|s| s.to_string_lossy().to_lowercase());
    stem.into_iter()
        .chain(FOLDER_NAMES.iter().map(|name| (*name).to_owned()))
        .flat_map(|base| SIDECAR_EXTENSIONS.map(|ext| format!("{base}.{ext}")))
        .filter_map(|wanted| listing.get(&wanted).map(|real| dir.join(real)))
        .collect()
}

/// Reads a sidecar image of at most `MAX_COVER_BYTES` through `open`.
///
/// `Ok(None)`: no usable image (gone, not a regular file, too large, or
/// refused for good at open, e.g. permissions). `Err(Retry)`: the file opened
/// (or failed transiently) but could not be read; a sidecar has no change
/// trigger, so storing "no cover" for that would be permanent.
pub fn read_sidecar(
    path: &Path,
    open: &dyn Fn(&Path) -> Result<File, MediaError>,
) -> Result<Option<Vec<u8>>, CoverError> {
    let file = match open(path) {
        Ok(file) => file,
        Err(e) if e.is_transient() => return Err(retry(path, &e)),
        Err(_) => return Ok(None),
    };
    let meta = file.metadata().map_err(|e| retry(path, &e))?;
    if !meta.is_file() || meta.len() > MAX_COVER_BYTES {
        return Ok(None);
    }
    // The cap still holds for a file that grows while it is read.
    let mut bytes = Vec::new();
    file.take(MAX_COVER_BYTES + 1)
        .read_to_end(&mut bytes)
        .map_err(|e| retry(path, &e))?;
    Ok((bytes.len() as u64 <= MAX_COVER_BYTES).then_some(bytes))
}

fn retry(path: &Path, e: &dyn std::fmt::Display) -> CoverError {
    CoverError::Retry(format!("{}: {e}", path.display()))
}

/// What one worker chunk has learned, so tracks of one album share the folder
/// listing and the decode of their `cover.jpg`. Per chunk, never shared
/// between threads: nothing blocks on another worker's claim.
#[derive(Default)]
pub struct FolderMemo {
    listings: HashMap<PathBuf, ImageListing>,
    /// Sidecar file to the key stored for it, `None` when it was unusable.
    sidecars: HashMap<PathBuf, Option<String>>,
}

impl FolderMemo {
    /// The image listing of `dir`. A folder that is gone, refused or not a
    /// folder lists as empty; any other failure is a `Retry` and not
    /// remembered.
    pub fn listing(&mut self, dir: &Path) -> Result<&ImageListing, CoverError> {
        self.listing_with(dir, list_images)
    }

    fn listing_with(
        &mut self,
        dir: &Path,
        list: impl FnOnce(&Path) -> io::Result<ImageListing>,
    ) -> Result<&ImageListing, CoverError> {
        if !self.listings.contains_key(dir) {
            let listing = match list(dir) {
                Ok(listing) => listing,
                Err(e) => classify_listing_error(dir, &e)?,
            };
            self.listings.insert(dir.to_owned(), listing);
        }
        Ok(&self.listings[dir])
    }

    pub fn known_sidecar(&self, path: &Path) -> Option<&Option<String>> {
        self.sidecars.get(path)
    }

    pub fn remember_sidecar(&mut self, path: &Path, key: Option<String>) {
        self.sidecars.insert(path.to_owned(), key);
    }
}

/// A folder that is gone, refused or not a folder has no sidecars; any other
/// failure (EIO on a dropped mount, ...) is retried later.
fn classify_listing_error(dir: &Path, e: &io::Error) -> Result<ImageListing, CoverError> {
    match e.kind() {
        io::ErrorKind::NotFound
        | io::ErrorKind::PermissionDenied
        | io::ErrorKind::NotADirectory => Ok(ImageListing::new()),
        _ => Err(retry(dir, e)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn listing(names: &[&str]) -> ImageListing {
        names
            .iter()
            .map(|n| (n.to_lowercase(), OsString::from(n)))
            .collect()
    }

    #[test]
    fn candidates_follow_the_documented_order() {
        let l = listing(&[
            "Front.PNG",
            "folder.jpg",
            "Song.JPEG",
            "cover.png",
            "song.png",
        ]);
        let got = sidecar_candidates(Path::new("/m/a/Song.flac"), &l);
        let names: Vec<_> = got
            .iter()
            .map(|p| p.file_name().unwrap().to_string_lossy().into_owned())
            .collect();
        assert_eq!(
            names,
            [
                "Song.JPEG",
                "song.png",
                "cover.png",
                "folder.jpg",
                "Front.PNG"
            ]
        );
        assert!(got.iter().all(|p| p.parent() == Some(Path::new("/m/a"))));
    }

    #[test]
    fn no_listing_no_candidates() {
        assert!(sidecar_candidates(Path::new("/m/a/x.mp3"), &ImageListing::new()).is_empty());
        assert!(sidecar_candidates(Path::new("x.mp3"), &listing(&["cover.jpg"])).len() <= 1);
    }

    fn png(width: u32, height: u32) -> Vec<u8> {
        let image = image::DynamicImage::ImageRgb8(image::ImageBuffer::new(width, height));
        let mut out = Cursor::new(Vec::new());
        image.write_to(&mut out, ImageFormat::Png).unwrap();
        out.into_inner()
    }

    #[test]
    fn header_accepts_small_png_and_reports_size() {
        let header = validate_header(&png(30, 20)).expect("png");
        assert_eq!(header.format, ImageFormat::Png);
        assert_eq!((header.width, header.height), (30, 20));
        assert_eq!(header.pixels(), 600);
    }

    /// CRC-32 (PNG chunks), bitwise.
    fn crc32(data: &[u8]) -> u32 {
        let mut crc = 0xFFFF_FFFFu32;
        for &byte in data {
            crc ^= u32::from(byte);
            for _ in 0..8 {
                crc = if crc & 1 == 1 {
                    (crc >> 1) ^ 0xEDB8_8320
                } else {
                    crc >> 1
                };
            }
        }
        !crc
    }

    /// A PNG whose header declares `width` x `height`, with no pixel data
    /// behind it, and a valid header checksum.
    fn png_header_only(width: u32, height: u32) -> Vec<u8> {
        let mut bytes = png(1, 1);
        bytes[16..20].copy_from_slice(&width.to_be_bytes());
        bytes[20..24].copy_from_slice(&height.to_be_bytes());
        let crc = crc32(&bytes[12..29]);
        bytes[29..33].copy_from_slice(&crc.to_be_bytes());
        bytes
    }

    #[test]
    fn header_rejects_more_than_the_pixel_cap_without_decoding() {
        // 36 MP is within the cap, 49 MP is not.
        let ok = validate_header(&png_header_only(6000, 6000)).expect("36 MP");
        assert_eq!(ok.pixels(), 36_000_000);
        assert_eq!(validate_header(&png_header_only(7000, 7000)), None);
        assert_eq!(validate_header(&png_header_only(0, 10)), None);
    }

    #[test]
    fn header_rejects_other_formats_garbage_and_empty() {
        assert_eq!(validate_header(b""), None);
        assert_eq!(validate_header(b"GIF89a......"), None);
        assert_eq!(validate_header(&[0xFF, 0xD8, 0xFF]), None);
        assert_eq!(validate_header(&[0x89, b'P', b'N', b'G']), None);
        assert_eq!(validate_header(&[7u8; 4096]), None);
    }

    #[test]
    fn header_rejects_a_cover_over_the_byte_cap() {
        let mut bytes = png(2, 2);
        bytes.resize(MAX_COVER_BYTES as usize + 1, 0);
        assert_eq!(validate_header(&bytes), None);
    }

    #[test]
    fn header_survives_hostile_bytes() {
        let base = png(64, 64);
        let mut state = 0x9E37_79B9_7F4A_7C15u64;
        let mut next = move || {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            state
        };
        for _ in 0..500 {
            let mut bytes = base.clone();
            for _ in 0..4 {
                let at = (next() % 64) as usize;
                bytes[at] = next() as u8;
            }
            let cut = (next() % bytes.len() as u64) as usize;
            bytes.truncate(cut.max(2));
            let _ = validate_header(&bytes);
        }
    }

    #[test]
    fn sidecar_open_failures_skip_or_retry() {
        let gone = |_: &Path| Err(MediaError::Io(io::ErrorKind::NotFound));
        assert!(matches!(
            read_sidecar(Path::new("/x/cover.jpg"), &gone),
            Ok(None)
        ));
        let refused = |_: &Path| Err(MediaError::Unsupported);
        assert!(matches!(
            read_sidecar(Path::new("/x/cover.jpg"), &refused),
            Ok(None)
        ));
        let busy = |_: &Path| Err(MediaError::Io(io::ErrorKind::TimedOut));
        assert!(matches!(
            read_sidecar(Path::new("/x/cover.jpg"), &busy),
            Err(CoverError::Retry(_))
        ));
    }

    #[test]
    fn a_directory_is_skipped_and_an_io_error_maps_to_retry() {
        let dir = std::env::temp_dir();
        let open_dir = |p: &Path| File::open(p).map_err(MediaError::from);
        // A directory is not a regular file: skipped, not retried.
        assert!(matches!(read_sidecar(&dir, &open_dir), Ok(None)));
        let err = io::Error::from(io::ErrorKind::Other);
        assert!(matches!(retry(Path::new("/x"), &err), CoverError::Retry(_)));
    }

    #[test]
    fn oversized_sidecars_are_skipped_by_size_without_reading() {
        let path = std::env::temp_dir().join(format!("kanaru-sidecar-big-{}", std::process::id()));
        let file = File::create(&path).expect("create");
        file.set_len(MAX_COVER_BYTES + 1).expect("sparse");
        drop(file);
        let open = |p: &Path| File::open(p).map_err(MediaError::from);
        let result = read_sidecar(&path, &open);
        std::fs::remove_file(&path).expect("remove");
        assert!(matches!(result, Ok(None)));
    }

    #[test]
    fn listing_errors_are_classified() {
        let dir = Path::new("/m/a");
        for kind in [
            io::ErrorKind::NotFound,
            io::ErrorKind::PermissionDenied,
            io::ErrorKind::NotADirectory,
        ] {
            let mut memo = FolderMemo::default();
            let listing = memo.listing_with(dir, |_| Err(io::Error::from(kind)));
            assert!(listing.expect("empty").is_empty(), "{kind:?}");
            assert!(memo.listings.contains_key(dir));
        }
        for kind in [
            io::ErrorKind::Other,
            io::ErrorKind::TimedOut,
            io::ErrorKind::InvalidData,
        ] {
            let mut memo = FolderMemo::default();
            let listing = memo.listing_with(dir, |_| Err(io::Error::from(kind)));
            assert!(matches!(listing, Err(CoverError::Retry(_))), "{kind:?}");
            assert!(!memo.listings.contains_key(dir), "not remembered");
        }
    }

    #[test]
    fn a_folder_that_is_gone_lists_as_empty_and_is_remembered() {
        let mut memo = FolderMemo::default();
        let dir = Path::new("/nonexistent/kanaru/folder");
        assert!(memo.listing(dir).expect("empty").is_empty());
        assert!(memo.listings.contains_key(dir));
    }
}
