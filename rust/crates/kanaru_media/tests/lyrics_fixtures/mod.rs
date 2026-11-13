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
use lofty::file::TaggedFileExt;
use lofty::id3::v2::{
    BinaryFrame, Frame, FrameId, Id3v2Tag, SyncTextContentType, SynchronizedTextFrame,
    TimestampFormat, UnsynchronizedTextFrame,
};
use lofty::tag::{ItemKey, Tag, TagExt};
use lofty::TextEncoding;

use crate::tags_fixtures::{flac_bytes, mp3_bytes, wav_bytes, TempDir};

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
