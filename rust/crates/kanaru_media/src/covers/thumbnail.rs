//! Turns an original cover image into the two JPEGs the library shows: a
//! 1024 px `full` and a 256 px `thumb`, from one decode.

use std::io::Cursor;
use std::panic::{catch_unwind, AssertUnwindSafe};

use image::metadata::Orientation;
use image::{DynamicImage, GrayImage, ImageFormat, ImageReader, RgbImage};

use super::decode_limits::{
    decode_limits, full_decode_fits, jpeg_data_fills_frame, scaled_plan, ScaledPlan,
};
use super::gate;
use super::jpeg_header::{self, JpegHeader};
use super::webp_exif;

/// Longest side of a `thumb`, in pixels.
pub const THUMB_SIDE: u32 = 256;

/// Longest side of a `full`, in pixels.
pub const FULL_SIDE: u32 = 1024;

const JPEG_QUALITY: u8 = 85;

/// Largest original JPEG used as its own `full`.
const MAX_PASSTHROUGH_BYTES: usize = 200 * 1024;

/// The two encoded sizes of one cover.
#[derive(Debug)]
pub struct CoverJpegs {
    pub thumb: Vec<u8>,
    pub full: Vec<u8>,
}

/// Decodes `bytes` (already checked by `sources::validate_header`, which also
/// gives `pixels`) and encodes both sizes, keeping the aspect ratio. Smaller
/// images are re-encoded at their own size, never enlarged. Transparent parts
/// end up on black. A JPEG or WebP is turned upright per its EXIF
/// orientation. `full` is the original JPEG minus its metadata when that is
/// safe (see [`passthrough`]); a large JPEG is decoded scaled down (see
/// `scaled_plan`). Every shortcut falls back to the full path on any trouble.
/// `None` when the image breaks a decode limit or is corrupt. A decode of an
/// image over 8 MP waits for the process-wide gate.
pub fn make_jpegs(bytes: &[u8], format: ImageFormat, pixels: u64) -> Option<CoverJpegs> {
    // A panic anywhere (decode, blend, resize, turn, encode) means this source
    // is unusable, so the caller moves on to the next one.
    guarded(|| {
        let _gate = gate::enter_for(pixels);
        build(bytes, format)
    })
}

fn build(bytes: &[u8], format: ImageFormat) -> Option<CoverJpegs> {
    if format == ImageFormat::Jpeg && !jpeg_data_fills_frame(bytes) {
        return None;
    }
    let mut original = None;
    let image = match guarded(|| scaled_decode(bytes, format)) {
        Some(image) => image,
        None => {
            if !full_decode_fits(bytes, format) {
                return None;
            }
            let image = full_decode(bytes, format)?;
            if format == ImageFormat::Jpeg {
                original = guarded(|| passthrough(bytes, &image));
            }
            image
        }
    };

    // Blended over black before the resize: averaging blended colours is what
    // a resize with premultiplied alpha gives. The turn comes after the
    // shrink: turning a small picture costs next to nothing and needs no
    // buffer the size of the original.
    let rgb = flatten_and_shrink(image, FULL_SIDE)?;
    let rgb = turn_upright(rgb, exif_orientation(bytes, format));
    let full = match original {
        Some(original) => original,
        None => encode(&rgb)?,
    };
    let thumb = encode(&shrink_rgb(rgb, THUMB_SIDE)?)?;
    Some(CoverJpegs { thumb, full })
}

/// EXIF orientation of the original: from the JPEG header or the WebP `EXIF`
/// chunk; PNG is not read, so it counts as upright.
fn exif_orientation(bytes: &[u8], format: ImageFormat) -> u16 {
    match format {
        ImageFormat::Jpeg => jpeg_header::parse(bytes).map_or(1, |header| header.orientation),
        ImageFormat::WebP => webp_exif::orientation(bytes),
        _ => 1,
    }
}

