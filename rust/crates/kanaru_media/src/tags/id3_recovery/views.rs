//! Read + Seek views over an open file, so lofty can re-read a damaged file
//! without a copy of it in memory.
//!
//! - [`OffsetView`] starts the stream at an offset: lofty sees the file as if
//!   the bytes before it (a broken ID3v2 prefix) were not there.
//! - [`MaskedView`] reads a few 4-byte spots as `JUNK`: lofty then skips the
//!   chunks whose ids sit there (a broken `id3 ` chunk of a WAV or AIFF).
//!
//! Neither allocates per read.

use std::io::{self, Read, Seek, SeekFrom};

use super::MAX_ID3_CHUNKS;

/// What a masked chunk id reads as. WAV and AIFF readers skip unknown chunks.
#[cfg_attr(
    not(test),
    expect(
        dead_code,
        reason = "the tag recovery of the scan masks chunks; not wired in yet"
    )
)]
const MASK: &[u8; 4] = b"JUNK";

fn invalid_seek() -> io::Error {
    io::Error::new(
        io::ErrorKind::InvalidInput,
        "seek to a negative or overflowing position",
    )
}

/// `base + delta` as a stream position, or an `InvalidInput` error when it
/// is negative or past `u64::MAX`.
fn offset_position(base: u64, delta: i64) -> io::Result<u64> {
    base.checked_add_signed(delta).ok_or_else(invalid_seek)
}

/// The inner stream from `offset` on: position `p` of the view is position
/// `offset + p` of the inner stream; the end is the inner end. Seeking before
/// the start of the view is an `InvalidInput` error and leaves the position
/// where it was.
pub(crate) struct OffsetView<R> {
    inner: R,
    offset: u64,
    /// Position relative to `offset`.
    pos: u64,
}

impl<R: Seek> OffsetView<R> {
    /// A view of `inner` starting at `offset`, positioned at its start.
    pub(crate) fn new(mut inner: R, offset: u64) -> io::Result<Self> {
        inner.seek(SeekFrom::Start(offset))?;
        Ok(Self {
            inner,
            offset,
            pos: 0,
        })
    }

    /// Moves to `target` (relative to the view's start).
    fn seek_to(&mut self, target: u64) -> io::Result<u64> {
        let absolute = self.offset.checked_add(target).ok_or_else(invalid_seek)?;
        self.inner.seek(SeekFrom::Start(absolute))?;
        self.pos = target;
        Ok(target)
    }
}

impl<R: Read> Read for OffsetView<R> {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        let n = self.inner.read(buf)?;
        self.pos = self.pos.saturating_add(n as u64);
        Ok(n)
    }
}

impl<R: Seek> Seek for OffsetView<R> {
    fn seek(&mut self, to: SeekFrom) -> io::Result<u64> {
        let target = match to {
            SeekFrom::Start(n) => n,
            SeekFrom::Current(delta) => offset_position(self.pos, delta)?,
            SeekFrom::End(delta) => {
                let end = self.inner.seek(SeekFrom::End(0))?;
                // The inner stream moved: on a refused target, go back to
                // where the view was so the error leaves it unchanged.
                let target = offset_position(end, delta).and_then(|absolute| {
                    absolute.checked_sub(self.offset).ok_or_else(invalid_seek)
                });
                match target {
                    Ok(target) => target,
                    Err(e) => {
                        self.seek_to(self.pos)?;
                        return Err(e);
                    }
                }
            }
        };
        self.seek_to(target)
    }

    fn stream_position(&mut self) -> io::Result<u64> {
        Ok(self.pos)
    }
}

/// The inner stream with the 4 bytes at each mask offset read as `JUNK`,
/// also when a read covers only part of them. Seeks pass through.
#[cfg_attr(
    not(test),
    expect(
        dead_code,
        reason = "the tag recovery of the scan masks chunks; not wired in yet"
    )
)]
pub(crate) struct MaskedView<R> {
    inner: R,
    masks: [u64; MAX_ID3_CHUNKS],
    mask_count: usize,
    /// Position of the inner stream.
    pos: u64,
}

