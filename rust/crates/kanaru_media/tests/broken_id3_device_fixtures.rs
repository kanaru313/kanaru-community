//! Builds the audio files for checking broken-ID3 recovery on a device (the
//! app's library scan and lyrics view), from untagged base files made with
//! ffmpeg. Ignored by default; run it by hand:
//!
//! ```sh
//! KANARU_BROKEN_ID3_BASE=<dir with base.mp3, base.wav, base.aiff, base.flac> \
//! KANARU_BROKEN_ID3_OUT=<output dir> \
//! cargo test -p kanaru_media --test broken_id3_device_fixtures -- --ignored
//! ```
//!
//! Per format (`mp3`, `wav`, `aiff`, `flac`) it writes three files, each with
//! its own title so the device list shows which is which:
//!
//! - `ok-<fmt>`: a healthy tag (title `OK <FMT>`), the control file;
//! - `broken-<fmt>`: title `Broken <FMT>`, artist, album and lyrics, then a
//!   frame lofty refuses, so lofty fails the whole file; the scan and the
//!   lyrics reader recover the fields. FLAC: the fields are in its Vorbis
//!   comments behind a broken ID3v2 prefix (whose own title, `Broken FLAC
//!   prefix`, must not win);
//! - `lost-<fmt>`: the refused frame first, so no field survives; the file is
//!   listed by its name with its duration.
//!
//! Every file is checked here against lofty and the crate's readers before
//! the test passes. No audio is checked in.

mod lyrics_fixtures;
mod tags_fixtures;

use std::path::{Path, PathBuf};

use kanaru_media::tags::{read_tags, TrackTags};
use kanaru_media::Cancel;
use lofty::file::{AudioFile, TaggedFileExt};
use lofty::tag::TagType;
use lyrics_fixtures::{
    add_chunks, frame_that_ends_the_tag, id3v2_frame, id3v2_tag, read, uslt_frame,
    write_vorbis_key, Place,
};
use tags_fixtures::{open_plain, TempDir};

const ARTIST: &str = "Kanaru Test";
const ALBUM: &str = "Broken ID3";
/// Length of the ffmpeg base files, in milliseconds.
const BASE_DURATION_MS: i64 = 35_000;
/// How far a read duration may be from [`BASE_DURATION_MS`].
const DURATION_SLACK_MS: i64 = 500;

#[derive(Clone, Copy, Debug, PartialEq)]
enum Format {
    Mp3,
    Wav,
    Aiff,
    Flac,
}

const FORMATS: [Format; 4] = [Format::Mp3, Format::Wav, Format::Aiff, Format::Flac];

impl Format {
    fn ext(self) -> &'static str {
        match self {
            Self::Mp3 => "mp3",
            Self::Wav => "wav",
            Self::Aiff => "aiff",
            Self::Flac => "flac",
        }
    }

    fn label(self) -> String {
        self.ext().to_ascii_uppercase()
    }
}

#[test]
#[ignore = "writes device fixtures; needs KANARU_BROKEN_ID3_BASE and KANARU_BROKEN_ID3_OUT"]
fn write_broken_id3_device_fixtures() {
    let base_dir = env_path("KANARU_BROKEN_ID3_BASE");
    let out_dir = env_path("KANARU_BROKEN_ID3_OUT");
    std::fs::create_dir_all(&out_dir).expect("create the output directory");
    let mut written = Vec::new();
    for format in FORMATS {
        let base_path = base_dir.join(format!("base.{}", format.ext()));
        let base = std::fs::read(&base_path)
            .unwrap_or_else(|e| panic!("read {}: {e}", base_path.display()));
        check_base(format, &base_path, &base);

        let label = format.label();
        let ok = write(&out_dir, "ok", format, &ok_bytes(format, &base));
        check_ok(&ok, &format!("OK {label}"));

        let broken = write(&out_dir, "broken", format, &broken_bytes(format, &base));
        check_broken(&broken, &format!("Broken {label}"));

        let lost = write(&out_dir, "lost", format, &lost_bytes(format, &base));
        check_lost(&lost);

        written.extend([ok, broken, lost]);
    }
    for path in &written {
        let size = std::fs::metadata(path).expect("stat output").len();
        println!("{size:>10}  {}", path.display());
    }
    assert_eq!(written.len(), 12);
}