/// `rgb` turned or flipped as the EXIF `orientation` says; a value that is
/// not an orientation leaves it as is. Neither the JPEG decoder nor `image`
/// applies it on its own.
fn turn_upright(rgb: RgbImage, orientation: u16) -> RgbImage {
    let orientation = u8::try_from(orientation)
        .ok()
        .and_then(Orientation::from_exif)
        .unwrap_or(Orientation::NoTransforms);
    if orientation == Orientation::NoTransforms {
        return rgb;
    }
    let mut image = DynamicImage::ImageRgb8(rgb);
    image.apply_orientation(orientation);
    image.into_rgb8()
}

/// `rgb` as a JPEG at [`JPEG_QUALITY`], colour at full resolution (4:4:4), so
/// text and edges in covers keep their colour.
fn encode(rgb: &RgbImage) -> Option<Vec<u8>> {
    let width = u16::try_from(rgb.width()).ok()?;
    let height = u16::try_from(rgb.height()).ok()?;
    let mut out = Vec::new();
    let mut encoder = jpeg_encoder::Encoder::new(&mut out, JPEG_QUALITY);
    encoder.set_sampling_factor(jpeg_encoder::SamplingFactor::F_1_1);
    encoder
        .encode(rgb.as_raw(), width, height, jpeg_encoder::ColorType::Rgb)
        .ok()?;
    Some(out)
}

/// Runs a shortcut; a panic inside it counts as "not taken".
fn guarded<T>(shortcut: impl FnOnce() -> Option<T>) -> Option<T> {
    catch_unwind(AssertUnwindSafe(shortcut)).ok().flatten()
}

fn full_decode(bytes: &[u8], format: ImageFormat) -> Option<DynamicImage> {
    let mut reader = ImageReader::with_format(Cursor::new(bytes), format);
    reader.limits(decode_limits());
    reader.decode().ok()
}

/// A large JPEG decoded at a DCT scale of 1/2, 1/4 or 1/8 (see [`scaled_plan`]
/// for when that applies). `None` when it does not apply or on any error.
fn scaled_decode(bytes: &[u8], format: ImageFormat) -> Option<DynamicImage> {
    let ScaledPlan {
        mut decoder,
        width,
        height,
        output,
    } = scaled_plan(bytes, format)?;
    decoder.set_max_decoding_buffer_size(usize::try_from(output).ok()?);
    let pixels = decoder.decode().ok()?;
    let (width, height) = (u32::from(width), u32::from(height));
    match decoder.info()?.pixel_format {
        jpeg_decoder::PixelFormat::RGB24 => {
            RgbImage::from_raw(width, height, pixels).map(DynamicImage::ImageRgb8)
        }
        jpeg_decoder::PixelFormat::L8 => {
            GrayImage::from_raw(width, height, pixels).map(DynamicImage::ImageLuma8)
        }
        _ => None,
    }
}

/// The original JPEG without its metadata segments, when it can serve as its
/// own `full`: at most [`FULL_SIDE`] and [`MAX_PASSTHROUGH_BYTES`], one scan
/// that runs into the final EOI, baseline, three YCbCr components, upright
/// (EXIF orientation 1, since the EXIF segment goes), one frame whose size
/// matches `decoded`. `decoded` is the full decode of `bytes`, so only bytes
/// that decode reach the cache; the decoder fills a scan that was cut short
/// without complaint and stops at the first EOI, hence the scan check.
fn passthrough(bytes: &[u8], decoded: &DynamicImage) -> Option<Vec<u8>> {
    if bytes.len() > MAX_PASSTHROUGH_BYTES || !jpeg_header::ends_with_first_scan(bytes) {
        return None;
    }
    let header = jpeg_header::parse(bytes)?;
    if !fits_as_is(&header, (decoded.width(), decoded.height())) {
        return None;
    }
    jpeg_header::strip_metadata(bytes)
}

