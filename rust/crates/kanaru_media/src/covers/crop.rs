//! The square a user cut out of a cover image, and where it lies in the
//! stored picture.
//!
//! A crop is given in pixels of the *upright* original (after the EXIF
//! orientation turn), the picture the user sees. Decoding works on the
//! *stored* picture, which may be turned or flipped, and on a scaled-down
//! decode of it; [`CropRect::to_stored`] and [`CropRect::scaled`] map the
//! rectangle there.

use crate::MediaError;

/// A square region: `side` x `side` pixels with its top-left corner at
/// (`left`, `top`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CropRect {
    pub left: u32,
    pub top: u32,
    pub side: u32,
}

/// Size of a `width` x `height` picture after the EXIF `orientation` turn
/// (5 to 8 swap the axes; any other value leaves it as is).
pub fn upright_size(orientation: u16, width: u32, height: u32) -> (u32, u32) {
    if (5..=8).contains(&orientation) {
        (height, width)
    } else {
        (width, height)
    }
}

/// Checks `crop` against the upright size of the original and reduces it to
/// its canonical form: a crop that covers a whole square picture is `None`
/// (the same cover as no crop, so it gets the same key). `Unsupported`
/// (permanent) for a crop with side 0 or one that leaves the picture.
pub fn normalise(
    crop: Option<CropRect>,
    upright: (u32, u32),
) -> Result<Option<CropRect>, MediaError> {
    let Some(crop) = crop else {
        return Ok(None);
    };
    let fits = |start: u32, size: u32| start.checked_add(crop.side).is_some_and(|e| e <= size);
    if crop.side == 0 || !fits(crop.left, upright.0) || !fits(crop.top, upright.1) {
        return Err(MediaError::Unsupported);
    }
    let whole = crop.left == 0 && crop.top == 0 && upright.0 == upright.1 && crop.side == upright.0;
    Ok((!whole).then_some(crop))
}

impl CropRect {
    /// This upright rectangle in the stored picture of `width` x `height`,
    /// whose EXIF `orientation` turns it upright. The rectangle must lie in
    /// the upright picture (see [`normalise`]).
    pub fn to_stored(self, orientation: u16, width: u32, height: u32) -> CropRect {
        let last = self.side.saturating_sub(1);
        let a = stored_point(orientation, (self.left, self.top), (width, height));
        let b = stored_point(
            orientation,
            (self.left + last, self.top + last),
            (width, height),
        );
        CropRect {
            left: a.0.min(b.0),
            top: a.1.min(b.1),
            side: self.side,
        }
    }

    /// This rectangle of a `from` sized picture, in the same picture decoded
    /// at size `to` (a DCT-scaled JPEG decode). Stays a square inside `to`.
    pub fn scaled(self, from: (u32, u32), to: (u32, u32)) -> CropRect {
        if from == to {
            return self;
        }
        let ratio = |to: u32, from: u32| f64::from(to) / f64::from(from.max(1));
        let side = ((f64::from(self.side) * ratio(to.0, from.0)).round() as u32)
            .clamp(1, to.0.min(to.1).max(1));
        let place = |start: u32, to: u32, from: u32| {
            ((f64::from(start) * ratio(to, from)).round() as u32).min(to.saturating_sub(side))
        };
        CropRect {
            left: place(self.left, to.0, from.0),
            top: place(self.top, to.1, from.1),
            side,
        }
    }
}

/// The stored pixel that ends up at the upright pixel `(x, y)` once the EXIF
/// `orientation` is applied; `(width, height)` is the stored size.
fn stored_point(orientation: u16, (x, y): (u32, u32), (width, height): (u32, u32)) -> (u32, u32) {
    let flip_x = |x: u32| width.saturating_sub(1 + x);
    let flip_y = |y: u32| height.saturating_sub(1 + y);
    match orientation {
        2 => (flip_x(x), y),
        3 => (flip_x(x), flip_y(y)),
        4 => (x, flip_y(y)),
        5 => (y, x),
        6 => (y, flip_y(x)),
        7 => (flip_x(y), flip_y(x)),
        8 => (flip_x(y), x),
        _ => (x, y),
    }
}

#[cfg(test)]
mod tests {
    use super::super::thumbnail::turn_upright;
    use super::*;
    use image::RgbImage;

    /// Every pixel carries its own coordinates.
    fn coded(width: u32, height: u32) -> RgbImage {
        RgbImage::from_fn(width, height, |x, y| image::Rgb([x as u8, y as u8, 7]))
    }

