//! The colours of a cover, taken from its `thumb` JPEG: a seed colour and a
//! small palette for gradients and tints. Both come from the encoded `thumb`
//! (also right after it was made), so a cover gets the same colours however
//! they are asked for.
//!
//! A `thumb` on disk is not trusted: it may be damaged, stale or written by
//! another tool. It is read with a byte cap, its header must declare at most
//! [`THUMB_SIDE`] per side, and it is decoded with the same limits as any cover.

use std::fs::File;
use std::io::{Cursor, Read};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::Path;

use image::{imageops, ImageFormat, ImageReader};
use material_colors::color::{Argb, Lab};
use material_colors::hct::Hct;
use material_colors::quantize::{Quantizer, QuantizerMap, QuantizerResult, QuantizerWu};
use material_colors::score::Score;

use super::decode_limits::decode_limits;
use super::jpeg_header;
use super::key::{relative_path, CoverSize};
use super::thumbnail::THUMB_SIDE;
use crate::MediaError;

/// The thumb is shrunk to at most this many pixels per side before the colours
/// are counted, as Flutter's `ColorScheme.fromImageProvider` does; more pixels
/// only cost time.
const MAX_SAMPLE_SIDE: u32 = 112;

/// Clusters the seed is picked from (as in Flutter and Android).
const SEED_CLUSTERS: usize = 128;

/// Colours in the palette, at most.
pub const PALETTE_SIZE: usize = 5;

/// A seed whose HCT chroma is below this is gray: its hue is noise, so the
/// cover has no colours (no row is stored and consumers use the app theme).
pub const MIN_SEED_CHROMA: f64 = 5.0;

/// A thumb file larger than this is not read. Real thumbs are well under
/// 100 KiB.
const MAX_THUMB_BYTES: u64 = 1024 * 1024;

/// The colours of one image.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CoverColors {
    /// Opaque ARGB seed: Flutter's scoring pick, or the most common colour
    /// when no cluster scores. Its HCT chroma is at least [`MIN_SEED_CHROMA`].
    pub seed: u32,
    /// Opaque ARGB colours, the most common first; one to [`PALETTE_SIZE`].
    pub palette: Vec<u32>,
}

/// The colours of the cached `thumb` of `key` under `cache_dir`, read through
/// `open`. `Unsupported` for a malformed key (a path is never built from it),
/// `TooLarge`/`Corrupt` for a file that cannot be a thumb; `Ok(None)` for a gray
/// cover (see [`MIN_SEED_CHROMA`]); I/O errors keep
/// their kind (a missing file is `Io(NotFound)`).
pub fn colors_of_cached_thumb(
    cache_dir: &Path,
    key: &str,
    open: &dyn Fn(&Path) -> Result<File, MediaError>,
) -> Result<Option<CoverColors>, MediaError> {
    let relative = relative_path(key, CoverSize::Thumb).ok_or(MediaError::Unsupported)?;
    let file = open(&cache_dir.join(relative))?;
    let mut bytes = Vec::new();
    file.take(MAX_THUMB_BYTES + 1).read_to_end(&mut bytes)?;
    if bytes.len() as u64 > MAX_THUMB_BYTES {
        return Err(MediaError::TooLarge);
    }
    catch_unwind(AssertUnwindSafe(|| {
        thumb_pixels(&bytes).map(|p| colors_of_pixels(&p))
    }))
    .ok()
    .flatten()
    .ok_or_else(|| MediaError::Corrupt("cover thumb does not decode".into()))
}

/// The colours of a `thumb` JPEG. `None` when it is not a JPEG, declares a
/// side over [`THUMB_SIDE`] (or zero), does not decode within the cover decode
/// limits, or is gray (see [`MIN_SEED_CHROMA`]).
pub fn colors_of_thumbnail(bytes: &[u8]) -> Option<CoverColors> {
    thumb_pixels(bytes).and_then(|p| colors_of_pixels(&p))
}

/// The sampled opaque pixels of a `thumb` JPEG (at most 112 px a side), or
/// `None` when it is not one this code accepts.
fn thumb_pixels(bytes: &[u8]) -> Option<Vec<Argb>> {
    if !bytes.starts_with(&[0xFF, 0xD8, 0xFF]) {
        return None;
    }
    let header = jpeg_header::parse(bytes)?;
    let (width, height) = (u32::from(header.width), u32::from(header.height));
    if width == 0 || height == 0 || width.max(height) > THUMB_SIDE {
        return None;
    }
    let mut reader = ImageReader::with_format(Cursor::new(bytes), ImageFormat::Jpeg);
    reader.limits(decode_limits());
    let rgb = reader.decode().ok()?.into_rgb8();
    let longest = rgb.width().max(rgb.height());
    let sample = if longest > MAX_SAMPLE_SIDE {
        let fit = |side: u32| (side * MAX_SAMPLE_SIDE / longest).max(1);
        imageops::thumbnail(&rgb, fit(rgb.width()), fit(rgb.height()))
    } else {
        rgb
    };
    Some(
        sample
            .pixels()
            .map(|p| Argb::new(255, p[0], p[1], p[2]))
            .collect(),
    )
}