fn fits_as_is(header: &JpegHeader, decoded: (u32, u32)) -> bool {
    let size = (u32::from(header.width), u32::from(header.height));
    !header.progressive
        && header.sampling.len() == 3
        && header
            .adobe_transform
            .is_none_or(|transform| transform == 1)
        && header.orientation == 1
        && size.0.max(size.1) <= FULL_SIDE
        && size == decoded
}

/// `image` blended over black and fitted within `side` (aspect kept, rounded
/// like `image`'s `thumbnail`), or at its own size when it already fits. The
/// work happens on the decoded buffer in its own channel layout (gray, gray
/// with alpha, RGB, RGBA): the blend is in place and the resize reads the
/// buffer as is, so no second buffer the size of the original exists. Only
/// the small result is widened to RGB.
fn flatten_and_shrink(image: DynamicImage, side: u32) -> Option<RgbImage> {
    let (width, height) = (image.width(), image.height());
    let channels = usize::from(image.color().channel_count());
    let mut data = match channels {
        1 => image.into_luma8().into_raw(),
        2 => image.into_luma_alpha8().into_raw(),
        3 => image.into_rgb8().into_raw(),
        _ => image.into_rgba8().into_raw(),
    };
    if channels % 2 == 0 {
        blend_on_black(&mut data, channels);
    }
    let (new_width, new_height) = fitted_size(width, height, side);
    if (new_width, new_height) != (width, height) {
        data = resize(width, height, channels, data, (new_width, new_height))?;
    }
    let mut rgb = Vec::with_capacity(new_width as usize * new_height as usize * 3);
    for pixel in data.chunks_exact(channels) {
        match channels {
            1 | 2 => rgb.extend_from_slice(&[pixel[0]; 3]),
            _ => rgb.extend_from_slice(&pixel[..3]),
        }
    }
    RgbImage::from_raw(new_width, new_height, rgb)
}

/// `rgb` fitted within `side`; unchanged when it already fits.
fn shrink_rgb(rgb: RgbImage, side: u32) -> Option<RgbImage> {
    let (width, height) = rgb.dimensions();
    let to = fitted_size(width, height, side);
    if to == (width, height) {
        return Some(rgb);
    }
    let data = resize(width, height, 3, rgb.into_raw(), to)?;
    RgbImage::from_raw(to.0, to.1, data)
}

/// The size of a `width` x `height` image fitted within `side`.
fn fitted_size(width: u32, height: u32, side: u32) -> (u32, u32) {
    let longest = width.max(height);
    if longest <= side {
        return (width, height);
    }
    let ratio = f64::from(side) / f64::from(longest);
    let fit = |s: u32| ((f64::from(s) * ratio).round() as u32).max(1);
    (fit(width), fit(height))
}

/// JPEG has no alpha channel: multiplies every colour channel by its pixel's
/// alpha (the last channel), in place. The alpha channel itself is left, and
/// dropped later.
fn blend_on_black(data: &mut [u8], channels: usize) {
    for pixel in data.chunks_exact_mut(channels) {
        let (colors, alpha) = pixel.split_at_mut(channels - 1);
        let alpha = u16::from(alpha[0]);
        for color in colors {
            *color = ((u16::from(*color) * alpha + 127) / 255) as u8;
        }
    }
}

/// `data` (`width` x `height`, `channels` 8-bit channels, no alpha handling)
/// resized to `to` with fast_image_resize (Lanczos3, SIMD chosen at run
/// time); on any error, with `image`.
fn resize(
    width: u32,
    height: u32,
    channels: usize,
    data: Vec<u8>,
    to: (u32, u32),
) -> Option<Vec<u8>> {
    use fast_image_resize as fir;
    let pixel_type = match channels {
        1 => fir::PixelType::U8,
        2 => fir::PixelType::U8x2,
        3 => fir::PixelType::U8x3,
        _ => fir::PixelType::U8x4,
    };
    let resized = guarded(|| {
        let source = fir::images::ImageRef::new(width, height, &data, pixel_type).ok()?;
        let mut target = fir::images::Image::new(to.0, to.1, pixel_type);
        // The channels were blended already: no alpha handling of its own.
        let options = fir::ResizeOptions::new()
            .resize_alg(fir::ResizeAlg::Convolution(fir::FilterType::Lanczos3))
            .use_alpha(false);
        fir::Resizer::new()
            .resize(&source, &mut target, &options)
            .ok()?;
        Some(target.into_vec())
    });
    resized.or_else(|| match channels {
        1 => thumbnail_of::<image::Luma<u8>>(width, height, data, to),
        2 => thumbnail_of::<image::LumaA<u8>>(width, height, data, to),
        3 => thumbnail_of::<image::Rgb<u8>>(width, height, data, to),
        _ => thumbnail_of::<image::Rgba<u8>>(width, height, data, to),
    })
}

