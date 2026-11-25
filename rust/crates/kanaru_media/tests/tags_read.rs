//! `read_tags` on small generated files.

mod lyrics_fixtures;
mod tags_fixtures;

use std::cell::Cell;
use std::path::Path;

use kanaru_media::tags::read_tags;
use kanaru_media::{Cancel, MediaError};
use lofty::probe::Probe;
use lofty::tag::{ItemKey, TagType};
use tags_fixtures::{flac_bytes, mp3_bytes, open_plain, save, tag_with, wav_bytes, TempDir};

fn read(path: &Path) -> Result<kanaru_media::tags::TrackTags, MediaError> {
    read_tags(path, &open_plain, &Cancel::new())
}

#[test]
fn fixtures_are_valid_audio() {
    let dir = TempDir::new();
    for (name, bytes) in [
        ("a.wav", wav_bytes()),
        ("a.flac", flac_bytes()),
        ("a.mp3", mp3_bytes()),
    ] {
        let path = dir.write(name, &bytes);
        let tagged = Probe::open(&path)
            .and_then(|p| p.guess_file_type().map_err(Into::into))
            .and_then(Probe::read);
        assert!(tagged.is_ok(), "{name} does not parse");
    }
}

#[test]
fn wav_with_id3_tags() {
    let dir = TempDir::new();
    let path = dir.write("song.wav", &wav_bytes());
    let tag = tag_with(
        TagType::Id3v2,
        &[
            (
                ItemKey::TrackTitle,
                "Những ngày tháng cũ còn mãi trong tim tôi",
            ),
            (ItemKey::TrackArtist, "Ca sĩ"),
            (ItemKey::AlbumTitle, "Album"),
            (ItemKey::RecordingDate, "2019-05-01"),
            (ItemKey::TrackNumber, "3"),
            (ItemKey::TrackTitleSortOrder, "Nhung"),
        ],
    );
    save(&tag, &path);
    let tags = read(&path).expect("read");
    assert_eq!(tags.codec.as_deref(), Some("WAV"));
    assert_eq!(tags.artists, ["Ca sĩ"]);
    assert_eq!(tags.album.as_deref(), Some("Album"));
    assert_eq!(tags.year, Some(2019));
    assert_eq!(tags.track_no, Some(3));
    assert_eq!(tags.title_sort.as_deref(), Some("Nhung"));
    assert_eq!(tags.sample_rate, Some(44_100));
    assert_eq!(tags.channels, Some(1));
    assert_eq!(tags.bit_depth, Some(16));
    assert_eq!(tags.duration_ms, Some(1000));
    assert_eq!(tags.detected_language.as_deref(), Some("vie"));
    assert_eq!(tags.language_tag, None);
}

#[test]
fn wav_with_riff_info_tags() {
    let dir = TempDir::new();
    let path = dir.write("info.wav", &wav_bytes());
    let tag = tag_with(
        TagType::RiffInfo,
        &[
            (ItemKey::TrackTitle, "Info Title"),
            (ItemKey::TrackArtist, "Info Artist"),
        ],
    );
    save(&tag, &path);
    let tags = read(&path).expect("read");
    assert_eq!(tags.title.as_deref(), Some("Info Title"));
    assert_eq!(tags.artists, ["Info Artist"]);
}

#[test]
fn flac_with_repeated_vorbis_fields() {
    let dir = TempDir::new();
    let path = dir.write("song.flac", &flac_bytes());
    let tag = tag_with(
        TagType::VorbisComments,
        &[
            (ItemKey::TrackTitle, "Song"),
            (ItemKey::TrackArtist, "A"),
            (ItemKey::TrackArtist, "B"),
            (ItemKey::AlbumArtist, "Band"),
            (ItemKey::Genre, "Rock"),
            (ItemKey::Genre, "Pop"),
            (ItemKey::Year, "1999"),
            (ItemKey::Language, "eng"),
            (ItemKey::Comment, "hello"),
        ],
    );
    save(&tag, &path);
    let tags = read(&path).expect("read");
    assert_eq!(tags.codec.as_deref(), Some("FLAC"));
    assert_eq!(tags.artists, ["A", "B"]);
    assert_eq!(tags.album_artists, ["Band"]);
    assert_eq!(tags.genres, ["Rock", "Pop"]);
    assert_eq!(tags.year, Some(1999));
    assert_eq!(tags.comment.as_deref(), Some("hello"));
    assert_eq!(tags.bit_depth, Some(16));
    assert_eq!(tags.channels, Some(2));
    // A language tag wins: no detection.
    assert_eq!(tags.language_tag.as_deref(), Some("eng"));
    assert_eq!(tags.detected_language, None);
}

