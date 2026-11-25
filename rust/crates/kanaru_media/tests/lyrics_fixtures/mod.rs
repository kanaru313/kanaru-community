//! Files for the lyrics reader tests. MP3, WAV, FLAC and AIFF are built in
//! memory; OGG, Opus, M4A and WavPack are tiny files made with ffmpeg
//! (`README.md` lists the commands). Tags are written with lofty into copies.
#![allow(dead_code)]

use std::borrow::Cow;
use std::fs::File;
use std::path::{Path, PathBuf};

use kanaru_media::tags::lyrics_reader::{read_lyrics, EmbeddedLyrics};
use kanaru_media::MediaError;
use lofty::config::WriteOptions;
use lofty::file::{AudioFile, TaggedFileExt};
use lofty::flac::FlacFile;
use lofty::id3::v2::{
    BinaryFrame, Frame, FrameId, Id3v2Tag, SyncTextContentType, SynchronizedTextFrame,
    TimestampFormat, UnsynchronizedTextFrame,
};
use lofty::ogg::tag::VorbisComments;
use lofty::ogg::{OpusFile, VorbisFile};
use lofty::tag::{ItemKey, Tag, TagExt};
use lofty::TextEncoding;

use crate::tags_fixtures::{flac_bytes, mp3_bytes, wav_bytes, TempDir};

mod containers;
pub use containers::*;

/// Names of the files made with ffmpeg and checked in.
pub const CHECKED_IN: [&str; 4] = ["sample.ogg", "sample.opus", "sample.m4a", "sample.wv"];

/// 4410 frames of 16-bit mono 44.1 kHz silence.
pub fn aiff_bytes() -> Vec<u8> {
    let data_len: u32 = 4410 * 2;
    let mut comm = Vec::new();
    comm.extend_from_slice(&1u16.to_be_bytes()); // channels
    comm.extend_from_slice(&4410u32.to_be_bytes()); // frames
    comm.extend_from_slice(&16u16.to_be_bytes());
    comm.extend_from_slice(&[0x40, 0x0E, 0xAC, 0x44, 0, 0, 0, 0, 0, 0]); // 44100 as f80
    let mut ssnd = vec![0u8; 8]; // offset and block size
    ssnd.resize(8 + data_len as usize, 0);
    let mut body = b"AIFF".to_vec();
    for (id, data) in [(b"COMM", &comm), (b"SSND", &ssnd)] {
        body.extend_from_slice(id);
        body.extend_from_slice(&(data.len() as u32).to_be_bytes());
        body.extend_from_slice(data);
    }
    let mut file = b"FORM".to_vec();
    file.extend_from_slice(&(body.len() as u32).to_be_bytes());
    file.extend_from_slice(&body);
    file
}

/// A writable, untagged `sample.<ext>` in `dir`.
pub fn sample(dir: &TempDir, name: &str) -> PathBuf {
    let bytes = match name {
        "sample.mp3" => mp3_bytes(),
        "sample.wav" => wav_bytes(),
        "sample.flac" => flac_bytes(),
        "sample.aiff" => aiff_bytes(),
        _ => {
            assert!(CHECKED_IN.contains(&name), "unknown fixture {name}");
            let source = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
                .join("tests/lyrics_fixtures")
                .join(name);
            let dest = dir.path(name);
            std::fs::copy(source, &dest).expect("copy fixture");
            return dest;
        }
    };
    dir.write(name, &bytes)
}

/// What a caller does before `read_lyrics`: open and pass the extension.
pub fn read(path: &Path) -> Result<Option<EmbeddedLyrics>, MediaError> {
    let ext = path.extension().and_then(|e| e.to_str());
    read_lyrics(File::open(path).expect("open"), ext)
}

