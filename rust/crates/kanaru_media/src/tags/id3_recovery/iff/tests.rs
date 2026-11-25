use std::io::{self, Cursor, Read, Seek, SeekFrom};

use super::*;

/// One chunk: its fourcc, the size its header declares and its body bytes
/// (no pad byte; add it as a separate raw piece where a test wants one).
fn chunk(kind: Iff, id: &[u8; 4], declared: u32, body: &[u8]) -> Vec<u8> {
    let mut bytes = id.to_vec();
    bytes.extend(match kind {
        Iff::Riff => declared.to_le_bytes(),
        Iff::Form => declared.to_be_bytes(),
    });
    bytes.extend_from_slice(body);
    bytes
}

/// A chunk whose declared size is its body length.
fn whole(kind: Iff, id: &[u8; 4], body: &[u8]) -> Vec<u8> {
    chunk(kind, id, body.len() as u32, body)
}

/// A file of `kind` (`form_type` `WAVE`, `AIFF` or `AIFC`) declaring
/// `outer_size`, with `pieces` after the outer header.
fn file(kind: Iff, form_type: &[u8; 4], outer_size: u32, pieces: &[Vec<u8>]) -> Vec<u8> {
    let mut bytes = match kind {
        Iff::Riff => b"RIFF".to_vec(),
        Iff::Form => b"FORM".to_vec(),
    };
    bytes.extend(match kind {
        Iff::Riff => outer_size.to_le_bytes(),
        Iff::Form => outer_size.to_be_bytes(),
    });
    bytes.extend_from_slice(form_type);
    for piece in pieces {
        bytes.extend_from_slice(piece);
    }
    bytes
}

/// A WAV declaring its real size.
fn riff(pieces: &[Vec<u8>]) -> Vec<u8> {
    let len: usize = pieces.iter().map(Vec::len).sum();
    file(Iff::Riff, b"WAVE", len as u32 + 4, pieces)
}

/// An AIFF declaring its real size.
fn form(form_type: &[u8; 4], pieces: &[Vec<u8>]) -> Vec<u8> {
    let len: usize = pieces.iter().map(Vec::len).sum();
    file(Iff::Form, form_type, len as u32 + 4, pieces)
}

fn spans(bytes: Vec<u8>, kind: Iff) -> Vec<ChunkSpan> {
    id3_chunks(&mut Cursor::new(bytes), kind).unwrap()
}

fn span(header_at: u64, body_len: u64) -> ChunkSpan {
    ChunkSpan {
        header_at,
        body_at: header_at + 8,
        body_len,
    }
}

const FMT: &[u8] = &[0u8; 16];

#[test]
fn an_id3_chunk_after_the_audio_of_a_wav_is_found() {
    let bytes = riff(&[
        whole(Iff::Riff, b"fmt ", FMT),
        whole(Iff::Riff, b"data", &[7u8; 40]),
        whole(Iff::Riff, b"id3 ", b"ID3tag"),
    ]);
    assert_eq!(spans(bytes, Iff::Riff), vec![span(12 + 24 + 48, 6)]);
}

#[test]
fn an_id3_chunk_of_an_aiff_or_aifc_is_found_with_big_endian_sizes() {
    for form_type in [b"AIFF", b"AIFC"] {
        let bytes = form(
            form_type,
            &[
                whole(Iff::Form, b"COMM", &[0u8; 18]),
                whole(Iff::Form, b"SSND", &[1u8; 300]),
                whole(Iff::Form, b"ID3 ", b"ID3tag"),
            ],
        );
        let expected = vec![span(12 + 26 + 308, 6)];
        assert_eq!(spans(bytes.clone(), Iff::Form), expected);
        // Not a RIFF file.
        assert!(spans(bytes, Iff::Riff).is_empty());
    }
}

#[test]
fn both_spellings_are_found_in_both_containers() {
    for kind in [Iff::Riff, Iff::Form] {
        let pieces = [whole(kind, b"ID3 ", b"ab"), whole(kind, b"id3 ", b"cd")];
        let bytes = match kind {
            Iff::Riff => riff(&pieces),
            Iff::Form => form(b"AIFF", &pieces),
        };
        assert_eq!(spans(bytes, kind), vec![span(12, 2), span(22, 2)]);
    }
}

#[test]
fn an_odd_chunk_is_followed_by_its_pad_byte() {
    let bytes = riff(&[
        whole(Iff::Riff, b"LIST", b"abc"),
        vec![0],
        whole(Iff::Riff, b"id3 ", b"tag"),
    ]);
    assert_eq!(spans(bytes, Iff::Riff), vec![span(12 + 12, 3)]);
}