#[test]
fn mp3_with_id3v24_artist_list() {
    let dir = TempDir::new();
    let path = dir.write("song.mp3", &mp3_bytes());
    let tag = tag_with(
        TagType::Id3v2,
        &[
            (ItemKey::TrackTitle, "Song"),
            (ItemKey::TrackArtist, "First"),
            (ItemKey::TrackArtist, "Second"),
        ],
    );
    save(&tag, &path);
    let tags = read(&path).expect("read");
    assert_eq!(tags.codec.as_deref(), Some("MP3"));
    assert_eq!(tags.artists, ["First", "Second"]);
    assert_eq!(tags.sample_rate, Some(44_100));
}

#[test]
fn content_wins_over_a_wrong_extension() {
    let dir = TempDir::new();
    let path = dir.write("really-flac.mp3", &flac_bytes());
    let tags = read(&path).expect("read");
    assert_eq!(tags.codec.as_deref(), Some("FLAC"));
}

#[test]
fn dsd_files_give_a_filename_only_result() {
    let dir = TempDir::new();
    for name in ["a.dsf", "a.DFF"] {
        let path = dir.write(name, b"DSD not parsed");
        let tags = read(&path).expect("no error");
        assert_eq!(tags, kanaru_media::tags::TrackTags::default());
    }
}

#[test]
fn wma_is_unsupported_without_opening() {
    let opened = Cell::new(false);
    let open = |_: &Path| {
        opened.set(true);
        Err(MediaError::Io(std::io::ErrorKind::NotFound))
    };
    let result = read_tags(Path::new("/x/a.wma"), &open, &Cancel::new());
    assert_eq!(result, Err(MediaError::Unsupported));
    assert!(!opened.get());
}

#[test]
fn open_errors_pass_through() {
    let open = |_: &Path| Err(MediaError::Io(std::io::ErrorKind::PermissionDenied));
    let result = read_tags(Path::new("/x/a.mp3"), &open, &Cancel::new());
    assert_eq!(
        result,
        Err(MediaError::Io(std::io::ErrorKind::PermissionDenied))
    );
}

#[test]
fn garbage_is_a_permanent_unsupported_or_corrupt_error() {
    let dir = TempDir::new();
    let garbage: Vec<u8> = (0..4096u32).map(|i| (i * 31 % 251) as u8).collect();
    for name in ["junk.mp3", "junk.flac", "junk.wav", "junk.xyz"] {
        let path = dir.write(name, &garbage);
        let err = read(&path).expect_err(name);
        assert!(
            matches!(err, MediaError::Unsupported | MediaError::Corrupt(_)),
            "{name}: {err:?}"
        );
        assert!(!err.is_transient());
    }
}

#[test]
fn truncated_flac_is_a_permanent_error() {
    let dir = TempDir::new();
    let bytes = flac_bytes();
    let path = dir.write("cut.flac", &bytes[..20]);
    let err = read(&path).expect_err("truncated");
    assert!(!matches!(err, MediaError::Io(std::io::ErrorKind::Other)));
    assert!(!err.is_transient());
}

#[test]
fn empty_file_is_a_permanent_error() {
    let dir = TempDir::new();
    let path = dir.write("empty.mp3", b"");
    let err = read(&path).expect_err("empty");
    assert!(!err.is_transient());
}

