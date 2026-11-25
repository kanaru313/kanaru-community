use std::io::{self, Cursor, ErrorKind, Read, Seek, SeekFrom};

use lofty::config::ParsingMode;

use super::*;

fn options() -> ParseOptions {
    ParseOptions::new()
        .read_cover_art(false)
        .read_properties(false)
        .parsing_mode(ParsingMode::BestAttempt)
}

fn syncsafe(size: usize) -> [u8; 4] {
    [21, 14, 7, 0].map(|shift| ((size >> shift) & 0x7f) as u8)
}

fn frame(id: &[u8; 4], body: &[u8]) -> Vec<u8> {
    let mut bytes = id.to_vec();
    bytes.extend(syncsafe(body.len()));
    bytes.extend([0, 0]);
    bytes.extend_from_slice(body);
    bytes
}

/// An ID3v2.4 tag holding a `USLT` with `text`, then a frame lofty refuses.
fn broken_tag(text: &str) -> Vec<u8> {
    let mut body = b"\x03eng\x00".to_vec();
    body.extend_from_slice(text.as_bytes());
    let mut frames = frame(b"USLT", &body);
    frames.extend(frame(b"TXXX", b"\x09d\x00t"));
    let mut bytes = b"ID3\x04\x00\x00".to_vec();
    bytes.extend(syncsafe(frames.len()));
    bytes.extend(frames);
    bytes
}

/// A WAV of one `fmt ` chunk, a few silent samples and an `id3 ` chunk.
fn wav_with(tag: &[u8]) -> Vec<u8> {
    let mut fmt = Vec::new();
    for (value, len) in [(1u32, 2), (1, 2), (8000, 4), (16000, 4), (2, 2), (16, 2)] {
        fmt.extend_from_slice(&value.to_le_bytes()[..len]);
    }
    let mut body = b"WAVE".to_vec();
    for (id, data) in [
        (b"fmt ", fmt),
        (b"data", vec![0; 16]),
        (b"id3 ", tag.to_vec()),
    ] {
        body.extend_from_slice(id);
        body.extend((data.len() as u32).to_le_bytes());
        body.extend(&data);
        if data.len() % 2 == 1 {
            body.push(0);
        }
    }
    let mut bytes = b"RIFF".to_vec();
    bytes.extend((body.len() as u32).to_le_bytes());
    bytes.extend(body);
    bytes
}

/// `prefix`, then a FLAC stream of a last STREAMINFO block.
fn flac_behind(prefix: &[u8]) -> Vec<u8> {
    let mut bytes = prefix.to_vec();
    bytes.extend_from_slice(b"fLaC\x80\x00\x00\x22");
    bytes.extend_from_slice(&4096u16.to_be_bytes());
    bytes.extend_from_slice(&4096u16.to_be_bytes());
    bytes.extend_from_slice(&[0; 6]);
    let packed: u64 = (44_100u64 << 44) | (1u64 << 41) | (15u64 << 36) | 44_100u64;
    bytes.extend_from_slice(&packed.to_be_bytes());
    bytes.extend_from_slice(&[0; 16]);
    bytes
}

/// The bytes of `inner`, with every read from `at` on failing with `kind`.
struct FailAt {
    inner: Cursor<Vec<u8>>,
    at: u64,
    kind: ErrorKind,
}

impl FailAt {
    fn new(bytes: Vec<u8>, at: usize, kind: ErrorKind) -> Self {
        Self {
            inner: Cursor::new(bytes),
            at: at as u64,
            kind,
        }
    }
}

impl Read for FailAt {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        let pos = self.inner.position();
        if pos >= self.at {
            return Err(io::Error::from(self.kind));
        }
        let room = (self.at - pos).min(buf.len() as u64) as usize;
        self.inner.read(&mut buf[..room])
    }
}

impl Seek for FailAt {
    fn seek(&mut self, to: SeekFrom) -> io::Result<u64> {
        self.inner.seek(to)
    }
}

fn text(recovered: Recovered) -> Option<String> {
    recovered
        .expect("applies")
        .expect("no error")
        .and_then(|lyrics| lyrics.text)
}

