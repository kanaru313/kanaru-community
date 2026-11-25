//! WAV, AIFF and FLAC files with an ID3v2 tag where each container keeps
//! it: a top-level `id3 `/`ID3 ` chunk, or a prefix in front of `fLaC`.

use std::path::Path;

use super::{aiff_bytes, syncsafe, write_vorbis_key};
use crate::tags_fixtures::{flac_bytes, wav_bytes, TempDir};

/// An ID3v2.4 tag made of `frames`, declaring exactly their length or
/// `declared` when given, with nothing after it.
pub fn id3v2_tag(frames: &[Vec<u8>], declared: Option<usize>) -> Vec<u8> {
    let body: Vec<u8> = frames.concat();
    let mut bytes = b"ID3\x04\x00\x00".to_vec();
    bytes.extend_from_slice(&syncsafe(declared.unwrap_or(body.len())));
    bytes.extend_from_slice(&body);
    bytes
}

/// Like [`id3v2_tag`] with the v2.4 footer flag set and the footer written.
pub fn id3v2_tag_with_footer(frames: &[Vec<u8>]) -> Vec<u8> {
    let mut bytes = id3v2_tag(frames, None);
    bytes[5] = 0x10;
    let mut footer = bytes[..10].to_vec();
    footer[..3].copy_from_slice(b"3DI");
    bytes.extend(footer);
    bytes
}

/// Where extra chunks go in a WAV or AIFF.
#[derive(Clone, Copy, Debug)]
pub enum Place {
    /// Between the format chunk and the audio chunk.
    BeforeAudio,
    /// At the end of the file.
    AfterAudio,
}

/// The in-memory WAV with `chunks` (id, body) added at `place`, each padded
/// to an even size, and the RIFF size fixed.
pub fn wav_with_chunks(chunks: &[(&[u8; 4], &[u8])], place: Place) -> Vec<u8> {
    // RIFF header (12) and a 16-byte `fmt ` chunk (24).
    add_chunks(wav_bytes(), 36, chunks, place, u32::to_le_bytes)
}

/// The in-memory AIFF with `chunks` added at `place`, as [`wav_with_chunks`].
pub fn aiff_with_chunks(chunks: &[(&[u8; 4], &[u8])], place: Place) -> Vec<u8> {
    // FORM header (12) and an 18-byte `COMM` chunk (26).
    add_chunks(aiff_bytes(), 38, chunks, place, u32::to_be_bytes)
}

fn add_chunks(
    mut file: Vec<u8>,
    audio_at: usize,
    chunks: &[(&[u8; 4], &[u8])],
    place: Place,
    size: fn(u32) -> [u8; 4],
) -> Vec<u8> {
    let mut added = Vec::new();
    for (id, body) in chunks {
        added.extend_from_slice(*id);
        added.extend_from_slice(&size(body.len() as u32));
        added.extend_from_slice(body);
        if body.len() % 2 == 1 {
            added.push(0);
        }
    }
    let at = match place {
        Place::BeforeAudio => audio_at,
        Place::AfterAudio => file.len(),
    };
    file.splice(at..at, added);
    let outer = size(file.len() as u32 - 8);
    file[4..8].copy_from_slice(&outer);
    file
}

/// The in-memory FLAC with the Vorbis comments `comments` (raw keys).
pub fn flac_with_comments(comments: &[(&str, &str)]) -> Vec<u8> {
    let dir = TempDir::new();
    let path = dir.write("comments.flac", &flac_bytes());
    for (key, text) in comments {
        write_vorbis_key(&path, key, text);
    }
    std::fs::read(Path::new(&path)).expect("read FLAC")
}