#[test]
fn cancelled_token_stops_before_reading() {
    let dir = TempDir::new();
    let path = dir.write("song.wav", &wav_bytes());
    let cancel = Cancel::new();
    cancel.cancel();
    assert_eq!(
        read_tags(&path, &open_plain, &cancel),
        Err(MediaError::Cancelled)
    );
}

#[test]
fn flac_date_and_description() {
    let dir = TempDir::new();
    let path = dir.write("song.flac", &flac_bytes());
    let tag = tag_with(
        TagType::VorbisComments,
        &[
            (ItemKey::RecordingDate, "2018-03-15"),
            (ItemKey::Description, "  Live at home "),
            (ItemKey::Comment, "plain comment"),
        ],
    );
    save(&tag, &path);
    let tags = read(&path).expect("read");
    assert_eq!(tags.year, Some(2018));
    assert_eq!(tags.release_date.as_deref(), Some("2018-03-15"));
    assert_eq!(tags.description.as_deref(), Some("Live at home"));
    assert_eq!(tags.comment.as_deref(), Some("plain comment"));
}

#[test]
fn flac_date_of_another_year_is_none() {
    let dir = TempDir::new();
    let path = dir.write("song.flac", &flac_bytes());
    // `Year` is read before `ReleaseDate`, so 2018 is the year; the full date
    // belongs to 2020 and must not be shown next to it.
    let tag = tag_with(
        TagType::VorbisComments,
        &[
            (ItemKey::Year, "2018"),
            (ItemKey::ReleaseDate, "2020-03-15"),
        ],
    );
    save(&tag, &path);
    let tags = read(&path).expect("read");
    assert_eq!(tags.year, Some(2018));
    assert_eq!(tags.release_date.as_deref(), Some("2018"));
    assert_eq!(tags.description, None);
}

#[test]
fn mp3_comm_description_is_not_the_comment() {
    use lofty::tag::{ItemValue, TagItem};
    let dir = TempDir::new();
    let path = dir.write("song.mp3", &mp3_bytes());
    let mut tag = tag_with(TagType::Id3v2, &[(ItemKey::RecordingDate, "2018-03-15")]);
    let mut comment = TagItem::new(ItemKey::Comment, ItemValue::Text("the comment".into()));
    comment.set_description(String::new());
    let mut description = TagItem::new(ItemKey::Comment, ItemValue::Text("the description".into()));
    description.set_description("description".into());
    // Described frame first: it must still not become the comment.
    tag.push(description);
    tag.push(comment);
    save(&tag, &path);
    let tags = read(&path).expect("read");
    assert_eq!(tags.release_date.as_deref(), Some("2018-03-15"));
    assert_eq!(tags.comment.as_deref(), Some("the comment"));
    assert_eq!(tags.description.as_deref(), Some("the description"));
}

// Files with a broken ID3v2 tag: lofty refuses them, the scan keeps what was
// written before the damage.

use kanaru_media::tags::TrackTags;
use lyrics_fixtures::{
    aiff_with_chunks, broken_id3v2, flac_with_comments, frame_that_ends_the_tag,
    frame_with_a_bad_encoding, id3v2_frame, id3v2_tag, versioned_bad_frame, versioned_frame,
    versioned_id3v2_tag, wav_with_chunks, Place,
};

/// A text frame of ID3v2.`version`: UTF-8 in 2.4, Latin-1 in 2.3.
fn text(version: u8, id: &str, value: &str) -> Vec<u8> {
    let mut body = vec![if version == 4 { 3 } else { 0 }];
    body.extend_from_slice(value.as_bytes());
    versioned_frame(version, id, &body)
}

/// A `COMM` frame of ID3v2.`version` with `descriptor`.
fn comment(version: u8, descriptor: &str, value: &str) -> Vec<u8> {
    text(version, "COMM", &format!("eng{descriptor}\0{value}"))
}

