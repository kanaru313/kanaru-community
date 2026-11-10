//! Pure mapping from lofty tags and properties to [`TrackTags`]. No file I/O,
//! so it is tested with in-memory tags.

use lofty::prelude::*;
use lofty::properties::FileProperties;
use lofty::tag::{ItemKey, Tag};

use super::TrackTags;

/// Longest stored text value (title, artist, album, genre, composer, sort
/// tags, language), in bytes. A hostile tag cannot make a row or a tile huge.
const MAX_TEXT_BYTES: usize = 1024;

/// Longest stored comment, in bytes.
const MAX_COMMENT_BYTES: usize = 4096;

/// Longest accepted raw date, in bytes. A date is never longer, so a longer
/// value is junk and is skipped rather than cut.
const MAX_RAW_DATE_BYTES: usize = 64;

/// Most values kept in one multi-value field (artists, album artists, genres).
const MAX_VALUES: usize = 32;

/// Keys that can carry the release year, most specific first.
const YEAR_KEYS: [ItemKey; 4] = [
    ItemKey::RecordingDate,
    ItemKey::Year,
    ItemKey::ReleaseDate,
    ItemKey::OriginalReleaseDate,
];

/// First four ASCII digits of `raw` as a year: `"2019-05-01"` gives 2019.
/// `None` when the value does not start with four digits.
pub fn parse_year(raw: &str) -> Option<i32> {
    let head = raw.trim().get(..4)?;
    if head.bytes().all(|b| b.is_ascii_digit()) {
        head.parse().ok().filter(|y| *y > 0)
    } else {
        None
    }
}

/// Copies the textual and numeric fields of `tag` into `out`.
pub fn apply_tag(out: &mut TrackTags, tag: &Tag) {
    out.title = capped(tag.title().as_deref(), MAX_TEXT_BYTES);
    out.artists = artists(tag);
    out.album = capped(tag.album().as_deref(), MAX_TEXT_BYTES);
    out.album_artists = values(tag, ItemKey::AlbumArtist);
    out.genres = values(tag, ItemKey::Genre);
    out.composer = capped(tag.get_string(ItemKey::Composer), MAX_TEXT_BYTES);
    out.year = year(tag);
    out.track_no = tag.track().and_then(to_i32);
    out.track_total = tag.track_total().and_then(to_i32);
    out.disc_no = tag.disk().and_then(to_i32);
    out.disc_total = tag.disk_total().and_then(to_i32);
    out.title_sort = capped(tag.get_string(ItemKey::TrackTitleSortOrder), MAX_TEXT_BYTES);
    out.artist_sort = capped(
        tag.get_string(ItemKey::TrackArtistSortOrder),
        MAX_TEXT_BYTES,
    );
    out.album_sort = capped(tag.get_string(ItemKey::AlbumTitleSortOrder), MAX_TEXT_BYTES);
    out.language_tag = capped(tag.get_string(ItemKey::Language), MAX_TEXT_BYTES);
    out.comment = capped(tag.comment().as_deref(), MAX_COMMENT_BYTES);
}

/// Copies the audio properties into `out`. Zero means "unknown" in several
/// formats, so it maps to `None`.
pub fn apply_properties(out: &mut TrackTags, props: &FileProperties) {
    out.duration_ms = i64::try_from(props.duration().as_millis())
        .ok()
        .filter(|ms| *ms > 0);
    out.bitrate = props.overall_bitrate().and_then(to_i32).filter(|v| *v > 0);
    out.sample_rate = props.sample_rate().and_then(to_i32).filter(|v| *v > 0);
    out.bit_depth = props.bit_depth().map(i32::from).filter(|v| *v > 0);
    out.channels = props.channels().map(i32::from).filter(|v| *v > 0);
}

fn to_i32(v: u32) -> Option<i32> {
    i32::try_from(v).ok()
}

/// The year of the first key in [`YEAR_KEYS`] whose cleaned value is at most
/// [`MAX_RAW_DATE_BYTES`] long and starts with four digits.
fn year(tag: &Tag) -> Option<i32> {
    YEAR_KEYS
        .into_iter()
        .filter_map(|key| tag.get_string(key))
        .map(|raw| {
            raw.chars()
                .filter(|c| !c.is_control())
                .collect::<String>()
                .trim()
                .to_owned()
        })
        .filter(|v| v.len() <= MAX_RAW_DATE_BYTES)
        .find_map(|v| parse_year(&v))
}

