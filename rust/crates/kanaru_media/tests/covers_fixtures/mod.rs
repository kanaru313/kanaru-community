//! Cover images built in memory with `image` and `jpeg-encoder`, including
//! hostile ones (header-only, truncated, trailing bytes).
#![allow(dead_code)]

use std::io::Cursor;

use image::{ImageFormat, RgbImage, RgbaImage};

/// Baseline (or progressive) 4:4:4 JPEG, `pixel(x, y)` gives the colour.
pub fn jpeg(
    width: u16,
    height: u16,
    progressive: bool,
    pixel: impl Fn(u16, u16) -> [u8; 3],
) -> Vec<u8> {
    let mut raw = Vec::with_capacity(usize::from(width) * usize::from(height) * 3);
    for y in 0..height {
        for x in 0..width {
            raw.extend_from_slice(&pixel(x, y));
        }
    }
    let mut out = Vec::new();
    let mut encoder = jpeg_encoder::Encoder::new(&mut out, 80);
    encoder.set_sampling_factor(jpeg_encoder::SamplingFactor::F_1_1);
    encoder.set_progressive(progressive);
    encoder
        .encode(&raw, width, height, jpeg_encoder::ColorType::Rgb)
        .expect("encode jpeg");
    out
}

/// A JPEG of two vertical halves, left red and right blue.
pub fn two_color_jpeg(width: u16, height: u16) -> Vec<u8> {
    jpeg(width, height, false, |x, _| {
        if x < width / 2 {
            [220, 30, 30]
        } else {
            [30, 30, 220]
        }
    })
}

/// A JPEG with a distinct look per `seed`, so two have different keys.
pub fn varied_jpeg(width: u16, height: u16, seed: u8) -> Vec<u8> {
    jpeg(width, height, false, |x, y| {
        [
            seed.wrapping_add((x / 8) as u8),
            seed.wrapping_mul(3).wrapping_add((y / 8) as u8),
            128,
        ]
    })
}

pub fn encode_with(format: ImageFormat, image: image::DynamicImage) -> Vec<u8> {
    let mut out = Cursor::new(Vec::new());
    image.write_to(&mut out, format).expect("encode image");
    out.into_inner()
}

pub fn png(width: u32, height: u32, pixel: impl Fn(u32, u32) -> [u8; 3]) -> Vec<u8> {
    let image = RgbImage::from_fn(width, height, |x, y| image::Rgb(pixel(x, y)));
    encode_with(ImageFormat::Png, image::DynamicImage::ImageRgb8(image))
}

/// PNG whose pixels are red but fully transparent.
pub fn transparent_png(width: u32, height: u32) -> Vec<u8> {
    let image = RgbaImage::from_pixel(width, height, image::Rgba([255, 0, 0, 0]));
    encode_with(ImageFormat::Png, image::DynamicImage::ImageRgba8(image))
}

/// CRC-32 of PNG chunks, bitwise.
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

/// A PNG whose header declares `width` x `height` with no pixel data behind
/// it (a valid header checksum, a real tiny IDAT).
pub fn png_header_only(width: u32, height: u32) -> Vec<u8> {
    let mut bytes = png(1, 1, |_, _| [9, 9, 9]);
    bytes[16..20].copy_from_slice(&width.to_be_bytes());
    bytes[20..24].copy_from_slice(&height.to_be_bytes());
    let crc = crc32(&bytes[12..29]);
    bytes[29..33].copy_from_slice(&crc.to_be_bytes());
    bytes
}

/// A baseline JPEG whose frame header declares `width` x `height` while the
/// entropy data is only that of a 16x16 picture.
pub fn jpeg_header_only(width: u16, height: u16) -> Vec<u8> {
    let mut bytes = jpeg(16, 16, false, |_, _| [50, 60, 70]);
    let at = bytes
        .windows(2)
        .position(|w| w == [0xFF, 0xC0])
        .expect("SOF0");
    // SOF0: marker (2), length (2), precision (1), height (2), width (2).
    bytes[at + 5..at + 7].copy_from_slice(&height.to_be_bytes());
    bytes[at + 7..at + 9].copy_from_slice(&width.to_be_bytes());
    bytes
}

/// `jpeg` with an EXIF APP1 segment that says `orientation`.
pub fn with_jpeg_orientation(jpeg: &[u8], orientation: u16) -> Vec<u8> {
    let mut tiff = b"MM\0\x2a\0\0\0\x08\0\x01\x01\x12\0\x03\0\0\0\x01".to_vec();
    tiff.extend_from_slice(&orientation.to_be_bytes());
    tiff.extend_from_slice(&[0; 6]);
    let mut segment = vec![0xFF, 0xE1];
    segment.extend_from_slice(&((2 + 6 + tiff.len()) as u16).to_be_bytes());
    segment.extend_from_slice(b"Exif\0\0");
    segment.extend_from_slice(&tiff);
    let mut out = jpeg[..2].to_vec();
    out.extend_from_slice(&segment);
    out.extend_from_slice(&jpeg[2..]);
    out
}

/// Extended lossless WebP (VP8X + VP8L + EXIF) whose orientation is
/// `orientation`; the picture is `width` x `height` before the turn.
pub fn webp_with_orientation(width: u32, height: u32, orientation: u16) -> Vec<u8> {
    let image = RgbImage::from_fn(width, height, |x, _| {
        if x < width / 2 {
            image::Rgb([200, 20, 20])
        } else {
            image::Rgb([20, 20, 200])
        }
    });
    let plain = encode_with(ImageFormat::WebP, image::DynamicImage::ImageRgb8(image));
    // Pick the VP8L chunk out of the simple file: "RIFF" size "WEBP" then chunks.
    let vp8l = &plain[12..];
    assert_eq!(&vp8l[..4], b"VP8L", "lossless encoder output");

    let mut tiff = b"MM\0\x2a\0\0\0\x08\0\x01\x01\x12\0\x03\0\0\0\x01".to_vec();
    tiff.extend_from_slice(&orientation.to_be_bytes());
    tiff.extend_from_slice(&[0; 6]);

    let mut vp8x = Vec::new();
    vp8x.extend_from_slice(&[0x08, 0, 0, 0]); // EXIF flag
    vp8x.extend_from_slice(&(width - 1).to_le_bytes()[..3]);
    vp8x.extend_from_slice(&(height - 1).to_le_bytes()[..3]);

    let mut body = b"WEBP".to_vec();
    body.extend_from_slice(b"VP8X");
    body.extend_from_slice(&(vp8x.len() as u32).to_le_bytes());
    body.extend_from_slice(&vp8x);
    body.extend_from_slice(vp8l);
    body.extend_from_slice(b"EXIF");
    body.extend_from_slice(&(tiff.len() as u32).to_le_bytes());
    body.extend_from_slice(&tiff);
    if tiff.len() % 2 == 1 {
        body.push(0);
    }
    let mut out = b"RIFF".to_vec();
    out.extend_from_slice(&(body.len() as u32).to_le_bytes());
    out.extend_from_slice(&body);
    out
}

/// Width and height of a JPEG file's frame header.
pub fn jpeg_size(bytes: &[u8]) -> (u32, u32) {
    image::ImageReader::with_format(Cursor::new(bytes), ImageFormat::Jpeg)
        .into_dimensions()
        .expect("jpeg dimensions")
}

/// The decoded RGB pixel at (x, y).
pub fn pixel_at(bytes: &[u8], x: u32, y: u32) -> [u8; 3] {
    let image = image::load_from_memory_with_format(bytes, ImageFormat::Jpeg)
        .expect("decode jpeg")
        .into_rgb8();
    image.get_pixel(x, y).0
}