/// A frame of every field the scan reads, in ID3v2.`version` (3 or 4).
fn every_field(version: u8) -> Vec<Vec<u8>> {
    let mut frames = Vec::new();
    if version == 4 {
        frames.push(text(4, "TIT2", "Những ngày tháng cũ"));
        frames.push(text(4, "TDRC", "2019-05-01"));
    } else {
        // UTF-16 with a byte order mark: 2.3 has no UTF-8.
        let mut title = vec![1, 0xFF, 0xFE];
        title.extend(
            "Những ngày tháng cũ"
                .encode_utf16()
                .flat_map(u16::to_le_bytes),
        );
        frames.push(versioned_frame(3, "TIT2", &title));
        frames.push(text(3, "TYER", "2019"));
        frames.push(text(3, "TDAT", "0105"));
    }
    for (id, value) in [
        ("TPE1", "First\0Second"),
        ("TALB", "Album"),
        ("TPE2", "Band"),
        ("TCON", "(13)"),
        ("TCOM", "Composer"),
        ("TRCK", "3/12"),
        ("TPOS", "1/2"),
        ("TSOT", "Title sort"),
        ("TSOP", "Artist sort"),
        ("TSOA", "Album sort"),
        ("TLAN", "vie"),
    ] {
        frames.push(text(version, id, value));
    }
    frames.push(comment(version, "", "Plain comment"));
    frames.push(comment(version, "description", "Long description"));
    frames.push(text(version, "TXXX", "CATALOGNUMBER\0CAT-1"));
    frames
}

/// A frame lofty refuses, in ID3v2.`version`, that ends what symphonia
/// reads of the tag (2.4) or that it skips (2.3, nothing follows it).
fn damage(version: u8) -> Vec<u8> {
    if version == 4 {
        frame_that_ends_the_tag()
    } else {
        versioned_bad_frame(3)
    }
}

/// `tag` where `ext` keeps an ID3v2 tag, with audio.
fn with_tag(ext: &str, tag: &[u8]) -> Vec<u8> {
    match ext {
        "mp3" => [tag, &mp3_bytes()].concat(),
        "wav" => wav_with_chunks(&[(b"id3 ", tag)], Place::AfterAudio),
        "aiff" => aiff_with_chunks(&[(b"ID3 ", tag)], Place::AfterAudio),
        other => panic!("no ID3v2 place in .{other}"),
    }
}

/// `read_tags` of `bytes` written as `name`, checking lofty's verdict first.
fn read_bytes(dir: &TempDir, name: &str, bytes: &[u8], lofty_reads: bool) -> TrackTags {
    let path = dir.write(name, bytes);
    assert_eq!(lofty::read_from_path(&path).is_ok(), lofty_reads, "{name}");
    read(&path).unwrap_or_else(|e| panic!("{name}: {e:?}"))
}

#[test]
fn broken_id3_keeps_the_fields_read_before_the_damage() {
    let dir = TempDir::new();
    for version in [3, 4] {
        for ext in ["mp3", "wav", "aiff"] {
            let frames = every_field(version);
            // Padding as long as the damaged frame keeps both files the same
            // length, so properties computed from it agree.
            let mut healthy_frames = frames.clone();
            healthy_frames.push(vec![0; damage(version).len()]);
            let healthy = with_tag(ext, &versioned_id3v2_tag(version, &healthy_frames));
            let mut broken_frames = frames;
            broken_frames.push(damage(version));
            let broken = with_tag(ext, &versioned_id3v2_tag(version, &broken_frames));
            assert_eq!(healthy.len(), broken.len());
            let what = format!("v2.{version} .{ext}");
            let mut expected = read_bytes(&dir, &format!("healthy.{ext}"), &healthy, true);
            assert_eq!(expected.artists, ["First", "Second"], "{what}");
            assert_eq!(
                expected.release_date.as_deref(),
                Some("2019-05-01"),
                "{what}"
            );
            assert_eq!(expected.description.as_deref(), Some("Long description"));
            assert!(expected.duration_ms.is_some(), "{what}");
            let recovered = read_bytes(&dir, &format!("broken.{ext}"), &broken, false);
            if ext == "mp3" {
                // lofty's MP3 overall bitrate is the bytes it reads over the
                // duration. The recovered file is read from after its tag,
                // so the tag is not counted: the audio's own 128 kbps.
                let duration = expected.duration_ms.expect("duration") as usize;
                let kbps = |len: usize| Some((len * 8 / duration) as i32);
                assert_eq!(expected.bitrate, kbps(healthy.len()), "{what}");
                assert_eq!(recovered.bitrate, kbps(mp3_bytes().len()), "{what}");
                assert_eq!(recovered.bitrate, Some(128), "{what}");
                expected.bitrate = recovered.bitrate;
            }
            assert_eq!(recovered, expected, "{what}");
        }
    }
}