/// Writes `text` under `key` into the file's primary tag (created if
/// missing), through lofty's generic tag.
pub fn write_generic(path: &Path, key: ItemKey, text: &str) {
    let tagged = lofty::read_from_path(path).expect("read fixture");
    let mut tag = tagged
        .primary_tag()
        .cloned()
        .unwrap_or_else(|| Tag::new(tagged.primary_tag_type()));
    assert!(tag.insert_text(key, text.to_owned()), "{path:?}");
    tag.save_to_path(path, WriteOptions::default())
        .expect("save tag");
}

/// A `SYLT` frame as lofty stores it: binary.
pub fn sylt(
    content_type: SyncTextContentType,
    format: TimestampFormat,
    lines: &[(u32, &str)],
) -> Frame<'static> {
    sylt_with(content_type, format, lines, |_| {})
}

/// Like [`sylt`], with `patch` applied to the encoded frame body.
pub fn sylt_with(
    content_type: SyncTextContentType,
    format: TimestampFormat,
    lines: &[(u32, &str)],
    patch: impl FnOnce(&mut Vec<u8>),
) -> Frame<'static> {
    let frame = SynchronizedTextFrame::new(
        TextEncoding::UTF8,
        *b"eng",
        format,
        content_type,
        None,
        lines.iter().map(|(t, s)| (*t, (*s).to_owned())).collect(),
    );
    let mut bytes = frame
        .as_bytes(WriteOptions::default())
        .expect("encode SYLT");
    patch(&mut bytes);
    Frame::Binary(BinaryFrame::new(
        FrameId::Valid(Cow::Borrowed("SYLT")),
        bytes,
    ))
}

/// A `USLT` frame, which lofty maps to `ItemKey::UnsyncLyrics`.
pub fn uslt(text: &str) -> Frame<'static> {
    Frame::UnsynchronizedText(UnsynchronizedTextFrame::new(
        TextEncoding::UTF8,
        *b"eng",
        String::new(),
        text.to_owned(),
    ))
}

pub fn write_id3v2(path: &Path, frames: Vec<Frame<'static>>) {
    let mut tag = Id3v2Tag::new();
    for frame in frames {
        tag.insert(frame);
    }
    tag.save_to_path(path, WriteOptions::default())
        .expect("save ID3v2");
}

/// Writes a raw Vorbis comment (`key` kept as given, no mapping to an
/// `ItemKey`) into a FLAC, Ogg Vorbis or Opus file, replacing earlier ones of
/// that key.
pub fn write_vorbis_key(path: &Path, key: &str, text: &str) {
    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .expect("extension");
    let mut file = File::open(path).expect("open fixture");
    let options = lofty::config::ParseOptions::new();
    macro_rules! write_key {
        ($file_type:ty, |$f:ident| $comments:expr) => {{
            let mut $f = <$file_type>::read_from(&mut file, options).expect("read fixture");
            let comments: &mut VorbisComments = $comments;
            comments.insert(key.to_owned(), text.to_owned());
            comments
                .save_to_path(path, WriteOptions::default())
                .expect("save Vorbis comments");
        }};
    }
    match ext {
        "flac" => write_key!(FlacFile, |f| {
            if f.vorbis_comments().is_none() {
                f.set_vorbis_comments(VorbisComments::default());
            }
            f.vorbis_comments_mut().expect("just set")
        }),
        "ogg" => write_key!(VorbisFile, |f| f.vorbis_comments_mut()),
        "opus" => write_key!(OpusFile, |f| f.vorbis_comments_mut()),
        other => panic!("no Vorbis comments in .{other}"),
    }
}

/// One ID3v2.4 frame: id, syncsafe size, no flags.
pub fn id3v2_frame(id: &str, body: &[u8]) -> Vec<u8> {
    id3v2_frame_with_size(id, body.len(), 0, body)
}

/// Like [`id3v2_frame`] with the size and flag fields chosen by the caller.
pub fn id3v2_frame_with_size(id: &str, size: usize, flags: u16, body: &[u8]) -> Vec<u8> {
    let mut frame = id.as_bytes().to_vec();
    frame.extend_from_slice(&syncsafe(size));
    frame.extend_from_slice(&flags.to_be_bytes());
    frame.extend_from_slice(body);
    frame
}