fn env_path(name: &str) -> PathBuf {
    match std::env::var_os(name) {
        Some(value) if !value.is_empty() => PathBuf::from(value),
        _ => panic!("set {name}"),
    }
}

fn write(dir: &Path, kind: &str, format: Format, bytes: &[u8]) -> PathBuf {
    let path = dir.join(format!("{kind}-{}.{}", format.ext(), format.ext()));
    std::fs::write(&path, bytes).unwrap_or_else(|e| panic!("write {}: {e}", path.display()));
    path
}

// Building.

fn ok_bytes(format: Format, base: &[u8]) -> Vec<u8> {
    let title = format!("OK {}", format.label());
    match format {
        Format::Flac => with_vorbis(base, &title),
        _ => with_id3(format, base, id3v2_tag(&fields(&title), None)),
    }
}

fn broken_bytes(format: Format, base: &[u8]) -> Vec<u8> {
    let title = format!("Broken {}", format.label());
    match format {
        Format::Flac => {
            let mut frames = fields(&format!("{title} prefix"));
            frames.push(frame_that_ends_the_tag());
            with_id3(format, &with_vorbis(base, &title), id3v2_tag(&frames, None))
        }
        _ => {
            let mut frames = fields(&title);
            frames.push(frame_that_ends_the_tag());
            with_id3(format, base, id3v2_tag(&frames, None))
        }
    }
}

fn lost_bytes(format: Format, base: &[u8]) -> Vec<u8> {
    let mut frames = vec![frame_that_ends_the_tag()];
    frames.extend(fields(&format!("Lost {}", format.label())));
    with_id3(format, base, id3v2_tag(&frames, None))
}

/// Title, artist, album and lyrics as ID3v2.4 frames.
fn fields(title: &str) -> Vec<Vec<u8>> {
    vec![
        text_frame("TIT2", title),
        text_frame("TPE1", ARTIST),
        text_frame("TALB", ALBUM),
        uslt_frame(&lyrics(title)),
    ]
}

/// Lyrics that name the file they belong to.
fn lyrics(title: &str) -> String {
    format!("{title}\nKanaru broken ID3 check\nThird line")
}

fn text_frame(id: &str, text: &str) -> Vec<u8> {
    let mut body = vec![0x03]; // UTF-8
    body.extend_from_slice(text.as_bytes());
    id3v2_frame(id, &body)
}

/// `base` with `tag` where the format keeps an ID3v2 tag: in front (MP3,
/// FLAC) or as a chunk at the end (WAV `id3 `, AIFF `ID3 `).
fn with_id3(format: Format, base: &[u8], tag: Vec<u8>) -> Vec<u8> {
    match format {
        Format::Mp3 | Format::Flac => [tag, base.to_vec()].concat(),
        Format::Wav => add_chunks(
            base.to_vec(),
            0,
            &[(b"id3 ", &tag)],
            Place::AfterAudio,
            u32::to_le_bytes,
        ),
        Format::Aiff => add_chunks(
            base.to_vec(),
            0,
            &[(b"ID3 ", &tag)],
            Place::AfterAudio,
            u32::to_be_bytes,
        ),
    }
}

/// The FLAC `base` with title, artist, album and lyrics in its Vorbis
/// comments (`LYRICS`, which lofty maps to its lyrics key).
fn with_vorbis(base: &[u8], title: &str) -> Vec<u8> {
    let dir = TempDir::new();
    let path = dir.write("vorbis.flac", base);
    let lyrics = lyrics(title);
    for (key, value) in [
        ("TITLE", title),
        ("ARTIST", ARTIST),
        ("ALBUM", ALBUM),
        ("LYRICS", lyrics.as_str()),
    ] {
        write_vorbis_key(&path, key, value);
    }
    std::fs::read(&path).expect("read the tagged FLAC")
}

// Checks.