/// The fallback resize, with `image`.
fn thumbnail_of<P: image::Pixel<Subpixel = u8> + 'static>(
    width: u32,
    height: u32,
    data: Vec<u8>,
    to: (u32, u32),
) -> Option<Vec<u8>> {
    let image = image::ImageBuffer::<P, Vec<u8>>::from_raw(width, height, data)?;
    Some(image::imageops::thumbnail(&image, to.0, to.1).into_raw())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn guarded_turns_a_panic_into_none() {
        let out: Option<u8> = guarded(|| panic!("a decoder gave up"));
        assert_eq!(out, None);
    }

    #[test]
    fn guarded_passes_a_result_through() {
        assert_eq!(guarded(|| Some(7)), Some(7));
        assert_eq!(guarded(|| None::<u8>), None);
    }

    fn header() -> JpegHeader {
        JpegHeader {
            width: 400,
            height: 300,
            progressive: false,
            sampling: vec![(2, 2), (1, 1), (1, 1)],
            adobe_transform: None,
            orientation: 1,
        }
    }

    #[test]
    fn only_small_upright_baseline_ycbcr_fits_as_is() {
        assert!(fits_as_is(&header(), (400, 300)));
        assert!(fits_as_is(
            &JpegHeader {
                adobe_transform: Some(1),
                ..header()
            },
            (400, 300)
        ));
        let refused = [
            JpegHeader {
                progressive: true,
                ..header()
            },
            JpegHeader {
                sampling: vec![(1, 1); 4],
                ..header()
            },
            JpegHeader {
                sampling: vec![(1, 1)],
                ..header()
            },
            JpegHeader {
                adobe_transform: Some(2),
                ..header()
            },
            JpegHeader {
                adobe_transform: Some(0),
                ..header()
            },
            JpegHeader {
                orientation: 6,
                ..header()
            },
            JpegHeader {
                width: 1025,
                ..header()
            },
        ];
        for refused in refused {
            let size = (u32::from(refused.width), u32::from(refused.height));
            assert!(!fits_as_is(&refused, size), "{refused:?}");
        }
        assert!(!fits_as_is(&header(), (300, 400)), "decoded size differs");
    }

    #[test]
    fn fitted_size_keeps_aspect_and_never_enlarges() {
        assert_eq!(fitted_size(2048, 1024, 1024), (1024, 512));
        assert_eq!(fitted_size(100, 3000, 256), (9, 256));
        assert_eq!(fitted_size(200, 100, 256), (200, 100));
        assert_eq!(fitted_size(1, 5000, 256), (1, 256));
    }

    #[test]
    fn resize_rings_at_edges() {
        // A step edge in the middle: a convolution with negative lobes
        // (Lanczos) overshoots on both sides, a bilinear blend never does.
        let step = RgbImage::from_fn(2048, 8, |x, _| {
            let level = if x < 1024 { 64 } else { 192 };
            image::Rgb([level; 3])
        });
        let shrunk = flatten_and_shrink(DynamicImage::ImageRgb8(step), FULL_SIDE).unwrap();
        assert_eq!(shrunk.dimensions(), (1024, 4));
        assert!(shrunk.pixels().any(|p| p.0[0] < 64 || p.0[0] > 192));
    }
}
