//! The frames symphonia recovered from a broken ID3v2 tag, rebuilt as the
//! lofty [`Id3v2Tag`] lofty's own parse makes of them, so that one mapping
//! (lofty's ID3v2 to `Tag` split, then `tags::mapping`) serves healthy and
//! recovered tags alike.
//!
//! What symphonia gives for one frame: the frame id as written (`TT2` in
//! ID3v2.2, `TYER` in 2.3), the text as a string or, for a `\0`-separated
//! list, a string list (any version), and sub-fields for `TXXX`
//! (`DESCRIPTION`) and `COMM` (`LANGUAGE` lowercased and left out for
//! `XXX`, `SHORT_DESCRIPTION` left out when empty). A frame that maps to two
//! standard tags (`TRCK` `3/12`) comes twice with the same raw value.
//!
//! Only what the mapping reads is rebuilt: text frames, `TXXX` and `COMM`.
//! Pictures, lyrics, URLs, private and binary frames are skipped.

use std::borrow::Cow;

use lofty::config::ParsingMode;
use lofty::id3::v2::{
    upgrade_v2, upgrade_v3, CommentFrame, ExtendedTextFrame, Frame, FrameId, Id3v2Tag,
    TextInformationFrame, TimestampFrame,
};
use lofty::tag::items::Timestamp;
use lofty::TextEncoding;
use symphonia::core::meta::{RawValue, Tag};

/// Frames lofty reads as timestamps rather than plain text.
const TIMESTAMP_IDS: [&str; 5] = ["TDEN", "TDOR", "TDRC", "TDRL", "TDTG"];

/// Text frames lofty reads as key/value lists: not rebuilt.
const KEY_VALUE_IDS: [&str; 2] = ["TIPL", "TMCL"];

/// The lofty tag holding the text, `TXXX` and `COMM` frames of `tags`. Frames
/// lofty would not accept (an invalid id, a date that does not parse) are
/// left out; never panics.
pub(crate) fn to_lofty(tags: &[Tag]) -> Id3v2Tag {
    let mut out = Id3v2Tag::new();
    let mut has_v3_year = false;
    for tag in tags {
        let key = tag.raw.key.as_str();
        let Some(id) = modern_id(key) else {
            continue;
        };
        if let Some(frame) = frame(id, tag) {
            has_v3_year |= key == "TYER";
            out.insert(frame);
        }
    }
    if has_v3_year {
        join_v3_date(&mut out);
    }
    out
}

/// The ID3v2.4 id of a frame id as written, as lofty upgrades it.
fn modern_id(key: &str) -> Option<&str> {
    match key.len() {
        3 => upgrade_v2(key),
        4 => Some(upgrade_v3(key).unwrap_or(key)),
        _ => None,
    }
}

fn frame(id: &str, tag: &Tag) -> Option<Frame<'static>> {
    let values = values(&tag.raw.value)?;
    // lofty keeps a list in one frame, its values separated by `\0`.
    let text = values.join("\0");
    let frame = match id {
        "TXXX" => Frame::UserText(ExtendedTextFrame::new(
            TextEncoding::UTF8,
            sub_field(tag, "DESCRIPTION").unwrap_or_default().to_owned(),
            text,
        )),
        "COMM" => Frame::Comment(CommentFrame::new(
            TextEncoding::UTF8,
            language(tag),
            sub_field(tag, "SHORT_DESCRIPTION")
                .unwrap_or_default()
                .to_owned(),
            text,
        )),
        _ if TIMESTAMP_IDS.contains(&id) => {
            let first = values.first()?;
            let timestamp = Timestamp::parse(&mut first.as_bytes(), ParsingMode::BestAttempt)
                .ok()
                .flatten()?;
            Frame::Timestamp(TimestampFrame::new(
                frame_id(id)?,
                TextEncoding::UTF8,
                timestamp,
            ))
        }
        _ if id.starts_with('T') && !KEY_VALUE_IDS.contains(&id) => Frame::Text(
            TextInformationFrame::new(frame_id(id)?, TextEncoding::UTF8, text),
        ),
        _ => return None,
    };
    Some(frame)
}

fn frame_id(id: &str) -> Option<FrameId<'static>> {
    FrameId::new(Cow::Owned(id.to_owned())).ok()
}

/// The text values of a frame; `None` for a value that is not text.
fn values(value: &RawValue) -> Option<Vec<&str>> {
    match value {
        RawValue::String(text) => Some(vec![text.as_str()]),
        RawValue::StringList(list) => Some(list.iter().map(String::as_str).collect()),
        _ => None,
    }
}

fn sub_field<'a>(tag: &'a Tag, name: &str) -> Option<&'a str> {
    let field = tag
        .raw
        .sub_fields
        .as_deref()?
        .iter()
        .find(|f| f.field == name)?;
    match &field.value {
        RawValue::String(text) => Some(text.as_str()),
        _ => None,
    }
}

/// The comment's language, `XXX` (unknown) when symphonia gives none.
fn language(tag: &Tag) -> [u8; 3] {
    sub_field(tag, "LANGUAGE")
        .and_then(|code| <[u8; 3]>::try_from(code.as_bytes()).ok())
        .unwrap_or(*b"XXX")
}

/// lofty's ID3v2.3 date rule: a year from `TYER` (now `TDRC`) takes its day
/// and month from `TDAT` (`DDMM`), then its hour and minute from `TIME`
/// (`HHMM`); the frames used are removed.
fn join_v3_date(tag: &mut Id3v2Tag) {
    let tdrc = FrameId::Valid(Cow::Borrowed("TDRC"));
    let tdat = FrameId::Valid(Cow::Borrowed("TDAT"));
    let time = FrameId::Valid(Cow::Borrowed("TIME"));
    let Some(Frame::Timestamp(year)) = tag.get(&tdrc).cloned() else {
        return;
    };
    let mut timestamp = year.timestamp;
    if timestamp.month.is_some() {
        return;
    }
    let Some((day, month)) = tag.get_text(&tdat).and_then(two_pairs) else {
        return;
    };
    timestamp.month = Some(month);
    timestamp.day = Some(day);
    // Frames compare by content: the year frame is replaced, not deduped.
    let _ = tag.remove(&tdrc);
    let _ = tag.remove(&tdat);
    if let Some((hour, minute)) = tag.get_text(&time).and_then(two_pairs) {
        timestamp.hour = Some(hour);
        timestamp.minute = Some(minute);
        let _ = tag.remove(&time);
    }
    tag.insert(Frame::Timestamp(TimestampFrame::new(
        tdrc,
        year.encoding,
        timestamp,
    )));
}

/// `"0105"` as `(1, 5)`: four ASCII characters read as two numbers.
fn two_pairs(text: &str) -> Option<(u8, u8)> {
    if text.len() != 4 || !text.is_ascii() {
        return None;
    }
    Some((text[..2].parse().ok()?, text[2..].parse().ok()?))
}

#[cfg(test)]
mod tests;
