//! Where the ID3v2 chunks of a WAV (RIFF) or AIFF (FORM) file sit, found by
//! walking the top-level chunk headers the way lofty does, so a chunk masked
//! for a re-read is the chunk lofty would have parsed.
//!
//! Mirrors lofty's IFF chunk walk: the bound is the real stream length, not
//! the size the outer header declares (streamed WAVs declare 0 or
//! `0xFFFFFFFF`); an invalid fourcc or a chunk larger than what is left ends
//! the walk; an odd-sized chunk is followed by a pad byte unless the byte
//! there starts a valid fourcc. Only headers (and pad probes) are read:
//! chunk bodies, `data` and `SSND` included, are seeked over. `LIST` is not
//! entered: an ID3 chunk is a top-level chunk. After a damaged `LIST`/`INFO`
//! chunk lofty may lose its place, while this walker seeks to the end the
//! chunk declares; the tag fallback's second lofty read, with
//! `ParseOptions::read_tags(false)`, covers that case.

use std::io::{self, Read, Seek, SeekFrom};

use super::{keep_found, MAX_ID3_CHUNKS, MAX_IFF_CHUNKS};
use crate::MediaError;

/// Length of the outer `RIFF`/`FORM` header and of a chunk header.
const OUTER_LEN: u64 = 12;
const CHUNK_HEADER_LEN: u64 = 8;

/// The two IFF flavours lofty reads ID3 chunks from.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Iff {
    /// `RIFF`…`WAVE`, little-endian sizes.
    Riff,
    /// `FORM`…`AIFF`/`AIFC`, big-endian sizes.
    Form,
}

impl Iff {
    fn matches(self, outer: &[u8; 12]) -> bool {
        match self {
            Iff::Riff => &outer[..4] == b"RIFF" && &outer[8..] == b"WAVE",
            Iff::Form => &outer[..4] == b"FORM" && matches!(&outer[8..], b"AIFF" | b"AIFC"),
        }
    }

    fn size(self, bytes: [u8; 4]) -> u64 {
        u64::from(match self {
            Iff::Riff => u32::from_le_bytes(bytes),
            Iff::Form => u32::from_be_bytes(bytes),
        })
    }
}

/// One `id3 `/`ID3 ` chunk: where its header and body start, and how many
/// body bytes the file holds (the declared size, lowered to the bytes left
/// when the chunk is cut short by the end of the file).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct ChunkSpan {
    /// Offset of the chunk's fourcc.
    pub header_at: u64,
    pub body_at: u64,
    pub body_len: u64,
}

/// The non-empty ID3 chunks of a `kind` file, in file order, at most
/// [`MAX_ID3_CHUNKS`], from at most [`MAX_IFF_CHUNKS`] chunk headers. Not a
/// `kind` file: none. Leaves the stream position unspecified.
///
/// `Err` only for a transient I/O error; any other read failure (the file
/// ends inside a header or a pad probe) ends the walk with the chunks found.
pub(crate) fn id3_chunks<R: Read + Seek>(
    reader: &mut R,
    kind: Iff,
) -> Result<Vec<ChunkSpan>, MediaError> {
    let mut found = Vec::new();
    let walked = walk(reader, kind, &mut found);
    keep_found(walked, found)
}

fn walk<R: Read + Seek>(reader: &mut R, kind: Iff, found: &mut Vec<ChunkSpan>) -> io::Result<()> {
    let len = reader.seek(SeekFrom::End(0))?;
    reader.seek(SeekFrom::Start(0))?;
    let mut outer = [0u8; 12];
    reader.read_exact(&mut outer)?;
    if !kind.matches(&outer) {
        return Ok(());
    }
    let mut stream = Tracked {
        reader,
        pos: OUTER_LEN,
    };
    let mut at = OUTER_LEN;
    for _ in 0..MAX_IFF_CHUNKS {
        // `at` may sit past the end after a chunk that overran it by less
        // than its own header (lofty allows that too).
        let remaining = len.saturating_sub(at);
        if remaining < CHUNK_HEADER_LEN {
            break;
        }
        let mut header = [0u8; 8];
        stream.read_at(at, &mut header)?;
        let fourcc = [header[0], header[1], header[2], header[3]];
        if !valid_fourcc(fourcc) {
            break;
        }
        let size = kind.size([header[4], header[5], header[6], header[7]]);
        let body_at = at + CHUNK_HEADER_LEN;
        if matches!(&fourcc, b"id3 " | b"ID3 ") && size > 0 {
            found.push(ChunkSpan {
                header_at: at,
                body_at,
                body_len: size.min(len - body_at),
            });
            if found.len() == MAX_ID3_CHUNKS {
                break;
            }
        }
        // lofty compares the size with what is left from the header on.
        if size > remaining {
            break;
        }
        let Some(end) = body_at.checked_add(size) else {
            break;
        };
        at = if size % 2 == 1 {
            stream.after_pad(end, len)?
        } else {
            end
        };
    }
    Ok(())
}

/// lofty's fourcc rule: printable ASCII (`0x20..=0x7E`), spaces only at the
/// end.
fn valid_fourcc(fourcc: [u8; 4]) -> bool {
    let mut has_spaces = false;
    fourcc.iter().all(|&b| {
        if b == b' ' {
            has_spaces = true;
        }
        (0x20..=0x7e).contains(&b) && (!has_spaces || b == b' ')
    })
}

/// The reader and its known position, so reading the next header right
/// where the last read stopped does not seek (a seek drops a `BufReader`'s
/// buffer).
struct Tracked<'a, R> {
    reader: &'a mut R,
    pos: u64,
}

impl<R: Read + Seek> Tracked<'_, R> {
    fn read_at(&mut self, at: u64, buf: &mut [u8]) -> io::Result<()> {
        if self.pos != at {
            self.reader.seek(SeekFrom::Start(at))?;
            self.pos = at;
        }
        self.reader.read_exact(buf)?;
        self.pos = at + buf.len() as u64;
        Ok(())
    }

    /// Where the next chunk starts after an odd-sized chunk ending at `end`,
    /// as lofty decides it: a `0` there is a pad byte; a non-zero byte is a
    /// pad byte too unless it and the next three bytes form a valid fourcc
    /// (the encoder counted the pad in the size, or wrote none). At the end
    /// of the stream there is no pad.
    fn after_pad(&mut self, end: u64, len: u64) -> io::Result<u64> {
        let remaining = len.saturating_sub(end);
        if remaining < 1 {
            return Ok(end);
        }
        let mut probe = [0u8; 4];
        self.read_at(end, &mut probe[..1])?;
        if probe[0] != 0 && remaining > 4 {
            self.read_at(end + 1, &mut probe[1..])?;
            if valid_fourcc(probe) {
                return Ok(end);
            }
        }
        Ok(end + 1)
    }
}

#[cfg(test)]
mod tests;
