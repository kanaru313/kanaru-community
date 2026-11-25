//! `read_lyrics` on lyrics written into small generated files, plus the
//! broken inputs it must survive.

mod lyrics_fixtures;
mod tags_fixtures;

use std::fs::File;

use kanaru_media::tags::lyrics_reader::{read_lyrics, SyncedLine};
use kanaru_media::MediaError;
use lofty::config::WriteOptions;
use lofty::id3::v2::{ExtendedTextFrame, Frame, Id3v2Tag, SyncTextContentType, TimestampFormat};
use lofty::tag::{ItemKey, Tag, TagExt, TagType};
use lofty::TextEncoding;
use lyrics_fixtures::{
    aiff_with_chunks, broken_id3v2, flac_with_comments, frame_that_ends_the_tag,
    frame_with_a_bad_encoding, id3v2_frame, id3v2_tag, id3v2_tag_bytes, id3v2_tag_with_footer,
    read, sample, sylt, sylt_with, unsynchronised, uslt, uslt_frame, versioned_bad_frame,
    versioned_uslt, wav_with_chunks, write_generic, write_id3v2, write_vorbis_key, Place,
};
use tags_fixtures::{flac_bytes, TempDir};

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
fn a_broken_id3_tag_with_nothing_recoverable_gives_no_lyrics() {
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

const FOOBAR_KEY: &str = "UNSYNCED LYRICS";

#[test]
fn reads_foobar_unsynced_lyrics_from_flac_ogg_and_opus() {
    let dir = TempDir::new();
    for name in ["sample.flac", "sample.ogg", "sample.opus"] {
        for key in [FOOBAR_KEY, "unsynced lyrics"] {
            let path = sample(&dir, name);
            write_vorbis_key(&path, key, "Foobar words");
            let lyrics = read(&path)
                .unwrap()
                .unwrap_or_else(|| panic!("{name} {key}: none"));
            assert_eq!(lyrics.text.as_deref(), Some("Foobar words"), "{name} {key}");
            assert!(lyrics.synced.is_empty(), "{name} {key}");
        }
    }
}

#[test]
fn generic_lyrics_win_over_unsynced_lyrics_with_a_space() {
    let dir = TempDir::new();
    for name in ["sample.flac", "sample.ogg", "sample.opus"] {
        let path = sample(&dir, name);
        write_vorbis_key(&path, FOOBAR_KEY, "Second");
        write_vorbis_key(&path, "LYRICS", "First");
        let lyrics = read(&path).unwrap().expect("lyrics");
        assert_eq!(lyrics.text.as_deref(), Some("First"), "{name}");
    }
}

#[test]
fn an_id3v2_uslt_in_flac_wins_over_unsynced_lyrics_with_a_space() {
    let dir = TempDir::new();
    let path = sample(&dir, "sample.flac");
    write_vorbis_key(&path, FOOBAR_KEY, "From Vorbis");
    // lofty only reads an ID3v2 tag in front of a FLAC stream: prepend one.
    let mut id3 = Id3v2Tag::new();
    id3.insert(uslt("From USLT"));
    let mut bytes = Vec::new();
    id3.dump_to(&mut bytes, WriteOptions::default())
        .expect("encode ID3v2");
    bytes.extend(std::fs::read(&path).unwrap());
    let path = dir.write("with_id3.flac", &bytes);
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("From USLT"));
}

#[test]
fn blank_or_oversized_unsynced_lyrics_count_as_none() {
    let dir = TempDir::new();
    for name in ["sample.flac", "sample.ogg", "sample.opus"] {
        for text in ["  \n ".to_owned(), "a".repeat(1024 * 1024 + 1)] {
            let path = sample(&dir, name);
            write_vorbis_key(&path, FOOBAR_KEY, &text);
            assert_eq!(read(&path), Ok(None), "{name}");
        }
    }
}

#[test]
fn lyrics_before_a_broken_id3_frame_are_kept() {
    let dir = TempDir::new();
    let bytes = broken_id3v2(
        &[
            uslt_frame("Kept first\nKept second"),
            frame_that_ends_the_tag(),
        ],
        None,
    );
    let path = dir.write("broken.mp3", &bytes);
    // lofty refuses the whole tag, so only the fallback can give this text.
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Kept first\nKept second"));
}

