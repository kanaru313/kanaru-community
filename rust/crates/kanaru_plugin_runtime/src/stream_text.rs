//! Text of a streamed body: UTF-8 decoding across chunk borders and SSE-style
//! line splitting. Pure (no runtime types), so it is tested on its own.
//!
//! Lines end at `\n`, `\r\n` or `\r`. A line is returned as soon as its
//! terminator is buffered: after a `\r` the next `\n`, even as the first byte
//! of a later chunk, belongs to the same terminator and is dropped.

use encoding_rs::{CoderResult, Decoder, UTF_8};

/// A line, or the buffer behind it, passed the limit.
#[derive(Debug, PartialEq, Eq)]
pub struct LineTooLong;

pub struct StreamText {
    decoder: Decoder,
    /// Decoded text; `text[pos..]` is what was not consumed yet.
    text: String,
    pos: usize,
    /// Bytes after `pos` already searched and known to hold no `\r`/`\n`, so
    /// a long unterminated line is not rescanned on every push.
    scanned: usize,
    /// The last line ended at `\r`: a `\n` that comes next is dropped.
    skip_lf: bool,
    ended: bool,
}

impl Default for StreamText {
    fn default() -> Self {
        Self::new()
    }
}

impl StreamText {
    pub fn new() -> Self {
        Self {
            // Not `new_decoder()`: that one would switch to UTF-16 on a
            // UTF-16 BOM, and a stream is UTF-8 only.
            decoder: UTF_8.new_decoder_with_bom_removal(),
            text: String::new(),
            pos: 0,
            scanned: 0,
            skip_lf: false,
            ended: false,
        }
    }

    /// Decodes `bytes` (invalid ones become U+FFFD) and buffers the text.
    pub fn push(&mut self, bytes: &[u8]) {
        self.decode(bytes, false);
    }

    /// No more bytes will come: flushes a cut-off sequence.
    pub fn finish(&mut self) {
        if !self.ended {
            self.decode(&[], true);
            self.ended = true;
        }
    }

    pub fn is_ended(&self) -> bool {
        self.ended
    }

    /// Decoded bytes not consumed yet.
    pub fn buffered_len(&self) -> usize {
        self.text.len() - self.pos
    }

    /// Drops everything buffered.
    pub fn clear(&mut self) {
        self.text.clear();
        self.pos = 0;
        self.scanned = 0;
    }

    fn decode(&mut self, bytes: &[u8], last: bool) {
        // Compact only when the consumed prefix is at least as long as what
        // is left: moving a long partial line on every push would be
        // quadratic. `scanned` is relative to `pos`, so it stays valid.
        if self.pos > 0 && self.pos * 2 >= self.text.len() {
            self.text.drain(..self.pos);
            self.pos = 0;
        }
        let mut input = bytes;
        loop {
            let need = self
                .decoder
                .max_utf8_buffer_length(input.len())
                .unwrap_or(input.len().saturating_mul(3));
            self.text.reserve(need);
            let (result, read, _) = self.decoder.decode_to_string(input, &mut self.text, last);
            input = &input[read..];
            if result == CoderResult::InputEmpty {
                return;
            }
        }
    }

    /// Drops the `\n` that follows a `\r`; keeps waiting if nothing is buffered.
    fn settle_skip_lf(&mut self) {
        if !self.skip_lf || self.pos >= self.text.len() {
            return;
        }
        if self.text.as_bytes()[self.pos] == b'\n' {
            self.pos += 1;
            self.scanned = 0;
        }
        self.skip_lf = false;
    }

    /// The next line without its terminator. `Ok(None)` when no complete line
    /// is buffered (or the stream ended and nothing is left); once the stream
    /// ended, a last unterminated line is returned. `max_line` bounds a line
    /// and, with no terminator yet, the buffer.
    pub fn take_line(&mut self, max_line: usize) -> Result<Option<String>, LineTooLong> {
        self.settle_skip_lf();
        let rest = &self.text.as_bytes()[self.pos..];
        let from = self.scanned.min(rest.len());
        let found = rest[from..]
            .iter()
            .position(|b| matches!(b, b'\n' | b'\r'))
            .map(|i| from + i);
        let Some(end) = found else {
            self.scanned = rest.len();
            if rest.len() > max_line {
                return Err(LineTooLong);
            }
            if self.ended && !rest.is_empty() {
                let line = self.text[self.pos..].to_owned();
                self.clear();
                return Ok(Some(line));
            }
            return Ok(None);
        };
        if end > max_line {
            return Err(LineTooLong);
        }
        let cr = rest[end] == b'\r';
        let line = self.text[self.pos..self.pos + end].to_owned();
        self.pos += end + 1;
        self.scanned = 0;
        if cr {
            self.skip_lf = true;
            self.settle_skip_lf();
        }
        Ok(Some(line))
    }

    /// Everything buffered, or `None` when it is empty (never `""`).
    pub fn take_chunk(&mut self) -> Option<String> {
        self.settle_skip_lf();
        if self.buffered_len() == 0 {
            return None;
        }
        let chunk = self.text[self.pos..].to_owned();
        self.clear();
        Some(chunk)
    }

