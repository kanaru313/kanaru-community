//! Frames go through symphonia's real reader (`read_frames`), so the shapes
//! tested are the ones it gives, then through lofty's `Tag` split.

use lofty::prelude::*;
use lofty::tag::Tag as LoftyTag;
use symphonia::core::meta::{RawTag, RawValue, Tag};

use super::to_lofty;
use crate::tags::id3_recovery::read_frames;

fn syncsafe(n: usize) -> [u8; 4] {
    [21, 14, 7, 0].map(|shift| ((n >> shift) & 0x7f) as u8)
}

/// A frame of ID3v2.`version` (2, 3 or 4).
fn frame(version: u8, id: &str, body: &[u8]) -> Vec<u8> {
    let mut frame = id.as_bytes().to_vec();
    match version {
        2 => frame.extend_from_slice(&(body.len() as u32).to_be_bytes()[1..]),
        3 => {
            frame.extend_from_slice(&(body.len() as u32).to_be_bytes());
            frame.extend_from_slice(&[0, 0]);
        }
        _ => {
            frame.extend_from_slice(&syncsafe(body.len()));
            frame.extend_from_slice(&[0, 0]);
        }
    }
    frame.extend_from_slice(body);
    frame
}

/// The generic tag lofty makes of the frames symphonia reads from a tag of
/// `version` holding `frames`.
fn recovered(version: u8, frames: &[Vec<u8>]) -> LoftyTag {
    let body = frames.concat();
    let mut tag = vec![b'I', b'D', b'3', version, 0, 0];
    tag.extend_from_slice(&syncsafe(body.len()));
    tag.extend_from_slice(&body);
    LoftyTag::from(to_lofty(&read_frames(tag).expect("frames")))
}

fn strings(tag: &LoftyTag, key: ItemKey) -> Vec<&str> {
    tag.get_strings(key).collect()
}

#[test]
fn text_frames_keep_their_value_lists() {
    let tag = recovered(
        4,
        &[
            frame(4, "TIT2", b"\x03Ti\xc3\xaau \xc4\x91\xe1\xbb\x81"),
            frame(4, "TPE1", b"\x03First\x00Second"),
            frame(4, "TCON", b"\x03(13)"),
        ],
    );
    assert_eq!(tag.title().as_deref(), Some("Tiêu đề"));
    assert_eq!(strings(&tag, ItemKey::TrackArtist), ["First", "Second"]);
    assert_eq!(strings(&tag, ItemKey::Genre), ["Pop"]);
}

#[test]
fn number_pairs_given_twice_are_read_once() {
    let tag = recovered(
        4,
        &[frame(4, "TRCK", b"\x033/12"), frame(4, "TPOS", b"\x031/2")],
    );
    assert_eq!(tag.track(), Some(3));
    assert_eq!(tag.track_total(), Some(12));
    assert_eq!(tag.disk(), Some(1));
    assert_eq!(tag.disk_total(), Some(2));
    assert_eq!(strings(&tag, ItemKey::TrackNumber), ["3"]);
}

#[test]
fn user_text_frames_map_by_their_description() {
    let tag = recovered(
        4,
        &[
            frame(4, "TXXX", b"\x03ARTISTS\x00One\x00Two"),
            frame(4, "TXXX", b"\x03unknown\x00kept out"),
        ],
    );
    assert_eq!(strings(&tag, ItemKey::TrackArtists), ["One", "Two"]);
    assert_eq!(tag.item_count(), 2);
}

#[test]
fn comments_keep_their_descriptor_and_language() {
    let tag = recovered(
        4,
        &[
            frame(4, "COMM", b"\x03engdescription\x00Long"),
            frame(4, "COMM", b"\x03eng\x00Plain"),
            frame(4, "COMM", b"\x03XXXother\x00Unknown language"),
        ],
    );
    let comments: Vec<_> = tag
        .items()
        .filter(|i| i.key() == ItemKey::Comment)
        .map(|i| (i.description(), i.lang(), i.value().text().unwrap_or("")))
        .collect();
    assert_eq!(
        comments,
        [
            ("description", b"eng", "Long"),
            ("", b"eng", "Plain"),
            ("other", b"XXX", "Unknown language"),
        ]
    );
}

#[test]
fn version_2_2_ids_are_upgraded() {
    let tag = recovered(
        2,
        &[
            frame(2, "TT2", b"\x00Title"),
            frame(2, "TP1", b"\x00Artist"),
            frame(2, "TYE", b"\x002019"),
        ],
    );
    assert_eq!(tag.title().as_deref(), Some("Title"));
    assert_eq!(tag.artist().as_deref(), Some("Artist"));
    assert_eq!(tag.get_string(ItemKey::RecordingDate), Some("2019"));
}

#[test]
fn a_version_2_3_year_takes_its_date_and_time() {
    let tag = recovered(
        3,
        &[
            frame(3, "TYER", b"\x002019"),
            frame(3, "TDAT", b"\x000105"),
            frame(3, "TIME", b"\x001230"),
        ],
    );
    assert_eq!(
        tag.get_string(ItemKey::RecordingDate),
        Some("2019-05-01T12:30")
    );
    let year_only = recovered(3, &[frame(3, "TYER", b"\x002019")]);
    assert_eq!(year_only.get_string(ItemKey::RecordingDate), Some("2019"));
    let bad_date = recovered(
        3,
        &[frame(3, "TYER", b"\x002019"), frame(3, "TDAT", b"\x00May")],
    );
    assert_eq!(bad_date.get_string(ItemKey::RecordingDate), Some("2019"));
}

#[test]
fn a_date_that_does_not_parse_is_left_out() {
    let tag = recovered(
        4,
        &[
            frame(4, "TDRC", b"\x03not a date"),
            frame(4, "TIT2", b"\x03Kept"),
        ],
    );
    assert_eq!(tag.get_string(ItemKey::RecordingDate), None);
    assert_eq!(tag.title().as_deref(), Some("Kept"));
}

#[test]
fn frames_the_mapping_does_not_read_are_skipped() {
    let tags = [
        Tag::new(RawTag::new("T\0\0\0", "invalid id")),
        Tag::new(RawTag::new("TOOLONG", "invalid id")),
        Tag::new(RawTag::new("XYZ", "unknown 2.2 id")),
        Tag::new(RawTag::new("USLT", "lyrics")),
        Tag::new(RawTag::new("WOAR", "https://example.com")),
        Tag::new(RawTag::new("TIPL", RawValue::from(vec!["mix".to_owned()]))),
        Tag::new(RawTag::new(
            "TIT2",
            RawValue::Binary(std::sync::Arc::new(vec![1u8, 2].into_boxed_slice())),
        )),
        Tag::new(RawTag::new("TALB", "Album")),
    ];
    let lofty = to_lofty(&tags);
    assert_eq!(lofty.len(), 1);
    let tag = LoftyTag::from(lofty);
    assert_eq!(tag.album().as_deref(), Some("Album"));
}
