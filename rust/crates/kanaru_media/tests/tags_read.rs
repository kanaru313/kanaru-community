//! `read_tags` on small generated files.

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