#[test]
fn fields_after_the_damage_are_lost() {
    let dir = TempDir::new();
    let bytes = broken_id3v2(
        &[
            id3v2_frame("TIT2", b"\x03Kept"),
            frame_that_ends_the_tag(),
            id3v2_frame("TPE1", b"\x03Lost"),
        ],
        None,
    );
    let tags = read_bytes(&dir, "song.mp3", &bytes, false);
    assert_eq!(tags.title.as_deref(), Some("Kept"));
    assert!(tags.artists.is_empty());
    assert_eq!(tags.sample_rate, Some(44_100));
    assert_eq!(tags.codec.as_deref(), Some("MP3"));
}

/// An ID3v1 trailer with `title` and `artist`.
fn id3v1(title: &str, artist: &str) -> Vec<u8> {
    let field = |text: &str, len: usize| {
        let mut bytes = text.as_bytes().to_vec();
        bytes.resize(len, 0);
        bytes
    };
    let mut tag = b"TAG".to_vec();
    tag.extend(field(title, 30));
    tag.extend(field(artist, 30));
    tag.extend(field("", 30 + 4 + 30));
    tag.push(255); // no genre
    tag
}

#[test]
fn a_broken_mp3_falls_back_to_its_id3v1_trailer_when_no_id3v2_frame_survives() {
    let dir = TempDir::new();
    let mut bytes = broken_id3v2(
        &[frame_that_ends_the_tag(), id3v2_frame("TIT2", b"\x03Lost")],
        None,
    );
    bytes.extend(id3v1("Trailer title", "Trailer artist"));
    let tags = read_bytes(&dir, "song.mp3", &bytes, false);
    assert_eq!(tags.title.as_deref(), Some("Trailer title"));
    assert_eq!(tags.artists, ["Trailer artist"]);
    assert_eq!(tags.sample_rate, Some(44_100));
}

#[test]
fn a_broken_wav_falls_back_to_riff_info() {
    let dir = TempDir::new();
    let mut info = b"INFOINAM".to_vec();
    info.extend_from_slice(&11u32.to_le_bytes());
    info.extend_from_slice(b"Info Title\0\0");
    let broken = id3v2_tag(
        &[frame_that_ends_the_tag(), id3v2_frame("TIT2", b"\x03Lost")],
        None,
    );
    let bytes = wav_with_chunks(&[(b"LIST", &info), (b"id3 ", &broken)], Place::AfterAudio);
    let tags = read_bytes(&dir, "song.wav", &bytes, false);
    assert_eq!(tags.title.as_deref(), Some("Info Title"));
    assert_eq!(tags.duration_ms, Some(1000));
    assert_eq!(tags.codec.as_deref(), Some("WAV"));
}

#[test]
fn a_broken_wav_whose_riff_info_fails_too_keeps_its_properties() {
    let dir = TempDir::new();
    // The last chunk, an `INAM` declaring 10 bytes where the file holds 4:
    // lofty refuses the INFO list as well, so only a read without tags gets
    // the properties.
    let mut info = b"INFOINAM".to_vec();
    info.extend_from_slice(&10u32.to_le_bytes());
    info.extend_from_slice(b"abcd");
    let broken = id3v2_tag(
        &[
            id3v2_frame("TIT2", b"\x03Recovered"),
            frame_that_ends_the_tag(),
        ],
        None,
    );
    let bytes = wav_with_chunks(&[(b"id3 ", &broken), (b"LIST", &info)], Place::AfterAudio);
    let tags = read_bytes(&dir, "song.wav", &bytes, false);
    assert_eq!(tags.title.as_deref(), Some("Recovered"));
    assert_eq!(tags.duration_ms, Some(1000));
}