/// The colours of opaque `pixels`. `None` when there are none or the seed is
/// gray (chroma below [`MIN_SEED_CHROMA`]).
///
/// Clusters come from the Wu quantizer, and each distinct pixel colour is
/// counted toward its nearest cluster (CIE Lab distance). That is one pass of
/// the k-means refinement Flutter's `QuantizerCelebi` runs to convergence,
/// which in this crate costs about 25 times more for the same image; one pass
/// gives the populations `Score` needs.
pub fn colors_of_pixels(pixels: &[Argb]) -> Option<CoverColors> {
    if pixels.is_empty() {
        return None;
    }
    let distinct = QuantizerMap::quantize(pixels, 0).color_to_count;
    let distinct: Vec<(Argb, Lab, u32)> = distinct
        .into_iter()
        .map(|(color, count)| (color, Lab::from(color), count))
        .collect();
    let scored_seed = seed_of(&clustered(pixels, &distinct, SEED_CLUSTERS));
    let mut clusters: Vec<(Argb, u32)> = clustered(pixels, &distinct, PALETTE_SIZE)
        .color_to_count
        .into_iter()
        .filter(|&(_, count)| count > 0)
        .collect();
    // Most common first; ties in a fixed order so the result is stable.
    clusters.sort_by(|a, b| b.1.cmp(&a.1).then(a.0.cmp(&b.0)));
    let palette: Vec<u32> = clusters
        .into_iter()
        .take(PALETTE_SIZE)
        .map(|(color, _)| opaque(color))
        .collect();
    let seed = scored_seed.or_else(|| palette.first().copied())?;
    let hct: Hct = Argb::from_u32(seed).into();
    if hct.get_chroma() < MIN_SEED_CHROMA {
        return None;
    }
    Some(CoverColors { seed, palette })
}

/// Up to `clusters` Wu clusters of `pixels`, each with the number of pixels
/// (from `distinct`: colour, its Lab value, its count) nearest to it.
fn clustered(pixels: &[Argb], distinct: &[(Argb, Lab, u32)], clusters: usize) -> QuantizerResult {
    let mut result = QuantizerWu::quantize(pixels, clusters);
    let centers: Vec<(Argb, Lab)> = result
        .color_to_count
        .keys()
        .map(|&color| (color, Lab::from(color)))
        .collect();
    if centers.is_empty() {
        return result;
    }
    for &(_, lab, count) in distinct {
        let nearest = centers
            .iter()
            .map(|(color, center)| (color, lab_distance(&lab, center)))
            .min_by(|a, b| a.1.total_cmp(&b.1))
            .map(|(color, _)| *color);
        if let Some(color) = nearest {
            if let Some(population) = result.color_to_count.get_mut(&color) {
                *population += count;
            }
        }
    }
    result
}

fn lab_distance(a: &Lab, b: &Lab) -> f64 {
    let (dl, da, db) = (a.l - b.l, a.a - b.a, a.b - b.b);
    dl * dl + da * da + db * db
}

/// The seed of a quantized image, as Flutter's `ColorScheme.fromImageProvider`
/// picks it (`Score` with one colour wanted and filtering on); `None` when no
/// cluster scores.
///
/// `Score` must never see an empty map or one whose counts add up to zero: its
/// sort then compares NaN scores with `unwrap_unchecked`, which is undefined
/// behaviour that `catch_unwind` cannot catch.
fn seed_of(quantized: &QuantizerResult) -> Option<u32> {
    let counts = &quantized.color_to_count;
    if counts.is_empty() || counts.values().all(|&count| count == 0) {
        return None;
    }
    let none = Argb::new(0, 0, 0, 0);
    let best = Score::score(counts, Some(1), Some(none), Some(true))
        .first()
        .copied()
        .unwrap_or(none);
    (best.alpha != 0).then(|| opaque(best))
}

