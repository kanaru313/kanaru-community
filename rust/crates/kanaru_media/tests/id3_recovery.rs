//! The recovery of a broken ID3v2 tag only ever parses a bounded copy of it.
//!
//! Each test builds a tag whose outcome differs when the copy handed to
//! symphonia is not cut first: frames past the frame cap would be read, and a
//! declared size past the bytes held would make the whole read fail. Padding
//! is no signal here: symphonia stops at padding by itself.
//!
//! The same holds for every container that keeps an ID3v2 tag (MP3 and FLAC
//! prefix, WAV and AIFF chunk), for lyrics and for the scan's tags. The last
//! tests check that a flood of frames and a long file stay quick to recover.

mod lyrics_fixtures;
mod tags_fixtures;

use std::fs::File;
use std::io::{BufReader, Seek, SeekFrom, Write};
use std::path::Path;
use std::time::{Duration, Instant};

use kanaru_media::tags::lyrics_reader::MAX_ID3_FALLBACK_FRAMES;
use kanaru_media::tags::{read_tags, TrackTags};
use kanaru_media::Cancel;
use lofty::file::FileType;
use lofty::probe::Probe;
use lyrics_fixtures::{
    aiff_with_chunks, broken_id3v2, frame_that_ends_the_tag, frame_with_a_bad_encoding,
    id3v2_frame, id3v2_tag, read, uslt_frame, wav_with_chunks, Place,
};
use tags_fixtures::{flac_bytes, mp3_bytes, open_plain, TempDir};

/// Where each container keeps the tag under test.
#[derive(Clone, Copy, Debug)]
enum Container {
    WavChunk,
    AiffChunk,
    FlacPrefix,
}

const CONTAINERS: [Container; 3] = [
    Container::WavChunk,
    Container::AiffChunk,
    Container::FlacPrefix,
];

impl Container {
    /// A file holding `tag` where this container keeps it. The FLAC stream
    /// carries no lyrics of its own, so its lyrics come from the prefix.
    /// `audio`: false ends a FLAC right after its prefix (a chunk is a copy of
    /// its own bounds, so a WAV or AIFF keeps its audio either way).
    fn write(self, dir: &TempDir, tag: &[u8], audio: bool) -> std::path::PathBuf {
        match self {
            Container::WavChunk => dir.write(
                "tagged.wav",
                &wav_with_chunks(&[(b"id3 ", tag)], Place::AfterAudio),
            ),
            Container::AiffChunk => dir.write(
                "tagged.aiff",
                &aiff_with_chunks(&[(b"ID3 ", tag)], Place::AfterAudio),
            ),
            Container::FlacPrefix => {
                let mut bytes = tag.to_vec();
                if audio {
                    bytes.extend(flac_bytes());
                }
                let path = dir.write("tagged.flac", &bytes);
                assert_eq!(probed(&path), Some(FileType::Flac));
                path
            }
        }
    }
}

/// The file type `read_lyrics` reads `path` as.
fn probed(path: &Path) -> Option<FileType> {
    let reader = BufReader::new(File::open(path).expect("open"));
    let ext = path
        .extension()
        .and_then(|e| e.to_str())
        .expect("extension");
    let file_type = FileType::from_ext(ext).expect("known extension");
    Probe::with_file_type(reader, file_type)
        .guess_file_type()
        .expect("probe")
        .file_type()
}

/// Frames of a tag lofty refuses for its first frame; symphonia skips only
/// that frame and reads on. `TXXX:LYRICS` sits inside the frame cap, `USLT`
/// after it: with the cap the text frame is all that is read; without it the
/// `USLT` past the fillers would win, as it is preferred.
fn frames_with_lyrics_past_the_frame_cap() -> Vec<Vec<u8>> {
    let mut frames = vec![
        frame_with_a_bad_encoding(),
        id3v2_frame("TXXX", b"\x03LYRICS\x00Inside the cap"),
    ];
    frames.extend(std::iter::repeat_n(
        id3v2_frame("TIT2", b"\x03x"),
        MAX_ID3_FALLBACK_FRAMES,
    ));
    frames.push(uslt_frame("Beyond the cap"));
    frames
}