#[test]
fn an_odd_chunk_without_a_pad_byte_is_followed_by_the_next_chunk() {
    let bytes = riff(&[
        whole(Iff::Riff, b"LIST", b"abc"),
        whole(Iff::Riff, b"id3 ", b"tag"),
    ]);
    assert_eq!(spans(bytes, Iff::Riff), vec![span(12 + 11, 3)]);
}

#[test]
fn a_non_zero_pad_byte_that_starts_no_fourcc_is_skipped() {
    let bytes = riff(&[
        whole(Iff::Riff, b"LIST", b"abc"),
        vec![0xff],
        whole(Iff::Riff, b"id3 ", b"tag"),
    ]);
    assert_eq!(spans(bytes, Iff::Riff), vec![span(12 + 12, 3)]);
}

#[test]
fn an_odd_id3_chunk_at_the_end_of_the_file_is_found() {
    let bytes = riff(&[
        whole(Iff::Riff, b"data", b"ab"),
        whole(Iff::Riff, b"id3 ", b"tag"),
    ]);
    assert_eq!(spans(bytes, Iff::Riff), vec![span(22, 3)]);
}

#[test]
fn an_empty_id3_chunk_is_skipped_and_the_walk_goes_on() {
    let bytes = riff(&[
        whole(Iff::Riff, b"id3 ", b""),
        whole(Iff::Riff, b"ID3 ", b"tag"),
    ]);
    assert_eq!(spans(bytes, Iff::Riff), vec![span(20, 3)]);
}

#[test]
fn a_truncated_id3_chunk_yields_the_bytes_held() {
    let bytes = riff(&[
        whole(Iff::Riff, b"data", b"ab"),
        chunk(Iff::Riff, b"id3 ", 1000, b"tag"),
    ]);
    assert_eq!(spans(bytes, Iff::Riff), vec![span(22, 3)]);
}

#[test]
fn a_chunk_larger_than_the_rest_of_the_file_ends_the_walk() {
    // lofty stops there too, so it never reads the ID3 chunk after it.
    let bytes = riff(&[
        chunk(Iff::Riff, b"data", 1000, b"ab"),
        whole(Iff::Riff, b"id3 ", b"tag"),
    ]);
    assert!(spans(bytes, Iff::Riff).is_empty());
}

#[test]
fn the_declared_outer_size_is_ignored() {
    let pieces = [
        whole(Iff::Riff, b"data", b"ab"),
        whole(Iff::Riff, b"id3 ", b"tag"),
    ];
    for outer_size in [0, 8, u32::MAX] {
        let bytes = file(Iff::Riff, b"WAVE", outer_size, &pieces);
        assert_eq!(spans(bytes, Iff::Riff), vec![span(22, 3)], "{outer_size}");
    }
}

#[test]
fn an_invalid_fourcc_ends_the_walk() {
    for bad in [*b"\0\x01\x02\x03", *b" abc", *b"a bc"] {
        let bytes = riff(&[
            whole(Iff::Riff, &bad, b"ab"),
            whole(Iff::Riff, b"id3 ", b"tag"),
        ]);
        assert!(spans(bytes, Iff::Riff).is_empty(), "{bad:?}");
    }
    assert!(valid_fourcc(*b"ab  "));
    assert!(valid_fourcc(*b"    "));
}

#[test]
fn an_id3_subchunk_inside_a_list_is_not_reported() {
    let mut list = b"INFO".to_vec();
    list.extend(whole(Iff::Riff, b"id3 ", b"tag!"));
    let bytes = riff(&[
        whole(Iff::Riff, b"LIST", &list),
        whole(Iff::Riff, b"data", b"ab"),
    ]);
    assert!(spans(bytes, Iff::Riff).is_empty());
}

#[test]
fn at_most_the_id3_chunk_cap_is_reported() {
    let pieces = vec![whole(Iff::Riff, b"id3 ", b"ab"); MAX_ID3_CHUNKS + 1];
    let found = spans(riff(&pieces), Iff::Riff);
    assert_eq!(found.len(), MAX_ID3_CHUNKS);
    assert_eq!(found[MAX_ID3_CHUNKS - 1], span(12 + 10 * 3, 2));
}