#[test]
fn lyrics_after_a_broken_id3_frame_are_lost() {
    let dir = TempDir::new();
    let bytes = broken_id3v2(&[frame_that_ends_the_tag(), uslt_frame("Lost")], None);
    let path = dir.write("broken.mp3", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    assert_eq!(read(&path), Ok(None));
}

#[test]
fn a_frame_skipped_alone_does_not_hide_the_lyrics_after_it() {
    let dir = TempDir::new();
    let bytes = broken_id3v2(&[frame_with_a_bad_encoding(), uslt_frame("Later")], None);
    let path = dir.write("broken.mp3", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Later"));
}

#[test]
fn a_txxx_before_a_broken_id3_frame_is_kept_when_there_is_no_uslt() {
    let dir = TempDir::new();
    let mut body = b"\x03Lyrics\x00".to_vec();
    body.extend_from_slice(b"From TXXX");
    let bytes = broken_id3v2(
        &[id3v2_frame("TXXX", &body), frame_that_ends_the_tag()],
        None,
    );
    let path = dir.write("broken.mp3", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("From TXXX"));
}

#[test]
fn a_huge_declared_id3_tag_is_read_within_the_cap() {
    let dir = TempDir::new();
    let bytes = broken_id3v2(&[uslt_frame("Small")], Some(250 * 1024 * 1024));
    let path = dir.write("huge.mp3", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    // The tag declares far more than the file holds. The declared size is
    // lowered to the bytes held, so the frame read before it is recovered
    // instead of the read failing at the end of the file.
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Small"));

    let empty_body = dir.write(
        "huge_empty.mp3",
        &broken_id3v2(&[], Some(250 * 1024 * 1024)),
    );
    assert_eq!(read(&empty_body), Ok(None));
}

#[test]
fn synced_lines_before_a_broken_id3_frame_are_kept() {
    let dir = TempDir::new();
    let Frame::Binary(sylt_frame) = sylt(
        SyncTextContentType::Lyrics,
        TimestampFormat::MS,
        &[(2500, "Second"), (1000, "First")],
    ) else {
        panic!("SYLT is a binary frame");
    };
    let bytes = broken_id3v2(
        &[
            id3v2_frame("SYLT", &sylt_frame.data),
            frame_that_ends_the_tag(),
        ],
        None,
    );
    let path = dir.write("broken.mp3", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text, None);
    assert_eq!(
        lyrics.synced,
        vec![line(1000, "First"), line(2500, "Second")]
    );
}

#[test]
fn a_flac_behind_a_broken_prefix_without_vorbis_lyrics_uses_the_prefix_frames() {
    let dir = TempDir::new();
    let mut bytes = id3v2_tag(
        &[uslt_frame("From the prefix"), frame_that_ends_the_tag()],
        None,
    );
    bytes.extend(flac_bytes());
    let path = dir.write("broken.flac", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("From the prefix"));
}

#[test]
fn a_broken_prefix_with_nothing_recoverable_is_still_an_error() {
    let dir = TempDir::new();
    let mut bytes = id3v2_tag(&[frame_that_ends_the_tag(), uslt_frame("Lost")], None);
    // One stray byte: `fLaC` is not where the prefix ends.
    bytes.push(0);
    bytes.extend(flac_bytes());
    let path = dir.write("broken.flac", &bytes);
    let result = read(&path);
    assert!(matches!(result, Err(MediaError::Corrupt(_))), "{result:?}");
}

#[test]
fn a_flac_behind_a_broken_id3v2_prefix_reads_its_vorbis_lyrics() {
    let dir = TempDir::new();
    let broken = [uslt_frame("From the prefix"), frame_that_ends_the_tag()];
    let healthy = [uslt_frame("Second prefix")];
    let prefixes = [
        ("plain", id3v2_tag(&broken, None)),
        ("footer", id3v2_tag_with_footer(&broken)),
        (
            "two",
            [id3v2_tag(&broken, None), id3v2_tag(&healthy, None)].concat(),
        ),
    ];
    for key in ["LYRICS", "UNSYNCED LYRICS"] {
        let flac = flac_with_comments(&[(key, "From Vorbis")]);
        for (name, prefix) in &prefixes {
            let path = dir.write("broken.flac", &[prefix.clone(), flac.clone()].concat());
            assert!(lofty::read_from_path(&path).is_err(), "{key} {name}");
            let lyrics = read(&path).unwrap().expect("lyrics");
            assert_eq!(lyrics.text.as_deref(), Some("From Vorbis"), "{key} {name}");
        }
    }
}

#[test]
fn a_flac_behind_a_broken_prefix_without_any_lyrics_has_none() {
    let dir = TempDir::new();
    let mut bytes = id3v2_tag(&[frame_that_ends_the_tag(), uslt_frame("Lost")], None);
    bytes.extend(flac_bytes());
    let path = dir.write("broken.flac", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    assert_eq!(read(&path), Ok(None));
}

/// A WAV or AIFF holding `chunks` at `place`.
fn iff_file(
    dir: &TempDir,
    aiff: bool,
    chunks: &[(&[u8; 4], &[u8])],
    place: Place,
) -> std::path::PathBuf {
    if aiff {
        dir.write("broken.aiff", &aiff_with_chunks(chunks, place))
    } else {
        dir.write("broken.wav", &wav_with_chunks(chunks, place))
    }
}

#[test]
fn lyrics_before_a_broken_id3_frame_are_kept_in_wav_and_aiff() {
    let dir = TempDir::new();
    let even = id3v2_tag(&[uslt_frame("Kept!"), frame_that_ends_the_tag()], None);
    // One byte less of text makes the chunk odd-sized (a pad byte follows).
    let odd = id3v2_tag(&[uslt_frame("Kept"), frame_that_ends_the_tag()], None);
    assert_eq!((even.len() % 2, odd.len() % 2), (0, 1));
    for aiff in [false, true] {
        for id in [b"id3 ", b"ID3 "] {
            for place in [Place::BeforeAudio, Place::AfterAudio] {
                for (tag, text) in [(&even, "Kept!"), (&odd, "Kept")] {
                    let path = iff_file(&dir, aiff, &[(id, tag)], place);
                    let case = format!("aiff={aiff} {id:?} {place:?} {text}");
                    assert!(lofty::read_from_path(&path).is_err(), "{case}");
                    let lyrics = read(&path).unwrap().unwrap_or_else(|| panic!("{case}"));
                    assert_eq!(lyrics.text.as_deref(), Some(text), "{case}");
                }
            }
        }
    }
}

#[test]
fn a_wav_with_a_truncated_id3_chunk_keeps_the_frames_held() {
    let dir = TempDir::new();
    let tag = id3v2_tag(
        &[
            uslt_frame("Held"),
            frame_with_a_bad_encoding(),
            uslt_frame("Cut"),
        ],
        None,
    );
    let mut bytes = wav_with_chunks(&[(b"id3 ", &tag)], Place::AfterAudio);
    // The file ends inside the last frame.
    bytes.truncate(bytes.len() - (tag.len() % 2) - 3);
    let path = dir.write("cut.wav", &bytes);
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Held"));
}

#[test]
fn a_wav_with_two_id3_chunks_reads_the_first_with_lyrics() {
    let dir = TempDir::new();
    let without = id3v2_tag(&[frame_that_ends_the_tag(), uslt_frame("Lost")], None);
    let first = id3v2_tag(&[uslt_frame("First"), frame_that_ends_the_tag()], None);
    let second = id3v2_tag(&[uslt_frame("Second")], None);
    let chunks: [(&[u8; 4], &[u8]); 3] =
        [(b"id3 ", &without), (b"ID3 ", &first), (b"id3 ", &second)];
    let path = dir.write("two.wav", &wav_with_chunks(&chunks, Place::AfterAudio));
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("First"));
}

#[test]
fn a_broken_wav_without_lyrics_still_gives_none() {
    let dir = TempDir::new();
    let tag = id3v2_tag(&[frame_that_ends_the_tag(), uslt_frame("Lost")], None);
    for aiff in [false, true] {
        let path = iff_file(&dir, aiff, &[(b"id3 ", &tag)], Place::AfterAudio);
        assert!(lofty::read_from_path(&path).is_err(), "aiff={aiff}");
        assert_eq!(read(&path), Ok(None), "aiff={aiff}");
    }
}

#[test]
fn lyrics_before_the_damage_are_kept_in_id3v2_2_and_2_3() {
    let dir = TempDir::new();
    for version in [2u8, 3] {
        let mut body = versioned_uslt(version, "Kept lines");
        body.extend(versioned_bad_frame(version));
        let path = dir.write("old.mp3", &id3v2_tag_bytes(version, 0, &body));
        assert!(lofty::read_from_path(&path).is_err(), "v2.{version}");
        let lyrics = read(&path)
            .unwrap()
            .unwrap_or_else(|| panic!("v2.{version}: none"));
        assert_eq!(lyrics.text.as_deref(), Some("Kept lines"), "v2.{version}");
    }
}

#[test]
fn a_tag_level_unsynchronised_id3v2_3_tag_is_recovered() {
    let dir = TempDir::new();
    // The Latin-1 `\u{ff}` makes an FF byte that unsynchronisation escapes.
    let mut body = versioned_uslt(3, "Kept \u{ff} lines");
    body.extend(versioned_bad_frame(3));
    let path = dir.write(
        "unsync.mp3",
        &id3v2_tag_bytes(3, 0x80, &unsynchronised(&body)),
    );
    assert!(lofty::read_from_path(&path).is_err());
    let lyrics = read(&path).unwrap().expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Kept \u{ff} lines"));
}

/// 16 MiB of frames after the lyrics and a frame with bad content (lofty
/// refuses it, symphonia skips it and reads on, so it does parse the flood
/// unless the tag was cut first): the lyrics are kept and the read stays
/// quick. The cut itself is asserted in the unit tests of `tags::id3_recovery::bound`.
fn assert_flood_is_read_fast(flood: Vec<u8>) {
    let dir = TempDir::new();
    let mut body = uslt_frame("Before the flood");
    body.extend(frame_with_a_bad_encoding());
    body.extend(flood);
    let path = dir.write("flood.mp3", &broken_id3v2(&[body], None));
    assert!(lofty::read_from_path(&path).is_err());
    let started = std::time::Instant::now();
    let lyrics = read(&path).expect("read").expect("lyrics");
    assert_eq!(lyrics.text.as_deref(), Some("Before the flood"));
    assert!(started.elapsed() < std::time::Duration::from_secs(3));
}

#[test]
fn a_flood_of_empty_id3_frames_is_read_fast() {
    let empty = id3v2_frame("TIT2", b"");
    assert_flood_is_read_fast(empty.repeat(16 * 1024 * 1024 / empty.len()));
}

#[test]
fn a_flood_of_tiny_junk_id3_frames_is_read_fast() {
    let junk = id3v2_frame("TIT2", b"\x09");
    assert_flood_is_read_fast(junk.repeat(16 * 1024 * 1024 / junk.len()));
}