/// The lyrics text `read_lyrics` gives for `path`, which lofty must refuse.
fn recovered_text(path: &Path, what: &str) -> Option<String> {
    assert!(lofty::read_from_path(path).is_err(), "{what}");
    read(path)
        .unwrap_or_else(|e| panic!("{what}: {e:?}"))
        .and_then(|lyrics| lyrics.text)
}

#[test]
fn mp3_lyrics_past_the_frame_cap_are_not_read() {
    let dir = TempDir::new();
    let tag = broken_id3v2(&frames_with_lyrics_past_the_frame_cap(), None);
    let path = dir.write("capped.mp3", &tag);
    assert_eq!(
        recovered_text(&path, "mp3").as_deref(),
        Some("Inside the cap")
    );
}

#[test]
fn mp3_lyrics_in_a_tag_declaring_more_than_the_file_holds_are_read() {
    let dir = TempDir::new();
    // The file ends with the tag: past the frames held, symphonia would look
    // for the next frame header beyond the end of the file and fail.
    let mut bytes = broken_id3v2(&[uslt_frame("Held")], Some(250 * 1024 * 1024));
    bytes.truncate(bytes.len() - mp3_bytes().len());
    let path = dir.write("oversized.mp3", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).expect("read").expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Held"));
}

#[test]
fn container_lyrics_past_the_frame_cap_are_not_read() {
    let dir = TempDir::new();
    let tag = id3v2_tag(&frames_with_lyrics_past_the_frame_cap(), None);
    for container in CONTAINERS {
        let path = container.write(&dir, &tag, true);
        let what = format!("{container:?}");
        assert_eq!(
            recovered_text(&path, &what).as_deref(),
            Some("Inside the cap"),
            "{what}"
        );
    }
}

#[test]
fn container_lyrics_in_a_tag_declaring_more_than_it_holds_are_read() {
    let dir = TempDir::new();
    // Past the frames held, symphonia would look for the next frame header
    // beyond the end of the copy and fail the whole read. The frame lofty
    // refuses makes it fail even where the container bounds the tag.
    let tag = id3v2_tag(
        &[uslt_frame("Held"), frame_with_a_bad_encoding()],
        Some(250 * 1024 * 1024),
    );
    for container in CONTAINERS {
        let path = container.write(&dir, &tag, false);
        assert!(lofty::read_from_path(&path).is_err(), "{container:?}");
        let lyrics = read(&path)
            .expect("read")
            .unwrap_or_else(|| panic!("{container:?}: none"));
        assert_eq!(lyrics.text.as_deref(), Some("Held"), "{container:?}");
    }
}

/// The scan's tags of `path`, which lofty must refuse.
fn scanned(path: &Path, what: &str) -> TrackTags {
    assert!(lofty::read_from_path(path).is_err(), "{what}");
    read_tags(path, &open_plain, &Cancel::new()).unwrap_or_else(|e| panic!("{what}: {e:?}"))
}

/// Frames of a tag lofty refuses for its first frame: `TALB` sits inside the
/// frame cap, `TIT2` after the fillers. With the cap only the album is read.
fn frames_with_a_title_past_the_frame_cap() -> Vec<Vec<u8>> {
    let mut frames = vec![
        frame_with_a_bad_encoding(),
        id3v2_frame("TALB", b"\x03Inside"),
    ];
    frames.extend(std::iter::repeat_n(
        id3v2_frame("TXXX", b"\x03f\x00x"),
        MAX_ID3_FALLBACK_FRAMES,
    ));
    frames.push(id3v2_frame("TIT2", b"\x03Beyond"));
    frames
}