fn opaque(color: Argb) -> u32 {
    0xFF00_0000 | u32::from(color.red) << 16 | u32::from(color.green) << 8 | u32::from(color.blue)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn jpeg_of(width: u16, height: u16, pixel: impl Fn(u16, u16) -> [u8; 3]) -> Vec<u8> {
        let mut raw = Vec::new();
        for y in 0..height {
            for x in 0..width {
                raw.extend_from_slice(&pixel(x, y));
            }
        }
        let mut out = Vec::new();
        let mut encoder = jpeg_encoder::Encoder::new(&mut out, 90);
        encoder.set_sampling_factor(jpeg_encoder::SamplingFactor::F_1_1);
        encoder
            .encode(&raw, width, height, jpeg_encoder::ColorType::Rgb)
            .expect("encode");
        out
    }

    fn channels(argb: u32) -> [i32; 3] {
        [
            ((argb >> 16) & 0xFF) as i32,
            ((argb >> 8) & 0xFF) as i32,
            (argb & 0xFF) as i32,
        ]
    }

    fn close(argb: u32, rgb: [i32; 3]) -> bool {
        channels(argb)
            .iter()
            .zip(rgb)
            .all(|(a, b)| (a - b).abs() <= 24)
    }

    #[test]
    fn two_colour_image_has_the_dominant_colour_first() {
        // 3/4 red, 1/4 blue.
        let jpeg = jpeg_of(
            128,
            128,
            |x, _| if x < 96 { [220, 20, 20] } else { [20, 20, 220] },
        );
        let colors = colors_of_thumbnail(&jpeg).expect("colours");
        assert!(colors.palette.len() >= 2, "{:?}", colors.palette);
        assert!(
            close(colors.palette[0], [220, 20, 20]),
            "{:?}",
            colors.palette
        );
        assert!(close(colors.seed, [220, 20, 20]), "{:#x}", colors.seed);
        assert!(
            close(colors.palette[1], [20, 20, 220]),
            "{:?}",
            colors.palette
        );
        assert!(colors.palette.iter().all(|c| c >> 24 == 0xFF));
        assert_eq!(colors.seed >> 24, 0xFF);
    }

    #[test]
    fn colours_are_deterministic() {
        let jpeg = jpeg_of(200, 150, |x, y| {
            [(x % 251) as u8, (y % 241) as u8, ((x + y) % 199) as u8]
        });
        assert_eq!(colors_of_thumbnail(&jpeg), colors_of_thumbnail(&jpeg));
    }

    #[test]
    fn gray_images_have_no_colours() {
        for level in [0u8, 128, 255] {
            let jpeg = jpeg_of(64, 64, |_, _| [level; 3]);
            assert_eq!(colors_of_thumbnail(&jpeg), None, "{level}");
        }
        // A black and white cover: no accent colour either.
        let bw = jpeg_of(64, 64, |x, _| if x < 32 { [0; 3] } else { [255; 3] });
        assert_eq!(colors_of_thumbnail(&bw), None);
    }

    #[test]
    fn a_weakly_tinted_image_is_still_gray() {
        let jpeg = jpeg_of(64, 64, |_, _| [128, 128, 130]);
        assert_eq!(colors_of_thumbnail(&jpeg), None);
    }

    #[test]
    fn a_colourful_seed_has_enough_chroma() {
        let jpeg = jpeg_of(64, 64, |_, _| [200, 40, 40]);
        let colors = colors_of_thumbnail(&jpeg).expect("colours");
        let hct: Hct = Argb::from_u32(colors.seed).into();
        assert!(hct.get_chroma() >= MIN_SEED_CHROMA);
    }

    #[test]
    fn a_single_colour_image_has_its_colour_first() {
        let jpeg = jpeg_of(64, 64, |_, _| [200, 40, 40]);
        let colors = colors_of_thumbnail(&jpeg).expect("colours");
        assert!(close(colors.palette[0], [200, 40, 40]));
    }

    #[test]
    fn non_jpeg_oversize_and_garbage_give_none() {
        assert_eq!(colors_of_thumbnail(b""), None);
        assert_eq!(colors_of_thumbnail(b"\x89PNG....."), None);
        assert_eq!(colors_of_thumbnail(&[0xFF, 0xD8, 0xFF, 0xE0, 0, 0]), None);
        let big = jpeg_of(300, 20, |_, _| [1, 2, 3]);
        assert_eq!(colors_of_thumbnail(&big), None, "wider than a thumb");
        assert_eq!(colors_of_pixels(&[]), None);
    }

    #[test]
    fn cached_thumb_rejects_bad_keys_and_missing_files() {
        let open = |p: &Path| File::open(p).map_err(MediaError::from);
        let dir = Path::new("/nonexistent/kanaru-cache");
        assert_eq!(
            colors_of_cached_thumb(dir, "../x", &open),
            Err(MediaError::Unsupported)
        );
        assert_eq!(
            colors_of_cached_thumb(dir, "ab/0123456789abcdef0123456789abcdef", &open),
            Err(MediaError::Io(std::io::ErrorKind::NotFound))
        );
    }
}