/// Every non-empty value of `key`, trimmed, each cut to [`MAX_TEXT_BYTES`],
/// at most [`MAX_VALUES`] of them (repeated Vorbis fields, NUL-separated
/// ID3v2.4 lists).
fn values(tag: &Tag, key: ItemKey) -> Vec<String> {
    tag.get_strings(key)
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|s| cut(s, MAX_TEXT_BYTES).to_owned())
        .take(MAX_VALUES)
        .collect()
}

/// Track artists: the explicit multi-value `TrackArtists` key first, then
/// every `TrackArtist` value, then the plain artist accessor.
fn artists(tag: &Tag) -> Vec<String> {
    let mut all = values(tag, ItemKey::TrackArtists);
    if all.is_empty() {
        all = values(tag, ItemKey::TrackArtist);
    }
    if all.is_empty() {
        all.extend(capped(tag.artist().as_deref(), MAX_TEXT_BYTES));
    }
    all
}

/// `value` trimmed and cut to `max_bytes` at a character boundary; `None`
/// when nothing is left.
fn capped(value: Option<&str>, max_bytes: usize) -> Option<String> {
    let trimmed = value?.trim();
    (!trimmed.is_empty()).then(|| cut(trimmed, max_bytes).to_owned())
}

/// The longest prefix of `text` of at most `max_bytes` bytes that ends at a
/// character boundary.
fn cut(text: &str, max_bytes: usize) -> &str {
    let mut end = max_bytes.min(text.len());
    while !text.is_char_boundary(end) {
        end -= 1;
    }
    &text[..end]
}

#[cfg(test)]
mod tests {
    use super::*;
    use lofty::tag::{ItemValue, TagItem, TagType};

    fn push(tag: &mut Tag, key: ItemKey, value: &str) {
        tag.push(TagItem::new(key, ItemValue::Text(value.to_owned())));
    }

    fn mapped(tag: &Tag) -> TrackTags {
        let mut out = TrackTags::default();
        apply_tag(&mut out, tag);
        out
    }

    #[test]
    fn year_takes_first_four_digits() {
        assert_eq!(parse_year("2019-05-01"), Some(2019));
        assert_eq!(parse_year(" 1999 "), Some(1999));
        assert_eq!(parse_year("2001"), Some(2001));
    }

    #[test]
    fn year_rejects_non_numeric_short_and_zero_values() {
        assert_eq!(parse_year(""), None);
        assert_eq!(parse_year("May 2019"), None);
        assert_eq!(parse_year("99"), None);
        assert_eq!(parse_year("0000"), None);
        // Multi-byte text must not panic on a character boundary.
        assert_eq!(parse_year("年年年年"), None);
    }