#[test]
fn tags_past_the_frame_cap_are_not_read() {
    let dir = TempDir::new();
    let frames = frames_with_a_title_past_the_frame_cap();
    let mp3 = dir.write("capped.mp3", &broken_id3v2(&frames, None));
    let wav = Container::WavChunk.write(&dir, &id3v2_tag(&frames, None), true);
    for (path, what) in [(mp3, "mp3"), (wav, "wav")] {
        let tags = scanned(&path, what);
        assert_eq!(tags.album.as_deref(), Some("Inside"), "{what}");
        assert_eq!(tags.title, None, "{what}");
        assert!(tags.duration_ms.is_some(), "{what}");
    }
}

#[test]
fn tags_in_a_tag_declaring_more_than_it_holds_are_read() {
    let dir = TempDir::new();
    // Past the frames held, symphonia would look for the next frame header
    // beyond the end of the copy and fail the whole read. The MP3 ends with
    // its tag (no audio, so the title is all that can be recovered); the WAV
    // chunk bounds the tag.
    let tag = id3v2_tag(
        &[
            id3v2_frame("TIT2", b"\x03Held"),
            frame_with_a_bad_encoding(),
        ],
        Some(250 * 1024 * 1024),
    );
    let mp3 = dir.write("oversized.mp3", &tag);
    let wav = Container::WavChunk.write(&dir, &tag, true);
    for (path, what) in [(mp3, "mp3"), (wav, "wav")] {
        let tags = scanned(&path, what);
        assert_eq!(tags.title.as_deref(), Some("Held"), "{what}");
    }
}

#[test]
fn a_flood_of_empty_frames_in_a_wav_id3_chunk_is_read_fast() {
    let dir = TempDir::new();
    let empty = id3v2_frame("TIT2", b"");
    let mut frames = vec![uslt_frame("Before the flood"), frame_with_a_bad_encoding()];
    frames.push(empty.repeat(16 * 1024 * 1024 / empty.len()));
    let tag = id3v2_tag(&frames, None);
    let path = Container::WavChunk.write(&dir, &tag, true);
    assert!(lofty::read_from_path(&path).is_err());
    let started = Instant::now();
    let lyrics = read(&path).expect("read").expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Before the flood"));
    assert!(started.elapsed() < Duration::from_secs(3));
}

#[test]
fn a_broken_id3_chunk_after_200_mb_of_audio_is_found_fast() {
    let dir = TempDir::new();
    let tag = id3v2_tag(&[uslt_frame("At the end"), frame_that_ends_the_tag()], None);
    let audio_len: u32 = 200 * 1024 * 1024;
    let mut bytes = wav_with_chunks(&[], Place::AfterAudio);
    // Keep the RIFF header and the `fmt ` chunk; the audio is a sparse hole.
    bytes.truncate(36);
    bytes.extend_from_slice(b"data");
    bytes.extend_from_slice(&audio_len.to_le_bytes());
    let path = dir.write("long.wav", &bytes);
    let mut file = std::fs::OpenOptions::new()
        .write(true)
        .open(&path)
        .expect("open");
    let audio_end = bytes.len() as u64 + u64::from(audio_len);
    file.set_len(audio_end).expect("grow");
    file.seek(SeekFrom::Start(audio_end)).expect("seek");
    let mut chunk = b"id3 ".to_vec();
    chunk.extend_from_slice(&(tag.len() as u32).to_le_bytes());
    chunk.extend_from_slice(&tag);
    if tag.len() % 2 == 1 {
        chunk.push(0);
    }
    file.write_all(&chunk).expect("write chunk");
    let riff_size = (audio_end + chunk.len() as u64 - 8) as u32;
    file.seek(SeekFrom::Start(4)).expect("seek");
    file.write_all(&riff_size.to_le_bytes())
        .expect("write size");
    drop(file);
    assert!(lofty::read_from_path(&path).is_err());
    let started = Instant::now();
    let lyrics = read(&path).expect("read").expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("At the end"));
    assert!(started.elapsed() < Duration::from_secs(1));
}