#[test]
fn an_unrecoverable_tag_with_readable_audio_is_not_an_error() {
    let dir = TempDir::new();
    let broken = id3v2_tag(&[frame_that_ends_the_tag()], None);
    for ext in ["mp3", "wav", "aiff"] {
        let tags = read_bytes(&dir, &format!("song.{ext}"), &with_tag(ext, &broken), false);
        assert_eq!(tags.title, None, "{ext}");
        assert!(tags.duration_ms.is_some(), "{ext}");
    }
}

#[test]
fn a_flac_behind_a_broken_prefix_reads_vorbis_and_properties() {
    let dir = TempDir::new();
    let prefix = id3v2_tag(
        &[
            id3v2_frame("TIT2", b"\x03Prefix title"),
            frame_that_ends_the_tag(),
        ],
        None,
    );
    let vorbis = flac_with_comments(&[("TITLE", "Vorbis title"), ("ARTIST", "Vorbis artist")]);
    let tags = read_bytes(&dir, "song.flac", &[&prefix[..], &vorbis].concat(), false);
    assert_eq!(tags.title.as_deref(), Some("Vorbis title"));
    assert_eq!(tags.artists, ["Vorbis artist"]);
    assert_eq!(tags.sample_rate, Some(44_100));
    assert_eq!(tags.duration_ms, Some(1000));
    assert_eq!(tags.codec.as_deref(), Some("FLAC"));

    // Without Vorbis comments, the prefix's frames are the tag.
    let tags = read_bytes(
        &dir,
        "bare.flac",
        &[&prefix[..], &flac_bytes()].concat(),
        false,
    );
    assert_eq!(tags.title.as_deref(), Some("Prefix title"));
    assert_eq!(tags.sample_rate, Some(44_100));
}

#[test]
fn a_broken_tag_with_nothing_recoverable_keeps_the_original_error() {
    use kanaru_media::tags::errors::from_parse_error;
    let dir = TempDir::new();
    // A tag with no frame and nothing after it.
    let cases: [(&str, Vec<u8>); 3] = [
        ("empty.mp3", id3v2_tag(&[], None)),
        ("bad.mp3", id3v2_tag(&[frame_with_a_bad_encoding()], None)),
        ("bad.flac", id3v2_tag(&[frame_that_ends_the_tag()], None)),
    ];
    for (name, bytes) in cases {
        let path = dir.write(name, &bytes);
        let lofty_error = Probe::open(&path)
            .expect("open")
            .options(
                lofty::config::ParseOptions::new()
                    .read_cover_art(false)
                    .parsing_mode(lofty::config::ParsingMode::BestAttempt),
            )
            .guess_file_type()
            .expect("sniff")
            .read()
            .err()
            .unwrap_or_else(|| panic!("{name}: lofty reads it"));
        let error = read(&path).expect_err(name);
        assert_eq!(error, from_parse_error(&lofty_error), "{name}");
        assert!(!error.is_transient(), "{name}");
    }
}

#[test]
fn a_cancel_during_the_open_stops_a_broken_file_before_its_recovery() {
    let dir = TempDir::new();
    let bytes = broken_id3v2(
        &[id3v2_frame("TIT2", b"\x03Title"), frame_that_ends_the_tag()],
        None,
    );
    let path = dir.write("song.mp3", &bytes);
    let cancel = Cancel::new();
    let open = |p: &Path| {
        cancel.cancel();
        open_plain(p)
    };
    assert_eq!(read_tags(&path, &open, &cancel), Err(MediaError::Cancelled));
}