#[test]
fn a_flood_of_empty_chunks_is_walked_up_to_the_chunk_cap() {
    let junk = whole(Iff::Riff, b"JUNK", b"");
    let mut pieces = vec![junk.clone(); MAX_IFF_CHUNKS - 1];
    pieces.push(whole(Iff::Riff, b"id3 ", b"ab"));
    assert_eq!(spans(riff(&pieces), Iff::Riff).len(), 1);
    // One more header before it: the ID3 chunk is past the cap.
    let mut pieces = vec![junk; 100_000];
    pieces.insert(MAX_IFF_CHUNKS, whole(Iff::Riff, b"id3 ", b"ab"));
    assert!(spans(riff(&pieces), Iff::Riff).is_empty());
}

#[test]
fn a_maximal_chunk_size_does_not_overflow() {
    for kind in [Iff::Riff, Iff::Form] {
        let pieces = [chunk(kind, b"id3 ", u32::MAX, b"tag")];
        let bytes = match kind {
            Iff::Riff => riff(&pieces),
            Iff::Form => form(b"AIFF", &pieces),
        };
        assert_eq!(spans(bytes, kind), vec![span(12, 3)]);
    }
}

#[test]
fn a_file_that_is_not_of_the_kind_has_no_chunks() {
    let id3 = whole(Iff::Riff, b"id3 ", b"tag");
    assert!(spans(
        file(Iff::Riff, b"AVI ", 0, std::slice::from_ref(&id3)),
        Iff::Riff
    )
    .is_empty());
    assert!(spans(
        file(Iff::Form, b"8SVX", 0, std::slice::from_ref(&id3)),
        Iff::Form
    )
    .is_empty());
    assert!(spans(b"RIFF".to_vec(), Iff::Riff).is_empty());
    assert!(spans(Vec::new(), Iff::Riff).is_empty());
}

#[test]
fn a_file_ending_inside_a_header_keeps_the_chunks_found() {
    let mut bytes = riff(&[whole(Iff::Riff, b"id3 ", b"ab")]);
    bytes.extend_from_slice(b"dat");
    assert_eq!(spans(bytes, Iff::Riff), vec![span(12, 2)]);
}

/// A reader that counts the bytes read, and fails every read with `fail`
/// once `fail_after` bytes were read.
struct Counting {
    inner: Cursor<Vec<u8>>,
    read: usize,
    fail_after: Option<(usize, io::ErrorKind)>,
}

impl Counting {
    fn new(bytes: Vec<u8>) -> Self {
        Self {
            inner: Cursor::new(bytes),
            read: 0,
            fail_after: None,
        }
    }
}

impl Read for Counting {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        if let Some((after, kind)) = self.fail_after {
            if self.read >= after {
                return Err(io::Error::from(kind));
            }
        }
        let n = self.inner.read(buf)?;
        self.read += n;
        Ok(n)
    }
}

impl Seek for Counting {
    fn seek(&mut self, to: SeekFrom) -> io::Result<u64> {
        self.inner.seek(to)
    }
}

#[test]
fn only_headers_and_pad_probes_are_read() {
    let bytes = riff(&[
        whole(Iff::Riff, b"fmt ", FMT),
        whole(Iff::Riff, b"data", &vec![7u8; 1_000_000]),
        whole(Iff::Riff, b"LIST", &[1u8; 501]),
        vec![0],
        whole(Iff::Riff, b"bext", &[2u8; 99]),
        whole(Iff::Riff, b"id3 ", &[3u8; 5000]),
    ]);
    let mut reader = Counting::new(bytes);
    assert_eq!(
        id3_chunks(&mut reader, Iff::Riff).unwrap(),
        vec![span(12 + 24 + 1_000_008 + 510 + 107, 5000)]
    );
    // Outer header, five chunk headers, one pad byte, then one pad probe of
    // four bytes (`bext` is odd and `id3 ` follows it with no pad).
    assert_eq!(reader.read, 12 + 5 * 8 + 1 + 4);
}

#[test]
fn a_transient_read_error_is_an_error_and_any_other_ends_the_walk() {
    let bytes = riff(&[
        whole(Iff::Riff, b"id3 ", b"ab"),
        whole(Iff::Riff, b"id3 ", b"cd"),
    ]);
    let mut reader = Counting::new(bytes.clone());
    reader.fail_after = Some((12 + 8, io::ErrorKind::TimedOut));
    assert_eq!(
        id3_chunks(&mut reader, Iff::Riff),
        Err(MediaError::Io(io::ErrorKind::TimedOut))
    );
    let mut reader = Counting::new(bytes);
    reader.fail_after = Some((12 + 8, io::ErrorKind::InvalidData));
    assert_eq!(id3_chunks(&mut reader, Iff::Riff), Ok(vec![span(12, 2)]));
}