#[cfg_attr(
    not(test),
    expect(
        dead_code,
        reason = "the tag recovery of the scan masks chunks; not wired in yet"
    )
)]
impl<R: Seek> MaskedView<R> {
    /// A view of `inner` at its current position. At most
    /// [`MAX_ID3_CHUNKS`] masks; more is an `InvalidInput` error.
    pub(crate) fn new(mut inner: R, masks: &[u64]) -> io::Result<Self> {
        if masks.len() > MAX_ID3_CHUNKS {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "too many masked chunk ids",
            ));
        }
        let mut stored = [0u64; MAX_ID3_CHUNKS];
        stored[..masks.len()].copy_from_slice(masks);
        let pos = inner.stream_position()?;
        Ok(Self {
            inner,
            masks: stored,
            mask_count: masks.len(),
            pos,
        })
    }
}

impl<R: Read> Read for MaskedView<R> {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        let n = self.inner.read(buf)?;
        let start = self.pos;
        let end = start.saturating_add(n as u64);
        for &mask in &self.masks[..self.mask_count] {
            let mask_end = mask.saturating_add(MASK.len() as u64);
            // Every byte of [start, end) that falls in [mask, mask_end).
            for at in start.max(mask)..end.min(mask_end) {
                // Both differences are below `n` and below 4: no truncation.
                buf[(at - start) as usize] = MASK[(at - mask) as usize];
            }
        }
        self.pos = end;
        Ok(n)
    }
}

impl<R: Seek> Seek for MaskedView<R> {
    fn seek(&mut self, to: SeekFrom) -> io::Result<u64> {
        self.pos = self.inner.seek(to)?;
        Ok(self.pos)
    }

    fn stream_position(&mut self) -> io::Result<u64> {
        Ok(self.pos)
    }
}

#[cfg(test)]
mod tests {
    use std::io::Cursor;

    use super::*;

    fn bytes() -> Vec<u8> {
        (0u8..32).collect()
    }

    fn read_all(reader: &mut impl Read) -> Vec<u8> {
        let mut out = Vec::new();
        reader.read_to_end(&mut out).unwrap();
        out
    }

    #[test]
    fn an_offset_view_reads_from_its_offset() {
        let mut view = OffsetView::new(Cursor::new(bytes()), 10).unwrap();
        assert_eq!(view.stream_position().unwrap(), 0);
        let mut head = [0u8; 4];
        view.read_exact(&mut head).unwrap();
        assert_eq!(head, [10, 11, 12, 13]);
        assert_eq!(view.stream_position().unwrap(), 4);
        assert_eq!(read_all(&mut view), (14u8..32).collect::<Vec<_>>());
        assert_eq!(view.stream_position().unwrap(), 22);
    }

    #[test]
    fn an_offset_view_seeks_relative_to_its_offset() {
        let mut view = OffsetView::new(Cursor::new(bytes()), 10).unwrap();
        let mut one = [0u8; 1];
        assert_eq!(view.seek(SeekFrom::Start(5)).unwrap(), 5);
        view.read_exact(&mut one).unwrap();
        assert_eq!(one, [15]);
        assert_eq!(view.seek(SeekFrom::Current(-3)).unwrap(), 3);
        view.read_exact(&mut one).unwrap();
        assert_eq!(one, [13]);
        assert_eq!(view.seek(SeekFrom::End(0)).unwrap(), 22);
        assert_eq!(view.read(&mut one).unwrap(), 0);
        assert_eq!(view.seek(SeekFrom::End(-2)).unwrap(), 20);
        view.read_exact(&mut one).unwrap();
        assert_eq!(one, [30]);
        // Past the end is allowed, as for a file; reads give nothing.
        assert_eq!(view.seek(SeekFrom::Start(100)).unwrap(), 100);
        assert_eq!(view.read(&mut one).unwrap(), 0);
    }

    #[test]
    fn an_offset_view_refuses_a_seek_before_its_start_and_stays_put() {
        let mut view = OffsetView::new(Cursor::new(bytes()), 10).unwrap();
        view.seek(SeekFrom::Start(4)).unwrap();
        for to in [
            SeekFrom::Current(-5),
            SeekFrom::End(-23),
            SeekFrom::End(i64::MIN),
        ] {
            let error = view.seek(to).unwrap_err();
            assert_eq!(error.kind(), io::ErrorKind::InvalidInput, "{to:?}");
            assert_eq!(view.stream_position().unwrap(), 4, "{to:?}");
            let mut one = [0u8; 1];
            view.read_exact(&mut one).unwrap();
            assert_eq!(one, [14], "{to:?}");
            view.seek(SeekFrom::Start(4)).unwrap();
        }
    }