/// A `USLT` frame body in UTF-8, as symphonia and lofty both read it.
pub fn uslt_frame(text: &str) -> Vec<u8> {
    let mut body = b"\x03eng\x00".to_vec();
    body.extend_from_slice(text.as_bytes());
    id3v2_frame("USLT", &body)
}

/// A frame lofty refuses (compressed, no data length indicator) and
/// symphonia treats as a structural error: it ends the readable part of the
/// tag.
pub fn frame_that_ends_the_tag() -> Vec<u8> {
    id3v2_frame_with_size("TIT2", 4, 0x0008, b"\x03abc")
}

/// A `TXXX` frame with an unknown text encoding byte: lofty refuses it,
/// symphonia skips just this frame and goes on.
pub fn frame_with_a_bad_encoding() -> Vec<u8> {
    id3v2_frame("TXXX", b"\x09d\x00t")
}

/// An ID3v2.4 tag made of `frames` (declaring exactly their length, or
/// `declared` when given) in front of the in-memory MP3.
pub fn broken_id3v2(frames: &[Vec<u8>], declared: Option<usize>) -> Vec<u8> {
    let mut bytes = id3v2_tag(frames, declared);
    bytes.extend_from_slice(&mp3_bytes());
    bytes
}

fn syncsafe(size: usize) -> [u8; 4] {
    [21, 14, 7, 0].map(|shift| ((size >> shift) & 0x7f) as u8)
}

/// A frame of ID3v2.`version` (2, 3 or 4): `id` is the four-letter id, cut to
/// its three-letter legacy form for 2.2 (`USLT` -> `ULT`, `TXXX` -> `TXX`).
pub fn versioned_frame(version: u8, id: &str, body: &[u8]) -> Vec<u8> {
    let mut frame = Vec::new();
    match version {
        2 => {
            let legacy = match id {
                "USLT" => "ULT",
                "TXXX" => "TXX",
                "TIT2" => "TT2",
                other => panic!("no legacy id for {other}"),
            };
            frame.extend_from_slice(legacy.as_bytes());
            frame.extend_from_slice(&(body.len() as u32).to_be_bytes()[1..]);
        }
        3 => {
            frame.extend_from_slice(id.as_bytes());
            frame.extend_from_slice(&(body.len() as u32).to_be_bytes());
            frame.extend_from_slice(&[0, 0]);
        }
        _ => return id3v2_frame(id, body),
    }
    frame.extend_from_slice(body);
    frame
}

/// A `USLT` (`ULT` in 2.2) frame in ISO-8859-1.
pub fn versioned_uslt(version: u8, text: &str) -> Vec<u8> {
    let mut body = b"\x00eng\x00".to_vec();
    body.extend(text.chars().map(|c| c as u8));
    versioned_frame(version, "USLT", &body)
}

/// A `TXXX` (`TXX` in 2.2) frame lofty refuses (unknown encoding byte).
pub fn versioned_bad_frame(version: u8) -> Vec<u8> {
    versioned_frame(version, "TXXX", b"\x09d\x00t")
}

/// An ID3v2.`version` tag with `flags` made of `body` (declaring its length)
/// in front of the in-memory MP3.
pub fn id3v2_tag_bytes(version: u8, flags: u8, body: &[u8]) -> Vec<u8> {
    let mut bytes = vec![b'I', b'D', b'3', version, 0, flags];
    bytes.extend_from_slice(&syncsafe(body.len()));
    bytes.extend_from_slice(body);
    bytes.extend_from_slice(&mp3_bytes());
    bytes
}

/// `body` with a `00` inserted after every `FF` (tag-level unsynchronisation).
pub fn unsynchronised(body: &[u8]) -> Vec<u8> {
    body.iter()
        .flat_map(|&b| if b == 0xff { vec![b, 0] } else { vec![b] })
        .collect()
}
