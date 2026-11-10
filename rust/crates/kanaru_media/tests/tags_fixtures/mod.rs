//! Minimal audio files built in memory, so no binary fixture is checked in.
//! Tags are written with lofty; a test asserts lofty probes each file before
//! trusting the tags it reads back. Shared by several test files, each of
//! which uses a part.
#![allow(dead_code)]

use std::fs::File;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU32, Ordering};

use kanaru_media::MediaError;
use lofty::config::WriteOptions;
use lofty::tag::{ItemKey, ItemValue, Tag, TagExt, TagItem};

static NEXT: AtomicU32 = AtomicU32::new(0);

/// A directory removed on drop.
pub struct TempDir(PathBuf);

impl TempDir {
    pub fn new() -> Self {
        let dir = std::env::temp_dir().join(format!(
            "kanaru-tags-test-{}-{}",
            std::process::id(),
            NEXT.fetch_add(1, Ordering::Relaxed)
        ));
        std::fs::create_dir_all(&dir).expect("create temp dir");
        Self(dir)
    }

    pub fn path(&self, name: &str) -> PathBuf {
        self.0.join(name)
    }

    pub fn write(&self, name: &str, bytes: &[u8]) -> PathBuf {
        let path = self.path(name);
        std::fs::write(&path, bytes).expect("write fixture");
        path
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

/// One second of 16-bit mono 44.1 kHz silence.
pub fn wav_bytes() -> Vec<u8> {
    let data_len: u32 = 44_100 * 2;
    let mut b = Vec::new();
    b.extend_from_slice(b"RIFF");
    b.extend_from_slice(&(36 + data_len).to_le_bytes());
    b.extend_from_slice(b"WAVEfmt ");
    b.extend_from_slice(&16u32.to_le_bytes());
    b.extend_from_slice(&1u16.to_le_bytes()); // PCM
    b.extend_from_slice(&1u16.to_le_bytes()); // mono
    b.extend_from_slice(&44_100u32.to_le_bytes());
    b.extend_from_slice(&(44_100u32 * 2).to_le_bytes()); // byte rate
    b.extend_from_slice(&2u16.to_le_bytes()); // block align
    b.extend_from_slice(&16u16.to_le_bytes());
    b.extend_from_slice(b"data");
    b.extend_from_slice(&data_len.to_le_bytes());
    b.resize(b.len() + data_len as usize, 0);
    b
}

/// FLAC with only a STREAMINFO block: 44.1 kHz, stereo, 16 bit, 1 s.
pub fn flac_bytes() -> Vec<u8> {
    let mut b = b"fLaC".to_vec();
    b.push(0x80); // last metadata block, type STREAMINFO
    b.extend_from_slice(&[0, 0, 34]);
    b.extend_from_slice(&4096u16.to_be_bytes()); // min block size
    b.extend_from_slice(&4096u16.to_be_bytes()); // max block size
    b.extend_from_slice(&[0; 6]); // min and max frame size: unknown
    let packed: u64 = (44_100u64 << 44) | (1u64 << 41) | (15u64 << 36) | 44_100u64;
    b.extend_from_slice(&packed.to_be_bytes());
    b.extend_from_slice(&[0; 16]); // MD5: unknown
    b
}

/// Twenty MPEG-1 Layer III frames, 128 kbps, 44.1 kHz, stereo.
pub fn mp3_bytes() -> Vec<u8> {
    let mut frame = vec![0u8; 417];
    frame[..4].copy_from_slice(&[0xFF, 0xFB, 0x90, 0x00]);
    frame.repeat(20)
}

/// A tag with the given text items; the same key may repeat.
pub fn tag_with(tag_type: lofty::tag::TagType, items: &[(ItemKey, &str)]) -> Tag {
    let mut tag = Tag::new(tag_type);
    for (key, value) in items {
        tag.push(TagItem::new(*key, ItemValue::Text((*value).to_owned())));
    }
    tag
}

pub fn save(tag: &Tag, path: &Path) {
    tag.save_to_path(path, WriteOptions::default())
        .expect("write tag with lofty");
}

/// The injected `open`: the plain filesystem, as the bridge's would be.
pub fn open_plain(path: &Path) -> Result<File, MediaError> {
    File::open(path).map_err(MediaError::from)
}
