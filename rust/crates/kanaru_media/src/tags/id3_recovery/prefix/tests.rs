use std::io::{self, Cursor};

use super::*;

/// An ID3v2 tag of version `major` with header `flags`, declaring
/// `declared` body bytes and holding `held` of them (plus a footer when the
/// v2.4 footer flag is set and the whole body is held).
fn tag(major: u8, flags: u8, declared: usize, held: usize) -> Vec<u8> {
    let mut bytes = vec![b'I', b'D', b'3', major, 0, flags];
    bytes.extend([21, 14, 7, 0].map(|shift| ((declared >> shift) & 0x7f) as u8));
    bytes.resize(bytes.len() + held, b'x');
    if major == 4 && flags & 0x10 != 0 && held == declared {
        bytes.extend_from_slice(b"3DI\x04\x00\x10\0\0\0\0");
    }
    bytes
}

/// A FLAC stream head: `fLaC` and a last-block STREAMINFO header.
fn flac_head() -> Vec<u8> {
    let mut bytes = b"fLaC\x80\x00\x00\x22".to_vec();
    bytes.resize(bytes.len() + 34, 0);
    bytes
}

fn prefixes(bytes: &[u8]) -> Vec<PrefixSpan> {
    id3_prefixes(&mut Cursor::new(bytes)).unwrap()
}

fn span(at: u64, declared: u64, end: u64) -> PrefixSpan {
    PrefixSpan {
        at,
        declared,
        end,
        past_eof: false,
    }
}

fn flac(bytes: Vec<u8>) -> Option<u64> {
    let mut reader = Cursor::new(bytes);
    let found = id3_prefixes(&mut reader).unwrap();
    flac_start(&mut reader, &found).unwrap()
}

#[test]
fn a_single_prefix_is_found() {
    let mut bytes = tag(3, 0, 20, 20);
    bytes.extend_from_slice(b"\xff\xfbaudio");
    let found = prefixes(&bytes);
    assert_eq!(found, vec![span(0, 20, 30)]);
    assert_eq!(audio_start(&found), Some(30));
}

#[test]
fn a_v24_footer_is_part_of_the_prefix() {
    let mut bytes = tag(4, 0x10, 20, 20);
    bytes.extend(flac_head());
    assert_eq!(prefixes(&bytes), vec![span(0, 20, 40)]);
    assert_eq!(flac(bytes), Some(40));
    // The footer flag means nothing before v2.4.
    let mut bytes = tag(3, 0x10, 20, 20);
    bytes.extend(flac_head());
    assert_eq!(flac(bytes), Some(30));
}

#[test]
fn two_prefixes_in_a_row_are_found() {
    let mut bytes = tag(3, 0, 5, 5);
    bytes.extend(tag(4, 0, 7, 7));
    bytes.extend(flac_head());
    assert_eq!(prefixes(&bytes), vec![span(0, 5, 15), span(15, 7, 32)]);
    assert_eq!(flac(bytes), Some(32));
}

#[test]
fn at_most_the_prefix_cap_is_walked() {
    let mut bytes = tag(3, 0, 2, 2).repeat(MAX_ID3_PREFIXES + 1);
    bytes.extend(flac_head());
    let found = prefixes(&bytes);
    assert_eq!(found.len(), MAX_ID3_PREFIXES);
    // The audio start is the end of the last prefix walked: the fifth
    // prefix sits there, not `fLaC`.
    assert_eq!(audio_start(&found), Some(12 * MAX_ID3_PREFIXES as u64));
    assert_eq!(flac(bytes), None);
}

#[test]
fn an_unknown_version_ends_the_walk() {
    for major in [0u8, 1, 5, 0xff] {
        assert!(prefixes(&tag(major, 0, 2, 2)).is_empty(), "v2.{major}");
    }
    let mut bytes = tag(2, 0, 2, 2);
    bytes.extend(tag(0xff, 0, 2, 2));
    assert_eq!(prefixes(&bytes), vec![span(0, 2, 12)]);
}

#[test]
fn a_file_without_a_prefix_has_none() {
    assert!(prefixes(&flac_head()).is_empty());
    assert!(prefixes(b"ID3").is_empty());
    assert!(prefixes(b"").is_empty());
    assert_eq!(audio_start(&[]), None);
    assert_eq!(flac(flac_head()), None);
}

#[test]
fn a_prefix_declared_past_the_end_is_kept_and_ends_the_walk() {
    let declared = 250 * 1024 * 1024;
    let mut bytes = tag(4, 0, declared, 30);
    bytes.extend(flac_head());
    let found = prefixes(&bytes);
    assert_eq!(
        found,
        vec![PrefixSpan {
            at: 0,
            declared: declared as u64,
            end: 10 + declared as u64,
            past_eof: true,
        }]
    );
    assert_eq!(audio_start(&found), None);
    assert_eq!(flac(bytes), None);
}

#[test]
fn flac_must_start_exactly_at_the_end_of_the_prefixes() {
    let mut early = tag(3, 0, 20, 20);
    early.pop();
    early.extend(flac_head());
    assert_eq!(flac(early), None);
    let mut late = tag(3, 0, 20, 20);
    late.push(0);
    late.extend(flac_head());
    assert_eq!(flac(late), None);
}

#[test]
fn flac_must_open_with_a_streaminfo_block() {
    let with_head = |head: &[u8]| {
        let mut bytes = tag(3, 0, 4, 4);
        bytes.extend_from_slice(head);
        bytes.resize(bytes.len() + 34, 0);
        flac(bytes)
    };
    assert_eq!(with_head(b"fLaC\x00\x00\x00\x22"), Some(14));
    // A PADDING block first, a wrong length, no `fLaC`.
    assert_eq!(with_head(b"fLaC\x01\x00\x00\x22"), None);
    assert_eq!(with_head(b"fLaC\x00\x00\x00\x21"), None);
    assert_eq!(with_head(b"fLaC\x00\x01\x00\x22"), None);
    assert_eq!(with_head(b"OggS\x00\x00\x00\x22"), None);
}

#[test]
fn a_file_ending_inside_the_flac_head_has_no_flac_start() {
    let mut bytes = tag(3, 0, 4, 4);
    bytes.extend_from_slice(b"fLaC\x80\x00\x00");
    assert_eq!(flac(bytes), None);
}

/// A reader whose reads fail with `kind`.
struct Failing(io::ErrorKind);

impl Read for Failing {
    fn read(&mut self, _: &mut [u8]) -> io::Result<usize> {
        Err(io::Error::from(self.0))
    }
}

impl Seek for Failing {
    fn seek(&mut self, _: SeekFrom) -> io::Result<u64> {
        Ok(100)
    }
}

#[test]
fn a_transient_read_error_is_an_error_and_any_other_is_nothing() {
    let timed_out = Err(MediaError::Io(io::ErrorKind::TimedOut));
    let found = [span(0, 2, 12)];
    assert_eq!(
        id3_prefixes(&mut Failing(io::ErrorKind::TimedOut)),
        timed_out
    );
    assert_eq!(
        flac_start(&mut Failing(io::ErrorKind::TimedOut), &found),
        Err(MediaError::Io(io::ErrorKind::TimedOut))
    );
    let lasting = io::ErrorKind::InvalidData;
    assert_eq!(id3_prefixes(&mut Failing(lasting)), Ok(vec![]));
    assert_eq!(flac_start(&mut Failing(lasting), &found), Ok(None));
}
