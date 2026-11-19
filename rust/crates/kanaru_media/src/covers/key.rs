//! Cache keys and relative paths of cover files. The format is the one Dart
//! checks with `isCoverKey` and builds with `coverRelativePath`.

use super::crop::CropRect;

/// The two sizes written for every cover.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CoverSize {
    /// Longest side at most 256 px: list tiles.
    Thumb,
    /// Longest side at most 1024 px: Now Playing, media session art.
    Full,
}

impl CoverSize {
    fn dir(self) -> &'static str {
        match self {
            CoverSize::Thumb => "thumb",
            CoverSize::Full => "full",
        }
    }
}

/// `<2 hex>/<32 hex>`: the first 16 bytes of the blake3 hash of the original
/// image bytes as 32 lowercase hex digits, behind a shard folder named after
/// their first two digits.
pub fn cover_key(original: &[u8]) -> String {
    let hash = blake3::hash(original).to_hex();
    let name = &hash.as_str()[..32];
    format!("{}/{}", &name[..2], name)
}

/// The key of a cover cut out of `original`: [`cover_key`] when `crop` is
/// `None`, otherwise the same hash taken over the bytes, `b"crop:"` and the
/// crop's `left`, `top` and `side` as little-endian `u32`. The same image with
/// the same crop always gets the same key. `crop` must be normalised (see
/// `crop::normalise`): a crop of a whole square picture is `None`.
pub fn cover_key_for(original: &[u8], crop: Option<CropRect>) -> String {
    let Some(crop) = crop else {
        return cover_key(original);
    };
    let mut hasher = blake3::Hasher::new();
    hasher.update(original);
    hasher.update(b"crop:");
    for part in [crop.left, crop.top, crop.side] {
        hasher.update(&part.to_le_bytes());
    }
    let hash = hasher.finalize().to_hex();
    let name = &hash.as_str()[..32];
    format!("{}/{}", &name[..2], name)
}

/// Whether `key` matches `^[0-9a-f]{2}/[0-9a-f]{32}$`. Nothing else may be
/// used to build a path: it could point outside the cover folder.
pub fn is_cover_key(key: &str) -> bool {
    let Some((shard, name)) = key.split_once('/') else {
        return false;
    };
    let lower_hex = |s: &str| s.bytes().all(|b| matches!(b, b'0'..=b'9' | b'a'..=b'f'));
    shard.len() == 2 && name.len() == 32 && lower_hex(shard) && lower_hex(name)
}

/// `covers/{thumb,full}/<key>.jpg`, relative to the cache folder (the same
/// string as Dart's `coverRelativePath`). `None` for a malformed key.
pub fn relative_path(key: &str, size: CoverSize) -> Option<String> {
    is_cover_key(key).then(|| format!("covers/{}/{key}.jpg", size.dir()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn key_has_the_dart_shape() {
        let key = cover_key(b"some image bytes");
        assert!(is_cover_key(&key), "{key}");
        assert_eq!(key.len(), 35);
        let (shard, name) = key.split_once('/').expect("shard");
        assert!(name.starts_with(shard));
    }

    #[test]
    fn key_is_the_first_16_bytes_of_blake3() {
        let key = cover_key(b"abc");
        let full = blake3::hash(b"abc").to_hex();
        assert_eq!(
            key,
            format!("{}/{}", &full.as_str()[..2], &full.as_str()[..32])
        );
    }

    #[test]
    fn a_crop_changes_the_key_and_is_deterministic() {
        let crop = |left, top, side| Some(CropRect { left, top, side });
        assert_eq!(cover_key_for(b"img", None), cover_key(b"img"));
        let key = cover_key_for(b"img", crop(1, 2, 3));
        assert!(is_cover_key(&key), "{key}");
        assert_eq!(key, cover_key_for(b"img", crop(1, 2, 3)));
        assert_ne!(key, cover_key(b"img"));
        for other in [crop(2, 1, 3), crop(1, 2, 4), crop(0, 2, 3)] {
            assert_ne!(key, cover_key_for(b"img", other));
        }
        assert_ne!(key, cover_key_for(b"imh", crop(1, 2, 3)));
        let mut hasher = blake3::Hasher::new();
        hasher.update(b"img");
        hasher.update(b"crop:");
        hasher.update(&[1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0]);
        let hash = hasher.finalize().to_hex();
        assert!(key.ends_with(&hash.as_str()[..32]));
    }

    #[test]
    fn key_is_stable_and_content_addressed() {
        assert_eq!(cover_key(b"a"), cover_key(b"a"));
        assert_ne!(cover_key(b"a"), cover_key(b"b"));
    }

    #[test]
    fn relative_paths_match_dart() {
        let key = "ab/0123456789abcdef0123456789abcdef";
        assert_eq!(
            relative_path(key, CoverSize::Thumb).as_deref(),
            Some("covers/thumb/ab/0123456789abcdef0123456789abcdef.jpg")
        );
        assert_eq!(
            relative_path(key, CoverSize::Full).as_deref(),
            Some("covers/full/ab/0123456789abcdef0123456789abcdef.jpg")
        );
    }

    #[test]
    fn malformed_keys_are_rejected() {
        for bad in [
            "",
            "ab",
            "ab/",
            "../etc/passwd",
            "AB/0123456789abcdef0123456789abcdef",
            "ab/0123456789ABCDEF0123456789abcdef",
            "ab/0123456789abcdef0123456789abcde",
            "ab/0123456789abcdef0123456789abcdef0",
            "abc/0123456789abcdef0123456789abcdef",
            "ab/0123456789abcdef0123456789abcdef/x",
            "ab/0123456789abcdef0123456789abcdeg",
            "ab/0123456789abcdef0123456789abcdef.jpg",
        ] {
            assert!(!is_cover_key(bad), "{bad}");
            assert_eq!(relative_path(bad, CoverSize::Thumb), None);
        }
    }
}
