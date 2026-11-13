//! `read_embedded_lyrics` on real files.

use std::path::{Path, PathBuf};

use kanaru_bridge::api::error::NativeErrorKind;
use kanaru_bridge::api::lyrics::read_embedded_lyrics;

/// A unique temp directory, removed on drop.
struct TempDir(PathBuf);

impl TempDir {
    fn new(name: &str) -> Self {
        let dir =
            std::env::temp_dir().join(format!("kanaru-lyrics-api-{}-{name}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).expect("create temp dir");
        Self(dir)
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

fn syncsafe(n: usize) -> [u8; 4] {
    [
        ((n >> 21) & 0x7f) as u8,
        ((n >> 14) & 0x7f) as u8,
        ((n >> 7) & 0x7f) as u8,
        (n & 0x7f) as u8,
    ]
}

fn frame(id: &[u8; 4], body: &[u8]) -> Vec<u8> {
    let mut f = id.to_vec();
    f.extend_from_slice(&(body.len() as u32).to_be_bytes());
    f.extend_from_slice(&[0, 0]);
    f.extend_from_slice(body);
    f
}

/// An MP3 with an ID3v2.3 tag holding USLT and SYLT, then a few silent frames.
fn mp3_with_lyrics() -> Vec<u8> {
    let mut uslt = b"\x00eng\x00".to_vec();
    uslt.extend_from_slice(b"plain words");
    let mut sylt = b"\x00eng\x02\x01\x00".to_vec();
    for (text, ms) in [("first", 1000u32), ("second", 2500)] {
        sylt.extend_from_slice(text.as_bytes());
        sylt.push(0);
        sylt.extend_from_slice(&ms.to_be_bytes());
    }
    let mut frames = frame(b"USLT", &uslt);
    frames.extend(frame(b"SYLT", &sylt));
    let mut out = b"ID3\x03\x00\x00".to_vec();
    out.extend_from_slice(&syncsafe(frames.len()));
    out.extend(frames);
    // MPEG1 Layer III, 128 kbps, 44.1 kHz: 417-byte frames.
    for _ in 0..4 {
        out.extend_from_slice(&[0xFF, 0xFB, 0x90, 0x64]);
        out.resize(out.len() + 413, 0);
    }
    out
}

fn path_str(p: &Path) -> String {
    p.to_string_lossy().into_owned()
}

#[test]
fn mp3_with_uslt_and_sylt_gives_text_and_lines() {
    let dir = TempDir::new("mp3");
    let file = dir.0.join("song.MP3");
    std::fs::write(&file, mp3_with_lyrics()).expect("write fixture");
    let lyrics = read_embedded_lyrics(path_str(&file))
        .expect("read ok")
        .expect("lyrics present");
    assert_eq!(lyrics.text.as_deref(), Some("plain words"));
    let lines: Vec<(i64, &str)> = lyrics
        .synced
        .iter()
        .map(|l| (l.time_ms, l.text.as_str()))
        .collect();
    assert_eq!(lines, vec![(1000, "first"), (2500, "second")]);
}

#[test]
fn missing_file_is_not_found() {
    let dir = TempDir::new("missing");
    let err = read_embedded_lyrics(path_str(&dir.0.join("none.mp3"))).unwrap_err();
    assert_eq!(err.kind, NativeErrorKind::NotFound);
    assert!(!err.transient);
}

#[test]
fn directory_is_unsupported() {
    let dir = TempDir::new("folder");
    let err = read_embedded_lyrics(path_str(&dir.0)).unwrap_err();
    assert_eq!(err.kind, NativeErrorKind::Unsupported);
}

#[cfg(unix)]
#[test]
fn fifo_is_unsupported_without_blocking() {
    let dir = TempDir::new("fifo");
    let fifo = dir.0.join("pipe.mp3");
    let made = std::process::Command::new("mkfifo")
        .arg(&fifo)
        .status()
        .is_ok_and(|s| s.success());
    if !made {
        eprintln!("skipped: mkfifo is not available");
        return;
    }
    let err = read_embedded_lyrics(path_str(&fifo)).unwrap_err();
    assert_eq!(err.kind, NativeErrorKind::Unsupported);
}
