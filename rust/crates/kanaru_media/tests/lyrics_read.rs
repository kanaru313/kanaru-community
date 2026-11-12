//! `read_lyrics` on lyrics written into small generated files, plus the
//! broken inputs it must survive.

mod lyrics_fixtures;
mod tags_fixtures;

use std::fs::File;

use kanaru_media::tags::lyrics_reader::{read_lyrics, SyncedLine};
use kanaru_media::MediaError;
use lofty::config::WriteOptions;
use lofty::id3::v2::{ExtendedTextFrame, Frame, SyncTextContentType, TimestampFormat};
use lofty::tag::{ItemKey, Tag, TagExt, TagType};
use lofty::TextEncoding;
use lyrics_fixtures::{read, sample, sylt, sylt_with, uslt, write_generic, write_id3v2};
use tags_fixtures::TempDir;

fn line(time_ms: u32, text: &str) -> SyncedLine {
    SyncedLine {
        time_ms,
        text: text.to_owned(),
    }
}

fn txxx(description: &str, text: &str) -> Frame<'static> {
    Frame::UserText(ExtendedTextFrame::new(
        TextEncoding::UTF8,
        description.to_owned(),
        text.to_owned(),
    ))
}

/// Writes an APEv2 tag holding `text` as lyrics at the end of `path`.
fn write_ape_lyrics(path: &std::path::Path, text: &str) {
    let mut tag = Tag::new(TagType::Ape);
    assert!(tag.insert_text(ItemKey::Lyrics, text.to_owned()));
    tag.save_to_path(path, WriteOptions::default())
        .expect("save APE");
}

#[test]
fn reads_the_lyrics_field_of_every_tag_format() {
    let dir = TempDir::new();
    for name in [
        "sample.flac",
        "sample.ogg",
        "sample.opus",
        "sample.m4a",
        "sample.wv",
    ] {
        let path = sample(&dir, name);
        write_generic(&path, ItemKey::Lyrics, "[00:01.00]Hello\n[00:02.00]World");
        let lyrics = read(&path)
            .unwrap()
            .unwrap_or_else(|| panic!("{name}: none"));
        assert_eq!(
            lyrics.text.as_deref(),
            Some("[00:01.00]Hello\n[00:02.00]World"),
            "{name}"
        );
        assert!(lyrics.synced.is_empty(), "{name}");
    }
}

#[test]
fn reads_an_ape_tag_written_on_an_mp3() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_ape_lyrics(&path, "[00:01.00]From APE");
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("[00:01.00]From APE"));
}

#[test]
fn reads_vorbis_unsynced_lyrics() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.flac");
    write_generic(&path, ItemKey::UnsyncLyrics, "Plain words");
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Plain words"));
}

#[test]
fn reads_id3v2_uslt_and_sylt_from_mp3_wav_and_aiff() {
    let dir = TempDir::new();
    for name in ["sample.mp3", "sample.wav", "sample.aiff"] {
        let path = sample(&dir, name);
        write_id3v2(
            &path,
            vec![
                uslt("Plain words"),
                sylt(
                    SyncTextContentType::Lyrics,
                    TimestampFormat::MS,
                    &[(2500, "\nSecond"), (1000, "First")],
                ),
            ],
        );
        let lyrics = read(&path)
            .unwrap()
            .unwrap_or_else(|| panic!("{name}: none"));
        assert_eq!(lyrics.text.as_deref(), Some("Plain words"), "{name}");
        assert_eq!(
            lyrics.synced,
            vec![line(1000, "First"), line(2500, "Second")],
            "{name}"
        );
    }
}

#[test]
fn reads_txxx_lyrics_when_no_uslt_exists() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(&path, vec![txxx("LYRICS", "From TXXX")]);
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("From TXXX"));
}

#[test]
fn txxx_is_only_a_fallback_for_the_generic_text() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(
        &path,
        vec![txxx("UNSYNCEDLYRICS", "From TXXX"), uslt("From USLT")],
    );
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("From USLT"));
}

#[test]
fn sylt_alone_is_enough() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(
        &path,
        vec![sylt(
            SyncTextContentType::Lyrics,
            TimestampFormat::MS,
            &[(0, "Only")],
        )],
    );
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text, None);
    assert_eq!(lyrics.synced, vec![line(0, "Only")]);
}

#[test]
fn sylt_in_mpeg_frames_or_of_another_type_is_skipped() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(
        &path,
        vec![
            sylt(
                SyncTextContentType::Lyrics,
                TimestampFormat::MPEG,
                &[(10, "frames")],
            ),
            sylt(
                SyncTextContentType::Chord,
                TimestampFormat::MS,
                &[(10, "Bb F")],
            ),
        ],
    );
    assert_eq!(read(&path), Ok(None));
}

