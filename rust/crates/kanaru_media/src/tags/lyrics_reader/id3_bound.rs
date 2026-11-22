//! Cuts the ID3v2 tag copy handed to symphonia down to the part worth
//! parsing, so a hostile tag cannot make it allocate, loop or log without
//! limit. A pure function of the bytes: no I/O, no symphonia.
//!
//! Frames are walked by their on-disk sizes: after the last of at most
//! [`MAX_ID3_FALLBACK_FRAMES`] frames, before the first empty frame, padding
//! or frame header that does not fit.

/// Most frames the fallback looks at. Lyrics frames sit near the start of a
/// tag; the cap keeps a tag of millions of tiny frames cheap.
pub const MAX_ID3_FALLBACK_FRAMES: usize = 1024;

/// Length of the ID3v2 tag header.
pub(super) const HEADER_LEN: usize = 10;

/// The tag size in header bytes 6-9 (syncsafe: 7 bits per byte).
pub(super) fn declared_size(header: &[u8]) -> usize {
    header[6..10]
        .iter()
        .fold(0usize, |size, byte| (size << 7) | usize::from(byte & 0x7f))
}

/// Writes `size` as the syncsafe tag size of `tag`'s header.
fn set_declared_size(tag: &mut [u8], size: usize) {
    for (i, byte) in tag[6..10].iter_mut().enumerate() {
        *byte = ((size >> (7 * (3 - i))) & 0x7f) as u8;
    }
}

/// `tag` (header + the body bytes read) cut down to what the fallback will
/// parse, with the declared size lowered to match so every size check inside
/// symphonia is against bytes that exist. Never raises the declared size.
///
/// 1. The size is lowered to the bytes held.
/// 2. A tag-level unsynchronisation (ID3v2.3 and older) is undone in our copy
///    and its flag cleared, so frame sizes can be walked on plain bytes.
/// 3. The frames are walked by their on-disk sizes and the tag ends where the
///    walk stops (see [`walk_end`]).
pub(super) fn bound_tag(mut tag: Vec<u8>) -> Vec<u8> {
    let held = tag.len() - HEADER_LEN;
    if held < declared_size(&tag) {
        set_declared_size(&mut tag, held);
    }
    let major = tag[3];
    if major < 4 && tag[5] & 0x80 != 0 {
        let body = undo_unsynchronisation(&tag[HEADER_LEN..]);
        tag.truncate(HEADER_LEN);
        tag.extend_from_slice(&body);
        tag[5] &= !0x80;
        set_declared_size(&mut tag, body.len());
    }
    let end = walk_end(major, tag[5], &tag[HEADER_LEN..]);
    tag.truncate(HEADER_LEN + end);
    set_declared_size(&mut tag, end);
    tag
}

/// `body` with the `00` that follows each `FF` removed.
fn undo_unsynchronisation(body: &[u8]) -> Vec<u8> {
    let mut plain = Vec::with_capacity(body.len());
    let mut bytes = body.iter().peekable();
    while let Some(&byte) = bytes.next() {
        plain.push(byte);
        if byte == 0xff && bytes.peek() == Some(&&0) {
            bytes.next();
        }
    }
    plain
}

/// Where the part of `body` worth parsing ends: after the last of at most
/// [`MAX_ID3_FALLBACK_FRAMES`] frames, stopping before the first frame that
/// is empty, starts with a zero byte (padding) or does not fit in `body`.
/// Frames are walked by their sizes on disk (per-frame unsynchronisation of
/// ID3v2.4 keeps the on-disk size). An unknown version is left whole:
/// symphonia refuses it at once.
fn walk_end(major: u8, flags: u8, body: &[u8]) -> usize {
    let header_len = match major {
        2 => 6,
        3 | 4 => 10,
        _ => return body.len(),
    };
    let mut pos = 0usize;
    if major >= 3 && flags & 0x40 != 0 {
        // v2.3: the size excludes its own four bytes; v2.4: it includes them.
        let Some(field) = body.get(..4) else {
            return 0;
        };
        let size = if major == 3 {
            4 + be_size(field)
        } else {
            syncsafe_size(field)
        };
        if size > body.len() {
            return 0;
        }
        pos = size;
    }
    let mut end = pos;
    for _ in 0..MAX_ID3_FALLBACK_FRAMES {
        let Some(header) = body.get(pos..pos + header_len) else {
            break;
        };
        if header[0] == 0 {
            break;
        }
        let size = match major {
            2 => be_size(&header[3..6]),
            3 => be_size(&header[4..8]),
            _ => syncsafe_size(&header[4..8]),
        };
        let next = pos.saturating_add(header_len).saturating_add(size);
        if size == 0 || next > body.len() {
            break;
        }
        pos = next;
        end = next;
    }
    end
}

fn be_size(bytes: &[u8]) -> usize {
    bytes.iter().fold(0usize, |n, b| (n << 8) | usize::from(*b))
}

