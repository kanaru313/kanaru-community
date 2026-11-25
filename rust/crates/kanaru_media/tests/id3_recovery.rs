//! The recovery of a broken ID3v2 tag only ever parses a bounded copy of it.
//!
//! Each test builds a tag whose outcome differs when the copy handed to
//! symphonia is not cut first: frames past the frame cap would be read, and a
//! declared size past the bytes held would make the whole read fail. Padding
//! is no signal here: symphonia stops at padding by itself.

mod lyrics_fixtures;
mod tags_fixtures;

use kanaru_media::tags::lyrics_reader::MAX_ID3_FALLBACK_FRAMES;
use lyrics_fixtures::{broken_id3v2, frame_with_a_bad_encoding, id3v2_frame, read, uslt_frame};
use tags_fixtures::{mp3_bytes, TempDir};

#[test]
fn mp3_lyrics_past_the_frame_cap_are_not_read() {
    let dir = TempDir::new();
    // lofty refuses the tag for its first frame; symphonia skips only that
    // frame and would read on through every filler to the lyrics.
    let mut frames = vec![frame_with_a_bad_encoding()];
    frames.extend(std::iter::repeat_n(
        id3v2_frame("TIT2", b"\x03x"),
        MAX_ID3_FALLBACK_FRAMES,
    ));
    frames.push(uslt_frame("Beyond the cap"));
    let path = dir.write("capped.mp3", &broken_id3v2(&frames, None));
    assert!(lofty::read_from_path(&path).is_err());
    assert_eq!(read(&path), Ok(None));
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