    #[test]
    fn an_offset_view_refuses_an_overflowing_seek() {
        let mut view = OffsetView::new(Cursor::new(bytes()), 10).unwrap();
        let error = view.seek(SeekFrom::Start(u64::MAX)).unwrap_err();
        assert_eq!(error.kind(), io::ErrorKind::InvalidInput);
        assert_eq!(view.stream_position().unwrap(), 0);
    }

    #[test]
    fn an_offset_view_past_the_end_reads_nothing() {
        let mut view = OffsetView::new(Cursor::new(bytes()), 40).unwrap();
        assert!(read_all(&mut view).is_empty());
        assert_eq!(view.read(&mut []).unwrap(), 0);
    }

    #[test]
    fn a_mask_inside_one_read_reads_as_junk() {
        let mut view = MaskedView::new(Cursor::new(bytes()), &[8]).unwrap();
        let out = read_all(&mut view);
        assert_eq!(&out[8..12], b"JUNK");
        assert_eq!(&out[..8], &bytes()[..8]);
        assert_eq!(&out[12..], &bytes()[12..]);
    }

    #[test]
    fn a_mask_split_across_reads_reads_as_junk() {
        for split in 1..4u64 {
            let mut view = MaskedView::new(Cursor::new(bytes()), &[8]).unwrap();
            let mut head = vec![0u8; (8 + split) as usize];
            view.read_exact(&mut head).unwrap();
            let tail = read_all(&mut view);
            let mut out = head;
            out.extend(tail);
            assert_eq!(&out[8..12], b"JUNK", "split after {split}");
            assert_eq!(&out[12..], &bytes()[12..], "split after {split}");
        }
    }

    #[test]
    fn a_read_inside_a_mask_gets_only_its_part() {
        let mut view = MaskedView::new(Cursor::new(bytes()), &[8]).unwrap();
        view.seek(SeekFrom::Start(9)).unwrap();
        let mut two = [0u8; 2];
        view.read_exact(&mut two).unwrap();
        assert_eq!(&two, b"UN");
        assert_eq!(view.stream_position().unwrap(), 11);
    }

    #[test]
    fn two_masks_and_a_mask_at_the_end_are_all_applied() {
        let mut view = MaskedView::new(Cursor::new(bytes()), &[0, 20, 30]).unwrap();
        let out = read_all(&mut view);
        assert_eq!(out.len(), 32);
        assert_eq!(&out[..4], b"JUNK");
        assert_eq!(&out[20..24], b"JUNK");
        // Only two of the last mask's bytes exist.
        assert_eq!(&out[30..], b"JU");
        assert_eq!(&out[4..20], &bytes()[4..20]);
    }

    #[test]
    fn a_mask_past_the_end_changes_nothing() {
        let mut view = MaskedView::new(Cursor::new(bytes()), &[100]).unwrap();
        assert_eq!(read_all(&mut view), bytes());
    }

    #[test]
    fn a_masked_view_starts_where_the_inner_stream_is_and_seeks_through() {
        let mut inner = Cursor::new(bytes());
        inner.seek(SeekFrom::Start(6)).unwrap();
        let mut view = MaskedView::new(inner, &[8]).unwrap();
        assert_eq!(view.stream_position().unwrap(), 6);
        let mut four = [0u8; 4];
        view.read_exact(&mut four).unwrap();
        assert_eq!(&four, &[6, 7, b'J', b'U']);
        assert_eq!(view.seek(SeekFrom::End(-1)).unwrap(), 31);
        assert_eq!(view.seek(SeekFrom::Current(-25)).unwrap(), 6);
        assert!(view.seek(SeekFrom::Current(-7)).is_err());
    }

    #[test]
    fn an_empty_read_changes_nothing() {
        let mut view = MaskedView::new(Cursor::new(bytes()), &[0]).unwrap();
        assert_eq!(view.read(&mut []).unwrap(), 0);
        assert_eq!(view.stream_position().unwrap(), 0);
        let mut four = [0u8; 4];
        view.read_exact(&mut four).unwrap();
        assert_eq!(&four, b"JUNK");
    }

    #[test]
    fn too_many_masks_are_refused() {
        let masks = [0u64; MAX_ID3_CHUNKS + 1];
        let error = MaskedView::new(Cursor::new(bytes()), &masks).err().unwrap();
        assert_eq!(error.kind(), io::ErrorKind::InvalidInput);
    }
}