    #[test]
    fn year_follows_key_order() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::OriginalReleaseDate, "1970");
        assert_eq!(mapped(&tag).year, Some(1970));
        push(&mut tag, ItemKey::ReleaseDate, "2020-01-01");
        assert_eq!(mapped(&tag).year, Some(2020));
        push(&mut tag, ItemKey::Year, "1985");
        assert_eq!(mapped(&tag).year, Some(1985));
        push(&mut tag, ItemKey::RecordingDate, " 2019-07-15 ");
        assert_eq!(mapped(&tag).year, Some(2019));
    }

    #[test]
    fn oversized_or_junk_date_falls_through_to_the_next_key() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::RecordingDate, &"9".repeat(65));
        push(&mut tag, ItemKey::Year, "soon");
        push(&mut tag, ItemKey::ReleaseDate, "2020-01-01");
        assert_eq!(mapped(&tag).year, Some(2020));
        let mut only_long = Tag::new(TagType::VorbisComments);
        push(&mut only_long, ItemKey::RecordingDate, &"9".repeat(65));
        assert_eq!(mapped(&only_long).year, None);
    }

    #[test]
    fn date_with_control_characters_is_cleaned() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::RecordingDate, "20\u{0}19\n");
        assert_eq!(mapped(&tag).year, Some(2019));
    }

    #[test]
    fn repeated_track_artists_are_listed() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::TrackArtists, "A");
        push(&mut tag, ItemKey::TrackArtists, "B");
        assert_eq!(mapped(&tag).artists, ["A", "B"]);
    }

    #[test]
    fn repeated_artist_fields_are_listed_without_blanks() {
        let mut tag = Tag::new(TagType::VorbisComments);
        for name in ["A", " B ", ""] {
            push(&mut tag, ItemKey::TrackArtist, name);
        }
        assert_eq!(mapped(&tag).artists, ["A", "B"]);
    }

    #[test]
    fn single_artist_falls_back_to_the_accessor() {
        let mut tag = Tag::new(TagType::Id3v2);
        tag.set_artist("Solo".into());
        tag.set_title("  Song ".into());
        tag.set_album(String::new());
        let out = mapped(&tag);
        assert_eq!(out.artists, ["Solo"]);
        assert_eq!(out.title.as_deref(), Some("Song"));
        assert_eq!(out.album, None);
    }

    #[test]
    fn long_multibyte_text_is_cut_at_a_character_boundary() {
        let mut tag = Tag::new(TagType::Id3v2);
        // 3-byte characters: 1024 is not a multiple of 3.
        tag.set_title("あ".repeat(700));
        tag.set_comment("é".repeat(5000));
        let out = mapped(&tag);
        let title = out.title.unwrap_or_default();
        assert_eq!(title.len(), 1023);
        assert!(title.chars().all(|c| c == 'あ'));
        assert_eq!(out.comment.map(|c| c.len()), Some(4096));
    }

    #[test]
    fn thousands_of_artists_are_limited() {
        let mut tag = Tag::new(TagType::VorbisComments);
        for i in 0..10_000 {
            push(&mut tag, ItemKey::TrackArtists, &format!("Artist {i}"));
        }
        assert_eq!(mapped(&tag).artists.len(), 32);
    }

    #[test]
    fn each_multi_value_is_capped() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::TrackArtists, &"é".repeat(100_000));
        push(&mut tag, ItemKey::Genre, &"é".repeat(100_000));
        let out = mapped(&tag);
        assert_eq!(out.artists[0].len(), 1024);
        assert_eq!(out.genres[0].len(), 1024);
    }

    #[test]
    fn genres_album_artists_and_sort_tags_are_read() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::Genre, "Rock");
        push(&mut tag, ItemKey::Genre, "Pop");
        push(&mut tag, ItemKey::AlbumArtist, "Band");
        push(&mut tag, ItemKey::TrackTitleSortOrder, "Song, The");
        push(&mut tag, ItemKey::TrackArtistSortOrder, "Band, The");
        push(&mut tag, ItemKey::AlbumTitleSortOrder, "Album, An");
        push(&mut tag, ItemKey::Composer, "Comp");
        let out = mapped(&tag);
        assert_eq!(out.genres, ["Rock", "Pop"]);
        assert_eq!(out.album_artists, ["Band"]);
        assert_eq!(out.title_sort.as_deref(), Some("Song, The"));
        assert_eq!(out.artist_sort.as_deref(), Some("Band, The"));
        assert_eq!(out.album_sort.as_deref(), Some("Album, An"));
        assert_eq!(out.composer.as_deref(), Some("Comp"));
    }

    #[test]
    fn track_and_disc_numbers_are_read() {
        let mut tag = Tag::new(TagType::VorbisComments);
        tag.set_track(3);
        tag.set_track_total(12);
        tag.set_disk(1);
        tag.set_disk_total(2);
        let out = mapped(&tag);
        assert_eq!(
            (out.track_no, out.track_total, out.disc_no, out.disc_total),
            (Some(3), Some(12), Some(1), Some(2))
        );
    }

    #[test]
    fn language_tag_is_raw_trimmed_and_blank_is_none() {
        let mut tag = Tag::new(TagType::Id3v2);
        assert_eq!(mapped(&tag).language_tag, None);
        push(&mut tag, ItemKey::Language, "  \t ");
        assert_eq!(mapped(&tag).language_tag, None);
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::Language, " vie ");
        assert_eq!(mapped(&tag).language_tag.as_deref(), Some("vie"));
    }

    #[test]
    fn zero_properties_map_to_none() {
        let mut out = TrackTags::default();
        apply_properties(&mut out, &FileProperties::default());
        assert_eq!(out.duration_ms, None);
        assert_eq!(out.bitrate, None);
        assert_eq!(out.sample_rate, None);
        assert_eq!(out.bit_depth, None);
        assert_eq!(out.channels, None);
    }
}