    fn crop_of(image: &RgbImage, rect: CropRect) -> RgbImage {
        image::imageops::crop_imm(image, rect.left, rect.top, rect.side, rect.side).to_image()
    }

    #[test]
    fn to_stored_is_the_inverse_of_the_upright_turn_for_every_orientation() {
        let (w, h) = (7, 5);
        let stored = coded(w, h);
        for orientation in 1..=8u16 {
            let upright = turn_upright(stored.clone(), orientation);
            assert_eq!(upright.dimensions(), upright_size(orientation, w, h));
            let (uw, uh) = upright.dimensions();
            for side in 1..=uw.min(uh) {
                for top in 0..=uh - side {
                    for left in 0..=uw - side {
                        let rect = CropRect { left, top, side };
                        let in_stored = crop_of(&stored, rect.to_stored(orientation, w, h));
                        assert_eq!(
                            turn_upright(in_stored, orientation),
                            crop_of(&upright, rect),
                            "orientation {orientation}, {rect:?}"
                        );
                    }
                }
            }
        }
    }

    #[test]
    fn an_unknown_orientation_is_upright() {
        let rect = CropRect {
            left: 1,
            top: 2,
            side: 3,
        };
        for orientation in [0, 9, 300] {
            assert_eq!(rect.to_stored(orientation, 10, 10), rect);
            assert_eq!(upright_size(orientation, 4, 2), (4, 2));
        }
    }

    #[test]
    fn scaling_keeps_a_square_inside_the_picture() {
        let rect = CropRect {
            left: 4000,
            top: 0,
            side: 2000,
        };
        let scaled = rect.scaled((6000, 2000), (3000, 1000));
        assert_eq!(
            scaled,
            CropRect {
                left: 2000,
                top: 0,
                side: 1000
            }
        );
        assert_eq!(rect.scaled((6000, 2000), (6000, 2000)), rect);
        // Rounding never pushes the square out of the picture.
        let edge = CropRect {
            left: 4,
            top: 0,
            side: 3,
        };
        let s = edge.scaled((7, 3), (2, 1));
        assert!(s.left + s.side <= 2 && s.top + s.side <= 1, "{s:?}");
    }

    #[test]
    fn validation_rejects_empty_and_outside_rects_without_overflow() {
        let rect = |left, top, side| Some(CropRect { left, top, side });
        for bad in [
            rect(0, 0, 0),
            rect(0, 0, 101),
            rect(1, 0, 100),
            rect(0, 51, 50),
            rect(u32::MAX, 0, 2),
            rect(0, 0, u32::MAX),
        ] {
            assert!(
                matches!(normalise(bad, (100, 100)), Err(MediaError::Unsupported)),
                "{bad:?}"
            );
        }
        assert!(matches!(
            normalise(rect(0, 0, 51), (100, 50)),
            Err(MediaError::Unsupported)
        ));
        assert_eq!(normalise(None, (3, 3)).unwrap(), None);
    }

    #[test]
    fn only_the_whole_of_a_square_picture_normalises_to_no_crop() {
        let whole = Some(CropRect {
            left: 0,
            top: 0,
            side: 100,
        });
        assert_eq!(normalise(whole, (100, 100)).unwrap(), None);
        // A square the full height of a wide picture is a real crop.
        assert_eq!(normalise(whole, (200, 100)).unwrap(), whole);
        let inner = Some(CropRect {
            left: 1,
            top: 0,
            side: 99,
        });
        assert_eq!(normalise(inner, (100, 100)).unwrap(), inner);
    }

    #[test]
    fn random_rects_never_panic_and_stay_inside() {
        // Deterministic xorshift: no extra crate.
        let mut state = 0x9E37_79B9_7F4A_7C15u64;
        let mut next = |max: u32| {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            (state % u64::from(max)) as u32
        };
        for _ in 0..2000 {
            let (w, h) = (1 + next(300), 1 + next(300));
            let orientation = next(10) as u16;
            let (uw, uh) = upright_size(orientation, w, h);
            let side = 1 + next(uw.min(uh));
            let rect = CropRect {
                left: next(uw - side + 1),
                top: next(uh - side + 1),
                side,
            };
            let stored = rect.to_stored(orientation, w, h);
            assert!(stored.left + stored.side <= w && stored.top + stored.side <= h);
            let (dw, dh) = (1 + next(w), 1 + next(h));
            let s = stored.scaled((w, h), (dw, dh));
            assert!(s.side >= 1 && s.left + s.side <= dw && s.top + s.side <= dh);
        }
    }
}
