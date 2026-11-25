//! Where the ID3v2 tags at the start of an MP3 or FLAC file sit, and where
//! the audio after them starts. Sizes come from the tag headers only: no
//! forward scan for a mis-sized tag.

// The container recovery that skips these prefixes is not wired in yet;
// until then only the unit tests use them.
#![cfg_attr(
    not(test),
    expect(dead_code, reason = "used once the container recovery lands")
)]

use std::io::{self, Read, Seek, SeekFrom};

use super::bound::{declared_size, HEADER_LEN};
use super::{keep_found, non_transient, MAX_ID3_PREFIXES};
use crate::MediaError;

/// Length of an ID3v2.4 footer.
const FOOTER_LEN: u64 = 10;

/// Length of the STREAMINFO block body, the first metadata block of a FLAC
/// stream.
const STREAMINFO_LEN: u32 = 34;

/// One ID3v2 tag at the start of a file.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct PrefixSpan {
    /// Offset of the `ID3` header.
    pub at: u64,
    /// The body size the header declares (header and footer excluded).
    pub declared: u64,
    /// Offset right after the tag: header, declared body and footer.
    pub end: u64,
    /// The tag declares more bytes than the file holds. Its frames are
    /// still worth reading; nothing after it can be located.
    pub past_eof: bool,
}

/// The ID3v2 tags that follow each other from offset 0, each starting where
/// the last one ends, at most [`MAX_ID3_PREFIXES`]. The walk stops at bytes
/// that are not an ID3v2.2–2.4 header and after a tag that runs past the end
/// of the file. Leaves the stream position unspecified.
///
/// `Err` only for a transient I/O error; any other read failure ends the
/// walk with the tags found.
pub(crate) fn id3_prefixes<R: Read + Seek>(reader: &mut R) -> Result<Vec<PrefixSpan>, MediaError> {
    let mut found = Vec::new();
    let walked = walk(reader, &mut found);
    keep_found(walked, found)
}

fn walk<R: Read + Seek>(reader: &mut R, found: &mut Vec<PrefixSpan>) -> io::Result<()> {
    let len = reader.seek(SeekFrom::End(0))?;
    let mut at = 0u64;
    while found.len() < MAX_ID3_PREFIXES {
        reader.seek(SeekFrom::Start(at))?;
        let mut header = [0u8; HEADER_LEN];
        reader.read_exact(&mut header)?;
        if &header[..3] != b"ID3" || !(2..=4).contains(&header[3]) {
            break;
        }
        // At most 256 MiB (28 bits): the additions below cannot overflow
        // for an `at` that lies inside the file, checked all the same.
        let declared = declared_size(&header) as u64;
        let footer = if header[3] == 4 && header[5] & 0x10 != 0 {
            FOOTER_LEN
        } else {
            0
        };
        let Some(end) = at
            .checked_add(HEADER_LEN as u64 + footer)
            .and_then(|n| n.checked_add(declared))
        else {
            break;
        };
        let past_eof = end > len;
        found.push(PrefixSpan {
            at,
            declared,
            end,
            past_eof,
        });
        if past_eof {
            break;
        }
        at = end;
    }
    Ok(())
}

/// Where the audio after the prefixes starts: the end of the last one.
/// `None` without prefixes or when the last one runs past the end of the
/// file.
pub(crate) fn audio_start(prefixes: &[PrefixSpan]) -> Option<u64> {
    prefixes.last().filter(|p| !p.past_eof).map(|p| p.end)
}

/// Where the FLAC stream starts after the prefixes: [`audio_start`], when
/// `fLaC` sits exactly there followed by a STREAMINFO block header (type 0,
/// any last-block flag, length 34). Otherwise `None`, also when the file
/// ends inside those 8 bytes. Leaves the stream position unspecified.
///
/// `Err` only for a transient I/O error.
pub(crate) fn flac_start<R: Read + Seek>(
    reader: &mut R,
    prefixes: &[PrefixSpan],
) -> Result<Option<u64>, MediaError> {
    let Some(start) = audio_start(prefixes) else {
        return Ok(None);
    };
    let mut head = [0u8; 8];
    let read = reader
        .seek(SeekFrom::Start(start))
        .and_then(|_| reader.read_exact(&mut head));
    if let Err(e) = read {
        return non_transient(MediaError::from(e));
    }
    let block_len = u32::from_be_bytes([0, head[5], head[6], head[7]]);
    let is_flac = &head[..4] == b"fLaC" && head[4] & 0x7f == 0 && block_len == STREAMINFO_LEN;
    Ok(is_flac.then_some(start))
}

#[cfg(test)]
mod tests;
