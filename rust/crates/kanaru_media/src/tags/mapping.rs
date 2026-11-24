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
    out.release_date = release_date(tag, out.year);
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
    out.comment = capped(comment(tag), MAX_COMMENT_BYTES);
    out.description = capped(description(tag), MAX_COMMENT_BYTES);
}

/// Descriptor of the ID3 `COMM` frame that carries the long description.
const DESCRIPTION_DESCRIPTOR: &str = "description";

fn is_description_frame(item: &lofty::tag::TagItem) -> bool {
    item.description()
        .trim()
        .eq_ignore_ascii_case(DESCRIPTION_DESCRIPTOR)
}

/// The comment: the `COMM` frame with an empty descriptor if there is one,
/// else the first one that is neither the description frame nor an iTunes
/// bookkeeping frame (`iTunNORM`, `iTunSMPB`, ...).
fn comment(tag: &Tag) -> Option<&str> {
    let comments = || {
        tag.items()
            .filter(|i| i.key() == ItemKey::Comment && !is_description_frame(i))
    };
    comments()
        .filter(|i| i.description().trim().is_empty())
        .chain(comments().filter(|i| {
            let d = i.description().trim();
            !d.is_empty() && !d.to_ascii_lowercase().starts_with("itun")
        }))
        .find_map(|i| i.value().text())
}

/// Vorbis `DESCRIPTION`, MP4 `desc`, else an ID3 `COMM` whose descriptor is
/// `description` (kept apart from the comment).
fn description(tag: &Tag) -> Option<&str> {
    tag.get_string(ItemKey::Description).or_else(|| {
        tag.items()
            .filter(|i| i.key() == ItemKey::Comment && is_description_frame(i))
            .find_map(|i| i.value().text())
    })
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
        .map(clean_date)
        .filter(|v| v.len() <= MAX_RAW_DATE_BYTES)
        .find_map(|v| parse_year(&v))
}

/// Removes control characters and surrounding blanks from a raw date.
fn clean_date(raw: &str) -> String {
    raw.chars()
        .filter(|c| !c.is_control())
        .collect::<String>()
        .trim()
        .to_owned()
}

/// Precision of a date: 1 year, 2 year-month, 3 full date. Accepts the dashed
/// (`YYYY-MM-DD`) and compact (`YYYYMM`, `YYYYMMDD`) forms, optionally
/// followed by a time. A month outside 01-12 or a day outside 01-31 counts
/// only up to the part that is valid (`2018-03-00` is a month).
fn date_precision(value: &str) -> u8 {
    let b = value.as_bytes();
    let num = |from: usize| -> Option<u32> {
        let s = b.get(from..from + 2)?;
        s.iter()
            .all(u8::is_ascii_digit)
            .then(|| u32::from(s[0] - b'0') * 10 + u32::from(s[1] - b'0'))
    };
    if !b.get(..4).is_some_and(|s| s.iter().all(u8::is_ascii_digit)) {
        return 0;
    }
    let dashed = b.get(4) == Some(&b'-');
    let month_at = if dashed { 5 } else { 4 };
    if !num(month_at).is_some_and(|m| (1..=12).contains(&m)) {
        return 1;
    }
    let day_at = if dashed { 8 } else { 6 };
    if dashed && b.get(7) != Some(&b'-') {
        return 2;
    }
    if num(day_at).is_some_and(|d| (1..=31).contains(&d)) {
        3
    } else {
        2
    }
}