#[test]
fn sylt_typed_other_is_used_when_no_lyrics_frame_exists() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(
        &path,
        vec![sylt(
            SyncTextContentType::Other,
            TimestampFormat::MS,
            &[(5, "other")],
        )],
    );
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.synced, vec![line(5, "other")]);
}

#[test]
fn sylt_with_a_junk_language_code_is_still_read() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(
        &path,
        vec![sylt_with(
            SyncTextContentType::Lyrics,
            TimestampFormat::MS,
            &[(1000, "Junk")],
            |bytes| bytes[1..4].copy_from_slice(&[0, 0, 0]),
        )],
    );
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.synced, vec![line(1000, "Junk")]);
}

#[test]
fn sylt_syllables_are_joined_into_lines() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(
        &path,
        vec![sylt(
            SyncTextContentType::Lyrics,
            TimestampFormat::MS,
            &[
                (100, "Hel"),
                (200, "lo "),
                (300, "world"),
                (900, "\nSe"),
                (1000, "cond"),
            ],
        )],
    );
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(
        lyrics.synced,
        vec![line(100, "Hello world"), line(900, "Second")]
    );
}

#[test]
fn files_without_lyrics_give_none() {
    let dir = TempDir::new();
    for name in [
        "sample.mp3",
        "sample.flac",
        "sample.m4a",
        "sample.ogg",
        "sample.wav",
    ] {
        assert_eq!(read(&sample(&dir, name)), Ok(None), "{name}");
    }
}

#[test]
fn blank_lyrics_count_as_none() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.flac");
    write_generic(&path, ItemKey::Lyrics, "  \n ");
    assert_eq!(read(&path), Ok(None));
}

#[test]
fn oversized_text_is_dropped() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.flac");
    write_generic(&path, ItemKey::Lyrics, &"a".repeat(1024 * 1024 + 1));
    assert_eq!(read(&path), Ok(None));
}

#[test]
fn an_oversized_primary_tag_falls_to_the_next_tag() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(&path, vec![uslt(&"a".repeat(1024 * 1024 + 1))]);
    write_ape_lyrics(&path, "Small and usable");
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Small and usable"));
}

#[test]
fn a_broken_id3_tag_means_no_lyrics_for_the_whole_file() {
    let dir = TempDir::new();
    let path = dir.write(
        "garbage.mp3",
        b"ID3\x04\x00\x00\x7f\x7f\x7f\x7fnot really a tag",
    );
    assert_eq!(read(&path), Ok(None));
}

#[test]
fn an_empty_mp3_means_no_lyrics() {
    let dir = TempDir::new();
    let empty = dir.write("empty.mp3", b"");
    assert_eq!(read(&empty), Ok(None));
}

#[test]
fn txxx_description_is_matched_ignoring_case() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(&path, vec![txxx("Lyrics", "Mixed case")]);
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Mixed case"));

    write_id3v2(&path, vec![txxx("unsyncedlyrics", "Lower case")]);
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Lower case"));
}

#[test]
fn txxx_lyrics_wins_over_unsyncedlyrics() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(
        &path,
        vec![txxx("unsyncedlyrics", "Second"), txxx("Lyrics", "First")],
    );
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("First"));
}

#[test]
fn unreadable_content_outside_id3_formats_is_a_permanent_error() {
    let dir = TempDir::new();
    let empty = dir.write("empty.flac", b"");
    assert_eq!(
        read(&empty),
        Err(MediaError::Io(std::io::ErrorKind::UnexpectedEof))
    );
    let junk = dir.write("junk.bin", &[7u8; 64]);
    let result = read_lyrics(File::open(&junk).unwrap(), None);
    assert_eq!(result, Err(MediaError::Unsupported));
    let hinted = dir.write("junk.ogg", &[7u8; 64]);
    let result = read(&hinted);
    assert!(matches!(result, Err(MediaError::Corrupt(_))), "{result:?}");
}

#[test]
fn an_io_failure_is_an_error() {
    // A directory opens on Linux but cannot be read.
    let dir = TempDir::new();
    let result = read_lyrics(File::open(dir.path(".")).unwrap(), Some("flac"));
    assert!(matches!(result, Err(MediaError::Io(_))), "{result:?}");
}

#[test]
fn the_content_wins_over_a_wrong_extension() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.flac");
    write_generic(&path, ItemKey::Lyrics, "Still found");
    let lyrics = read_lyrics(File::open(&path).unwrap(), Some("mp3")).unwrap();
    assert_eq!(lyrics.unwrap().text.as_deref(), Some("Still found"));
}

#[test]
fn an_mp3_cut_inside_its_id3_tag_means_no_lyrics() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.mp3");
    write_id3v2(&path, vec![uslt("Plain words")]);
    let bytes = std::fs::read(&path).unwrap();
    let cut = dir.write("cut.mp3", &bytes[..30]);
    assert_eq!(read(&cut), Ok(None));
}
