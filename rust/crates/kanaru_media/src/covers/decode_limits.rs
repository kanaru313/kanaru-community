//! What a decode of a cover may take, checked from the headers alone, before
//! any pixel buffer exists. The pixel cap (`MAX_COVER_PIXELS`) is checked
//! earlier, in `sources::validate_header`.

use std::io::Cursor;

use image::{ImageFormat, Limits};

use super::jpeg_header::{self, JpegHeader};
use super::thumbnail::FULL_SIDE;

/// Upper bound on the buffers one decode may allocate, in the format the
/// decoder produces: the pixel buffer and, for a progressive JPEG, its
/// coefficients (see [`progressive_coefficient_bytes`]). What comes after
/// stays within about one more such buffer: the alpha blend and the resize
/// work in place on the decoded pixels, and the results are at most 1024 px.
/// Decodes of images over 8 MP also run one at a time (see `gate`).
pub const MAX_DECODE_BYTES: u64 = 64 * 1024 * 1024;

/// JPEGs with a longer side are decoded at 1/2, 1/4 or 1/8 of their size,
/// still at least [`FULL_SIDE`]: most of the decode work is skipped.
const SCALED_DECODE_ABOVE: u32 = FULL_SIDE;

/// The limits of a full decode.
pub(crate) fn decode_limits() -> Limits {
    let mut limits = Limits::default();
    limits.max_alloc = Some(MAX_DECODE_BYTES);
    limits
}

/// A scaled JPEG decode that is allowed: the decoder, set to the smallest DCT
/// scale (1/2, 1/4, 1/8) that keeps the longest side at least [`FULL_SIDE`],
/// and the size it will produce.
pub(crate) struct ScaledPlan<'a> {
    pub decoder: jpeg_decoder::Decoder<Cursor<&'a [u8]>>,
    pub width: u16,
    pub height: u16,
    /// Bytes of the decoded pixels.
    pub output: u64,
}

/// The scaled decode of `bytes`, when it applies: a JPEG whose longest side
/// is over [`SCALED_DECODE_ABOVE`], gray or YCbCr (or RGB; CMYK and YCCK take
/// the full path), whose decode needs no more than [`MAX_DECODE_BYTES`] (see
/// [`progressive_coefficient_bytes`]). Only headers are read.
pub(crate) fn scaled_plan(bytes: &[u8], format: ImageFormat) -> Option<ScaledPlan<'_>> {
    if format != ImageFormat::Jpeg {
        return None;
    }
    let header = jpeg_header::parse(bytes)?;
    let side = u32::from(header.width.max(header.height));
    if side <= SCALED_DECODE_ABOVE || header.sampling.len() == 4 {
        return None;
    }
    let mut decoder = jpeg_decoder::Decoder::new(Cursor::new(bytes));
    let side = u16::try_from(FULL_SIDE).ok()?;
    let (width, height) = decoder.scale(side, side).ok()?;
    let output = u64::from(width) * u64::from(height) * header.sampling.len() as u64;
    // The output is held about twice: component planes, then the
    // interleaved pixels.
    if progressive_coefficient_bytes(&header) + 2 * output > MAX_DECODE_BYTES {
        return None;
    }
    Some(ScaledPlan {
        decoder,
        width,
        height,
        output,
    })
}

/// Whether the full decode of `bytes` keeps to [`MAX_DECODE_BYTES`].
/// `image`'s limit only bounds the output buffer, but a progressive JPEG also
/// keeps every coefficient of the image until its last scan, so one that would
/// need more is refused: no cover, rather than a decode far over the limit.
/// Other images are left to `image`'s own limits.
pub(crate) fn full_decode_fits(bytes: &[u8], format: ImageFormat) -> bool {
    if format != ImageFormat::Jpeg {
        return true;
    }
    let Some(header) = jpeg_header::parse(bytes) else {
        return true;
    };
    if !header.progressive {
        return true;
    }
    let output = u64::from(header.width) * u64::from(header.height) * header.sampling.len() as u64;
    progressive_coefficient_bytes(&header) + output <= MAX_DECODE_BYTES
}

/// What a decode holds besides its output, at most: a progressive JPEG keeps
/// every DCT coefficient of the full-size image (64 two-byte values per 8x8
/// block, blocks padded to whole MCUs) until its last scan, at any output
/// scale; a baseline one decodes row by row. The output comes on top,
/// counted by the caller.
fn progressive_coefficient_bytes(header: &JpegHeader) -> u64 {
    if !header.progressive {
        return 0;
    }
    block_count(header) * 64 * 2
}

/// DCT blocks of the frame over all components, padded to whole MCUs.
fn block_count(header: &JpegHeader) -> u64 {
    let h_max = header
        .sampling
        .iter()
        .map(|s| u64::from(s.0))
        .max()
        .unwrap_or(1);
    let v_max = header
        .sampling
        .iter()
        .map(|s| u64::from(s.1))
        .max()
        .unwrap_or(1);
    let mcus_x = u64::from(header.width).div_ceil(8 * h_max);
    let mcus_y = u64::from(header.height).div_ceil(8 * v_max);
    header
        .sampling
        .iter()
        .map(|&(h, v)| mcus_x * u64::from(h) * mcus_y * u64::from(v))
        .sum()
}