/// The most precise date among [`YEAR_KEYS`] whose year is `year` (the one
/// chosen for the row); the first key wins a tie. `None` when no key agrees,
/// so a date never contradicts the year shown next to it.
fn release_date(tag: &Tag, year: Option<i32>) -> Option<String> {
    let year = year?;
    let mut best: Option<(u8, String)> = None;
    for value in YEAR_KEYS
        .into_iter()
        .filter_map(|key| tag.get_string(key))
        .map(clean_date)
        .filter(|v| v.len() <= MAX_RAW_DATE_BYTES)
    {
        if parse_year(&value) != Some(year) {
            continue;
        }
        let precision = date_precision(&value);
        if best.as_ref().is_none_or(|(p, _)| precision > *p) {
            best = Some((precision, value));
        }
    }
    best.map(|(_, v)| v)
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
    fn release_date_is_the_most_precise_one_of_the_chosen_year() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::RecordingDate, "2018");
        push(&mut tag, ItemKey::ReleaseDate, "2018-03-15");
        push(&mut tag, ItemKey::OriginalReleaseDate, "2018-03");
        let out = mapped(&tag);
        assert_eq!(out.year, Some(2018));
        assert_eq!(out.release_date.as_deref(), Some("2018-03-15"));
    }

    #[test]
    fn compact_dates_rank_like_dashed_ones() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::RecordingDate, "2018");
        push(&mut tag, ItemKey::ReleaseDate, "20180315");
        assert_eq!(mapped(&tag).release_date.as_deref(), Some("20180315"));
        let mut month = Tag::new(TagType::VorbisComments);
        push(&mut month, ItemKey::RecordingDate, "2018");
        push(&mut month, ItemKey::ReleaseDate, "201803");
        assert_eq!(mapped(&month).release_date.as_deref(), Some("201803"));
    }

    #[test]
    fn invalid_month_or_day_ranks_at_the_valid_part_only() {
        assert_eq!(date_precision("2018-00-00"), 1);
        assert_eq!(date_precision("2018-13-01"), 1);
        assert_eq!(date_precision("2018-03-00"), 2);
        assert_eq!(date_precision("2018-03-32"), 2);
        assert_eq!(date_precision("20180300"), 2);
        assert_eq!(date_precision("2018-03-15T10:00:00"), 3);
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::RecordingDate, "2018-00-00");
        push(&mut tag, ItemKey::ReleaseDate, "2018-03");
        assert_eq!(mapped(&tag).release_date.as_deref(), Some("2018-03"));
    }

    #[test]
    fn itunes_comm_frames_are_not_the_comment() {
        let mut tag = Tag::new(TagType::Id3v2);
        for (desc, text) in [
            ("iTunNORM", "00000A2B 00000B3C"),
            ("", "real comment"),
            ("Other", "other"),
        ] {
            let mut item = TagItem::new(ItemKey::Comment, ItemValue::Text(text.into()));
            item.set_description(desc.into());
            tag.push(item);
        }
        assert_eq!(mapped(&tag).comment.as_deref(), Some("real comment"));
        let mut only = Tag::new(TagType::Id3v2);
        for (desc, text) in [("iTunSMPB", "x"), ("Other", "other")] {
            let mut item = TagItem::new(ItemKey::Comment, ItemValue::Text(text.into()));
            item.set_description(desc.into());
            only.push(item);
        }
        assert_eq!(mapped(&only).comment.as_deref(), Some("other"));
    }

    #[test]
    fn mp4_desc_item_is_the_description() {
        let mut tag = Tag::new(TagType::Mp4Ilst);
        push(&mut tag, ItemKey::Description, "From desc");
        assert_eq!(mapped(&tag).description.as_deref(), Some("From desc"));
    }

    #[test]
    fn release_date_of_another_year_is_dropped() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::RecordingDate, "2018");
        push(&mut tag, ItemKey::ReleaseDate, "2020-03-15");
        let out = mapped(&tag);
        assert_eq!(out.release_date.as_deref(), Some("2018"));
        let mut only_other = Tag::new(TagType::VorbisComments);
        push(&mut only_other, ItemKey::Year, "2018");
        push(&mut only_other, ItemKey::OriginalReleaseDate, "1999-01-01");
        assert_eq!(mapped(&only_other).release_date.as_deref(), Some("2018"));
        assert_eq!(mapped(&Tag::new(TagType::Id3v2)).release_date, None);
    }

    #[test]
    fn release_date_is_cleaned_and_long_junk_is_none() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::RecordingDate, " 2019-07\u{0}-15\n");
        assert_eq!(mapped(&tag).release_date.as_deref(), Some("2019-07-15"));
        let mut long = Tag::new(TagType::VorbisComments);
        push(
            &mut long,
            ItemKey::RecordingDate,
            &format!("2019-{}", "1".repeat(70)),
        );
        let out = mapped(&long);
        assert_eq!((out.year, out.release_date), (None, None));
    }

    #[test]
    fn description_is_read_apart_from_the_comment() {
        let mut tag = Tag::new(TagType::VorbisComments);
        push(&mut tag, ItemKey::Description, "  About the song ");
        push(&mut tag, ItemKey::Comment, "note");
        let out = mapped(&tag);
        assert_eq!(out.description.as_deref(), Some("About the song"));
        assert_eq!(out.comment.as_deref(), Some("note"));
        let mut long = Tag::new(TagType::VorbisComments);
        push(&mut long, ItemKey::Description, &"é".repeat(5000));
        assert_eq!(mapped(&long).description.map(|d| d.len()), Some(4096));
        assert_eq!(mapped(&Tag::new(TagType::Id3v2)).description, None);
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