fn syncsafe_size(bytes: &[u8]) -> usize {
    bytes
        .iter()
        .fold(0usize, |n, b| (n << 7) | usize::from(b & 0x7f))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tags::lyrics_reader::id3_fallback::MAX_ID3_FALLBACK_BYTES;

    fn header(major: u8, flags: u8, declared: usize) -> Vec<u8> {
        let mut bytes = vec![b'I', b'D', b'3', major, 0, flags];
        for shift in [21, 14, 7, 0] {
            bytes.push(((declared >> shift) & 0x7f) as u8);
        }
        bytes
    }

    /// A frame with `size_len` bytes of body, laid out for `major`.
    fn frame(major: u8, id: &str, size: usize, body_len: usize) -> Vec<u8> {
        let mut bytes = id.as_bytes().to_vec();
        match major {
            2 => bytes.extend_from_slice(&(size as u32).to_be_bytes()[1..]),
            3 => bytes.extend_from_slice(&(size as u32).to_be_bytes()),
            _ => bytes.extend((0..4).map(|i| ((size >> (7 * (3 - i))) & 0x7f) as u8)),
        }
        if major > 2 {
            bytes.extend_from_slice(&[0, 0]);
        }
        bytes.resize(bytes.len() + body_len, b'x');
        bytes
    }

    fn tag(major: u8, flags: u8, declared: usize, body: &[u8]) -> Vec<u8> {
        let mut bytes = header(major, flags, declared);
        bytes.extend_from_slice(body);
        bytes
    }

    #[test]
    fn declared_size_round_trips() {
        assert_eq!(declared_size(&header(4, 0, 0)), 0);
        assert_eq!(declared_size(&header(4, 0, 257)), 257);
        let big = 250 * 1024 * 1024;
        assert_eq!(declared_size(&header(4, 0, big)), big);
    }

    #[test]
    fn a_declared_size_above_the_bytes_held_is_lowered() {
        let body = frame(4, "TIT2", 3, 3);
        let bounded = bound_tag(tag(4, 0, 250 * 1024 * 1024, &body));
        assert_eq!(declared_size(&bounded), body.len());
        assert_eq!(&bounded[..6], b"ID3\x04\x00\x00");
    }

    #[test]
    fn a_tag_read_at_the_cap_declares_at_most_the_cap() {
        let mut body = frame(4, "TIT2", 3, 3);
        body.resize(MAX_ID3_FALLBACK_BYTES, b'x');
        let bounded = bound_tag(tag(4, 0, 250 * 1024 * 1024, &body));
        assert!(declared_size(&bounded) <= MAX_ID3_FALLBACK_BYTES);
    }

    #[test]
    fn a_declared_size_within_the_bytes_held_is_kept_up_to_the_last_frame() {
        let frames = frame(3, "TIT2", 3, 3);
        let mut body = frames.clone();
        body.extend_from_slice(&[0u8; 8]);
        let bounded = bound_tag(tag(3, 0, body.len(), &body));
        assert_eq!(declared_size(&bounded), frames.len());
    }

    #[test]
    fn the_walk_stops_before_the_first_empty_frame() {
        for major in [2u8, 3, 4] {
            let id = if major == 2 { "TT2" } else { "TIT2" };
            let first = frame(major, id, 2, 2);
            let mut body = first.clone();
            body.extend(frame(major, id, 0, 0));
            body.extend(frame(major, id, 2, 2));
            assert_eq!(walk_end(major, 0, &body), first.len(), "v2.{major}");
        }
    }

    #[test]
    fn the_walk_stops_at_padding() {
        let first = frame(4, "TIT2", 1, 1);
        let mut body = first.clone();
        body.extend_from_slice(&[0u8; 64]);
        assert_eq!(walk_end(4, 0, &body), first.len());
    }

    #[test]
    fn the_walk_looks_at_a_bounded_number_of_frames() {
        let one = frame(3, "TIT2", 1, 1);
        let body = one.repeat(MAX_ID3_FALLBACK_FRAMES * 3);
        assert_eq!(walk_end(3, 0, &body), one.len() * MAX_ID3_FALLBACK_FRAMES);
    }

    #[test]
    fn the_walk_stops_before_a_frame_that_does_not_fit() {
        let first = frame(4, "TIT2", 1, 1);
        let mut body = first.clone();
        body.extend(frame(4, "TIT2", 1000, 3));
        assert_eq!(walk_end(4, 0, &body), first.len());
        // A header cut short.
        let mut cut = first.clone();
        cut.extend_from_slice(b"TIT2\0");
        assert_eq!(walk_end(4, 0, &cut), first.len());
    }

    #[test]
    fn the_walk_skips_the_extended_header() {
        let first = frame(3, "TIT2", 1, 1);
        // v2.3: the size excludes its own four bytes.
        let mut body = 6u32.to_be_bytes().to_vec();
        body.extend_from_slice(&[0u8; 6]);
        body.extend(first.clone());
        assert_eq!(walk_end(3, 0x40, &body), 10 + first.len());
        // v2.4: the size includes its own four bytes.
        let mut body = vec![0, 0, 0, 6, 1, 0];
        body.extend(first.clone());
        assert_eq!(walk_end(4, 0x40, &body), 6 + first.len());
        // An extended header that does not fit leaves nothing.
        assert_eq!(walk_end(4, 0x40, &[0, 0, 0x7f, 0x7f, 1, 0]), 0);
    }

    #[test]
    fn an_unknown_version_is_left_whole() {
        assert_eq!(walk_end(5, 0, &[1, 2, 3]), 3);
    }

    #[test]
    fn tag_level_unsynchronisation_is_undone_and_its_flag_cleared() {
        let body = [0xff, 0x00, 0x41, 0xff, 0x00, 0x00];
        assert_eq!(undo_unsynchronisation(&body), vec![0xff, 0x41, 0xff, 0x00]);
        let plain = frame(3, "TIT2", 2, 2);
        let mut unsynced = plain.clone();
        unsynced.splice(10..12, [0xff, 0x00, 0x41]);
        let bounded = bound_tag(tag(3, 0x80, unsynced.len(), &unsynced));
        assert_eq!(bounded[5] & 0x80, 0);
        assert_eq!(bounded.len(), HEADER_LEN + declared_size(&bounded));
    }
}