/// Whether `bytes` hold at least the one bit per block that any coded JPEG
/// frame needs (a Huffman code is at least one bit and every block codes at
/// least one symbol). A file that declares a large frame and carries a few
/// hundred bytes is a header-only fixture or a hostile file: refused before
/// the decoder fills the frame with gray. `true` for anything that is not a
/// parseable JPEG; the decoders judge those.
pub(crate) fn jpeg_data_fills_frame(bytes: &[u8]) -> bool {
    match jpeg_header::parse(bytes) {
        Some(header) => (bytes.len() as u64) * 8 >= block_count(&header),
        None => true,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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

    /// A uniform `side` x `side` JPEG.
    fn jpeg(side: u16, color: jpeg_encoder::ColorType, progressive: bool) -> Vec<u8> {
        let channels = if color == jpeg_encoder::ColorType::Cmyk {
            4
        } else {
            3
        };
        let pixels = vec![120u8; usize::from(side) * usize::from(side) * channels];
        let mut out = Vec::new();
        let mut encoder = jpeg_encoder::Encoder::new(&mut out, 50);
        encoder.set_progressive(progressive);
        encoder.set_sampling_factor(jpeg_encoder::SamplingFactor::F_1_1);
        encoder.encode(&pixels, side, side, color).unwrap();
        out
    }

    #[test]
    fn progressive_decode_memory_counts_padded_blocks() {
        let progressive = |width, height, sampling: Vec<(u8, u8)>| JpegHeader {
            width,
            height,
            progressive: true,
            sampling,
            ..header()
        };
        assert_eq!(progressive_coefficient_bytes(&header()), 0, "baseline");
        // 2000x1000 4:2:0: 125x63 MCUs; 4 luma + 2 chroma blocks per MCU.
        let blocks = 125 * 63 * 6;
        let yuv420 = progressive(2000, 1000, vec![(2, 2), (1, 1), (1, 1)]);
        assert_eq!(progressive_coefficient_bytes(&yuv420), blocks * 128);
        // 4096^2 4:4:4: 3 x 512^2 blocks = 96 MiB, over the cap.
        let full = progressive(4096, 4096, vec![(1, 1); 3]);
        assert_eq!(progressive_coefficient_bytes(&full), 3 * 512 * 512 * 128);
        assert!(progressive_coefficient_bytes(&full) > MAX_DECODE_BYTES);
    }

    #[test]
    fn a_frame_larger_than_its_data_is_refused() {
        use jpeg_encoder::ColorType::Rgb;
        assert!(jpeg_data_fills_frame(&jpeg(2048, Rgb, false)));
        assert!(jpeg_data_fills_frame(&jpeg(16, Rgb, true)));
        assert!(jpeg_data_fills_frame(b"not a jpeg"));
        // Patch the frame header of a tiny file to declare 5000 x 5000.
        let mut bytes = jpeg(16, Rgb, false);
        let at = bytes.windows(2).position(|w| w == [0xFF, 0xC0]).unwrap();
        bytes[at + 5..at + 7].copy_from_slice(&5000u16.to_be_bytes());
        bytes[at + 7..at + 9].copy_from_slice(&5000u16.to_be_bytes());
        assert!(!jpeg_data_fills_frame(&bytes));
    }

    #[test]
    fn scaled_decode_applies_to_large_baseline_jpeg_only() {
        use jpeg_encoder::ColorType::{Cmyk, Rgb};
        assert!(scaled_plan(&jpeg(2048, Rgb, false), ImageFormat::Jpeg).is_some());
        assert!(scaled_plan(&jpeg(1024, Rgb, false), ImageFormat::Jpeg).is_none());
        assert!(scaled_plan(&jpeg(2048, Cmyk, false), ImageFormat::Jpeg).is_none());
        assert!(scaled_plan(&jpeg(2048, Rgb, false), ImageFormat::Png).is_none());
        let bytes = jpeg(4096, Rgb, false);
        let plan = scaled_plan(&bytes, ImageFormat::Jpeg).expect("plan");
        assert_eq!((plan.width, plan.height), (1024, 1024));
        assert_eq!(plan.output, 1024 * 1024 * 3);
    }

    #[test]
    fn progressive_jpeg_over_the_memory_cap_is_refused() {
        use jpeg_encoder::ColorType::Rgb;
        assert!(full_decode_fits(&jpeg(1000, Rgb, true), ImageFormat::Jpeg));
        assert!(!full_decode_fits(&jpeg(4096, Rgb, true), ImageFormat::Jpeg));
        assert!(full_decode_fits(&jpeg(4096, Rgb, false), ImageFormat::Jpeg));
        assert!(full_decode_fits(b"not a jpeg", ImageFormat::Jpeg));
    }
}