#[test]
fn the_id3_chunk_of_a_wav_gives_its_lyrics() {
    let bytes = wav_with(&broken_tag("From the chunk"));
    let recovered = recover_wav(&mut Cursor::new(bytes), options());
    assert_eq!(text(recovered).as_deref(), Some("From the chunk"));
}

#[test]
fn a_wav_read_as_aiff_has_no_chunk_and_no_lyrics() {
    let bytes = wav_with(&broken_tag("Not here"));
    assert_eq!(
        recover_aiff(&mut Cursor::new(bytes), options()),
        Some(Ok(None))
    );
}

#[test]
fn a_transient_error_inside_an_id3_chunk_is_an_error() {
    let bytes = wav_with(&broken_tag("Lyrics"));
    let tag_at = bytes.windows(3).position(|w| w == b"ID3").expect("tag");
    let mut reader = FailAt::new(bytes.clone(), tag_at + 12, ErrorKind::TimedOut);
    assert_eq!(
        recover_wav(&mut reader, options()),
        Some(Err(MediaError::Io(ErrorKind::TimedOut)))
    );
    // Any other failure only means nothing was recovered.
    let mut reader = FailAt::new(bytes, tag_at + 12, ErrorKind::InvalidData);
    assert_eq!(recover_wav(&mut reader, options()), Some(Ok(None)));
}

#[test]
fn a_transient_error_inside_an_mp3_prefix_is_an_error() {
    let mut bytes = broken_tag("Lyrics");
    bytes.extend_from_slice(&[0xff, 0xfb, 0x90, 0x00]);
    let mut reader = FailAt::new(bytes, 12, ErrorKind::WouldBlock);
    assert_eq!(
        recover_mp3(&mut reader, options()),
        Some(Err(MediaError::Io(ErrorKind::WouldBlock)))
    );
}

#[test]
fn a_flac_without_a_prefix_is_not_recovered() {
    let bytes = flac_behind(&[]);
    assert_eq!(recover_flac(&mut Cursor::new(bytes), options()), None);
}

#[test]
fn a_flac_behind_a_prefix_without_lyrics_reads_as_a_flac_without_lyrics() {
    let mut tag = b"ID3\x04\x00\x00".to_vec();
    let frames = frame(b"TXXX", b"\x09d\x00t");
    tag.extend(syncsafe(frames.len()));
    tag.extend(frames);
    let bytes = flac_behind(&tag);
    assert_eq!(
        recover_flac(&mut Cursor::new(bytes), options()),
        Some(Ok(None))
    );
}

#[test]
fn the_prefix_lyrics_are_used_when_the_stream_does_not_read() {
    let tag = broken_tag("From the prefix");
    let mut bytes = flac_behind(&tag);
    // STREAMINFO is cut short: the stream head is found but does not read.
    bytes.truncate(tag.len() + 8 + 10);
    let recovered = recover_flac(&mut Cursor::new(bytes), options());
    assert_eq!(text(recovered).as_deref(), Some("From the prefix"));
}

#[test]
fn a_transient_error_while_reading_the_flac_stream_is_an_error() {
    let tag = broken_tag("Lyrics");
    let bytes = flac_behind(&tag);
    // The stream head is read, its STREAMINFO body fails.
    let at = tag.len() + 8 + 4;
    let mut reader = FailAt::new(bytes.clone(), at, ErrorKind::TimedOut);
    assert_eq!(
        recover_flac(&mut reader, options()),
        Some(Err(MediaError::Io(ErrorKind::TimedOut)))
    );
    // A lasting failure there falls back to the prefix.
    let mut reader = FailAt::new(bytes, at, ErrorKind::InvalidData);
    assert_eq!(
        text(recover_flac(&mut reader, options())).as_deref(),
        Some("Lyrics")
    );
}

#[test]
fn a_transient_error_at_the_flac_head_is_an_error() {
    let tag = broken_tag("Lyrics");
    let mut reader = FailAt::new(flac_behind(&tag), tag.len(), ErrorKind::TimedOut);
    assert_eq!(
        recover_flac(&mut reader, options()),
        Some(Err(MediaError::Io(ErrorKind::TimedOut)))
    );
}