    /// Everything buffered (`""` when nothing is).
    pub fn take_all(&mut self) -> String {
        self.take_chunk().unwrap_or_default()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const BIG: usize = 1 << 20;

    fn line(t: &mut StreamText) -> Option<String> {
        t.take_line(BIG).unwrap()
    }

    #[test]
    fn lines_split_at_lf_and_the_last_one_waits_for_the_end() {
        let mut t = StreamText::new();
        t.push(b"a\nb");
        assert_eq!(line(&mut t).as_deref(), Some("a"));
        assert_eq!(line(&mut t), None);
        t.push(b"\n");
        assert_eq!(line(&mut t).as_deref(), Some("b"));
        assert_eq!(line(&mut t), None);
        t.push(b"tail");
        t.finish();
        assert_eq!(line(&mut t).as_deref(), Some("tail"));
        assert_eq!(line(&mut t), None);
    }

    #[test]
    fn a_cr_at_a_chunk_end_returns_the_line_and_the_next_lf_is_dropped() {
        let mut t = StreamText::new();
        t.push(b"a\r");
        assert_eq!(line(&mut t).as_deref(), Some("a"));
        t.push(b"\nb\n");
        assert_eq!(line(&mut t).as_deref(), Some("b"));
        assert_eq!(line(&mut t), None);
    }

    #[test]
    fn crlf_in_one_chunk_is_one_terminator_and_lone_cr_splits() {
        let mut t = StreamText::new();
        t.push(b"a\r\nb\rc\r\n\r\nd\n\ne\n");
        let all: Vec<_> = std::iter::from_fn(|| line(&mut t)).collect();
        assert_eq!(all, ["a", "b", "c", "", "d", "", "e"]);
    }

    #[test]
    fn a_cr_followed_by_a_chunk_without_lf_keeps_that_chunk() {
        let mut t = StreamText::new();
        t.push(b"a\r");
        assert_eq!(line(&mut t).as_deref(), Some("a"));
        t.push(b"b\n");
        assert_eq!(line(&mut t).as_deref(), Some("b"));
    }

    #[test]
    fn a_character_split_across_chunks_is_decoded_whole() {
        let mut t = StreamText::new();
        let bytes = "é\n".as_bytes();
        t.push(&bytes[..1]);
        assert_eq!(line(&mut t), None);
        t.push(&bytes[1..]);
        assert_eq!(line(&mut t).as_deref(), Some("é"));
    }

    #[test]
    fn a_utf8_bom_is_dropped() {
        let mut t = StreamText::new();
        t.push(&[0xEF, 0xBB, 0xBF, b'a', b'\n']);
        assert_eq!(line(&mut t).as_deref(), Some("a"));
    }

    #[test]
    fn a_utf8_bom_split_across_chunks_is_dropped() {
        let mut t = StreamText::new();
        t.push(&[0xEF]);
        t.push(&[0xBB, 0xBF, b'a']);
        t.finish();
        assert_eq!(t.take_all(), "a");
    }

    #[test]
    fn a_long_line_pushed_in_small_pieces_is_found_whole() {
        let mut t = StreamText::new();
        let total = 1 << 20;
        for i in 0..total {
            t.push(&[b'a' + (i % 26) as u8]);
            if i % 4096 == 0 {
                assert_eq!(t.take_line(total), Ok(None));
            }
        }
        assert_eq!(t.buffered_len(), total);
        t.push(b"\r\nnext\n");
        let got = t.take_line(total).unwrap().unwrap();
        assert_eq!(got.len(), total);
        assert!(got
            .bytes()
            .enumerate()
            .all(|(i, b)| b == b'a' + (i % 26) as u8));
        assert_eq!(line(&mut t).as_deref(), Some("next"));
        assert_eq!(t.buffered_len(), 0);
    }

    #[test]
    fn a_utf16_bom_does_not_switch_the_encoding() {
        let mut t = StreamText::new();
        t.push(&[0xFF, 0xFE, 0x61]);
        t.finish();
        assert_eq!(t.take_all(), "\u{FFFD}\u{FFFD}a");
    }

    #[test]
    fn invalid_bytes_become_replacement_characters() {
        let mut t = StreamText::new();
        t.push(&[b'a', 0xC3, b'\n']);
        assert_eq!(line(&mut t).as_deref(), Some("a\u{FFFD}"));
        // A cut-off sequence at the end is flushed by `finish`.
        t.push(&[b'b', 0xE2, 0x82]);
        t.finish();
        assert_eq!(t.take_all(), "b\u{FFFD}");
    }

    #[test]
    fn chunks_are_never_empty_and_skip_a_pending_lf() {
        let mut t = StreamText::new();
        assert_eq!(t.take_chunk(), None);
        t.push(b"x\r");
        assert_eq!(line(&mut t).as_deref(), Some("x"));
        t.push(b"\n");
        assert_eq!(t.take_chunk(), None);
        t.push(b"hello");
        assert_eq!(t.take_chunk().as_deref(), Some("hello"));
        assert_eq!(t.take_all(), "");
    }

    #[test]
    fn a_line_over_the_limit_is_refused() {
        let mut t = StreamText::new();
        t.push(&[b'x'; 11]);
        assert_eq!(t.take_line(10), Err(LineTooLong));
        let mut t = StreamText::new();
        t.push(&[b'x'; 10]);
        assert_eq!(t.take_line(10), Ok(None));
        t.push(b"\n");
        assert_eq!(t.take_line(10).unwrap().map(|l| l.len()), Some(10));
        let mut t = StreamText::new();
        t.push(b"xxxxxxxxxxx\nok\n");
        assert_eq!(t.take_line(10), Err(LineTooLong));
    }

    #[test]
    fn many_short_lines_are_taken_in_order() {
        let mut t = StreamText::new();
        t.push("l\n".repeat(1000).as_bytes());
        assert_eq!(std::iter::from_fn(|| line(&mut t)).count(), 1000);
        assert_eq!(t.buffered_len(), 0);
    }
}