/// The base must be untagged where the format keeps ID3v2, and 35 s long.
fn check_base(format: Format, path: &Path, bytes: &[u8]) {
    let what = path.display();
    match format {
        Format::Mp3 => assert!(!bytes.starts_with(b"ID3"), "{what} has an ID3v2 tag"),
        Format::Flac => assert!(
            bytes.starts_with(b"fLaC"),
            "{what} does not start with fLaC"
        ),
        Format::Wav => check_container(bytes, b"RIFF", b"WAVE", false, &what.to_string()),
        Format::Aiff => check_container(bytes, b"FORM", b"AIFF", true, &what.to_string()),
    }
    let tagged = lofty::read_from_path(path).unwrap_or_else(|e| panic!("lofty on {what}: {e}"));
    assert!(
        tagged.tag(TagType::Id3v2).is_none(),
        "{what} has an ID3v2 tag"
    );
    let duration = tagged.properties().duration().as_millis() as i64;
    assert_close(duration, &what.to_string());
}

/// A RIFF/FORM file whose outer size matches its length (chunks can be
/// appended) and that holds no top-level ID3 chunk.
fn check_container(bytes: &[u8], outer: &[u8; 4], form: &[u8; 4], big_endian: bool, what: &str) {
    assert!(
        bytes.len() >= 12 && &bytes[..4] == outer && &bytes[8..12] == form,
        "{what} is not {}/{}",
        String::from_utf8_lossy(outer),
        String::from_utf8_lossy(form)
    );
    let size = |at: usize| {
        let field: [u8; 4] = bytes[at..at + 4].try_into().expect("4 bytes");
        if big_endian {
            u32::from_be_bytes(field)
        } else {
            u32::from_le_bytes(field)
        }
    };
    assert_eq!(
        size(4) as usize,
        bytes.len() - 8,
        "{what}: outer size does not match the file length"
    );
    let mut at = 12;
    while at + 8 <= bytes.len() {
        let id = &bytes[at..at + 4];
        assert!(
            !id.eq_ignore_ascii_case(b"id3 "),
            "{what} already has an ID3 chunk"
        );
        let len = size(at + 4) as usize;
        at = at.saturating_add(8 + len + len % 2);
    }
}

fn tags(path: &Path) -> TrackTags {
    read_tags(path, &open_plain, &Cancel::new())
        .unwrap_or_else(|e| panic!("read_tags {}: {e:?}", path.display()))
}

fn lyrics_text(path: &Path) -> Option<String> {
    read(path)
        .unwrap_or_else(|e| panic!("read_lyrics {}: {e:?}", path.display()))
        .and_then(|lyrics| lyrics.text)
}

fn check_fields(path: &Path, title: &str) {
    let what = path.display().to_string();
    let tags = tags(path);
    assert_eq!(tags.title.as_deref(), Some(title), "{what}");
    assert_eq!(tags.artists, [ARTIST], "{what}");
    assert_eq!(tags.album.as_deref(), Some(ALBUM), "{what}");
    assert_close(tags.duration_ms.expect("duration"), &what);
    assert_eq!(lyrics_text(path), Some(lyrics(title)), "{what}");
}

fn check_ok(path: &Path, title: &str) {
    assert!(
        lofty::read_from_path(path).is_ok(),
        "lofty refuses the control file {}",
        path.display()
    );
    check_fields(path, title);
}

fn check_broken(path: &Path, title: &str) {
    assert!(
        lofty::read_from_path(path).is_err(),
        "lofty reads {}: it is not broken",
        path.display()
    );
    check_fields(path, title);
}

fn check_lost(path: &Path) {
    let what = path.display().to_string();
    assert!(
        lofty::read_from_path(path).is_err(),
        "lofty reads {what}: it is not broken"
    );
    let tags = tags(path);
    assert_eq!(tags.title, None, "{what}");
    assert!(tags.artists.is_empty(), "{what}");
    assert_eq!(tags.album, None, "{what}");
    assert_close(tags.duration_ms.expect("duration"), &what);
    assert_eq!(lyrics_text(path), None, "{what}");
}

fn assert_close(duration_ms: i64, what: &str) {
    assert!(
        (duration_ms - BASE_DURATION_MS).abs() <= DURATION_SLACK_MS,
        "{what}: duration {duration_ms} ms, expected about {BASE_DURATION_MS} ms"
    );
}
