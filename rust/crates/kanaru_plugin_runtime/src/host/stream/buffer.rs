//! What the runtime keeps per open stream: the decoded text, the byte counts
//! and the budget charge, plus what a script read is served from the buffer
//! and how a host reply is applied to it.

use std::cell::RefCell;
use std::collections::HashMap;

use super::{MODE_CHUNK, MODE_LINE};
use crate::host::budget::ByteBudget;
use crate::limits::{
    MAX_STREAM_BODY_BYTES, MAX_STREAM_LINE_BYTES, MAX_STREAM_READ_BYTES, MAX_STREAM_TEXT_BYTES,
};
use crate::stream_text::StreamText;
use crate::types::StreamReply;

pub(super) struct OpenStream {
    text: StreamText,
    /// Raw bytes delivered so far (the body cap counts these).
    received: usize,
    /// Bytes of `text` charged to the budget; always what is buffered.
    charged: usize,
    /// Dead or closed: reads return `null`/`''` and no op is sent.
    pub(super) finished: bool,
    /// Counts against the per-run cap: open, or dead and not yet `Close`d.
    /// A stream whose body ended needs no `Close` (the host closed it).
    pub(super) holds_slot: bool,
}

impl OpenStream {
    /// The one place the budget is charged or released: afterwards the charge
    /// equals what is buffered. False (nothing charged) when the budget refuses.
    pub(super) fn sync_budget(&mut self, budget: &ByteBudget) -> bool {
        let held = self.text.buffered_len();
        if held > self.charged {
            if !budget.try_charge(held - self.charged) {
                return false;
            }
        } else {
            budget.release(self.charged - held);
        }
        self.charged = held;
        true
    }

    /// Drops the buffered text and ends the stream for the script.
    pub(super) fn discard(&mut self, budget: &ByteBudget) {
        self.text.clear();
        self.sync_budget(budget);
        self.finished = true;
    }
}

/// The streams of one call.
#[derive(Default)]
pub struct StreamState {
    pub(super) next_id: u32,
    pub(super) streams: HashMap<u32, OpenStream>,
}

impl StreamState {
    pub(super) fn slots_used(&self) -> usize {
        self.streams.values().filter(|s| s.holds_slot).count()
    }

    pub(super) fn insert(&mut self, id: u32, finished: bool) {
        self.streams.insert(
            id,
            OpenStream {
                text: StreamText::new(),
                received: 0,
                charged: 0,
                finished,
                holds_slot: true,
            },
        );
    }
}

/// What the buffer gives for a read.
pub(super) enum Served {
    Text(String),
    End,
    Wait,
    TooLong,
}

pub(super) fn serve(s: &mut OpenStream, mode: u8) -> Served {
    if s.finished {
        return Served::End;
    }
    let ended = s.text.is_ended();
    let end_or_wait = if ended { Served::End } else { Served::Wait };
    match mode {
        MODE_LINE => match s.text.take_line(MAX_STREAM_LINE_BYTES) {
            Err(_) => Served::TooLong,
            Ok(Some(line)) => Served::Text(line),
            Ok(None) => end_or_wait,
        },
        MODE_CHUNK => s.text.take_chunk().map_or(end_or_wait, Served::Text),
        _ if s.text.buffered_len() > MAX_STREAM_TEXT_BYTES => Served::TooLong,
        _ if ended => Served::Text(s.text.take_all()),
        _ => Served::Wait,
    }
}

/// Which way a reply was unusable.
pub(super) enum Applied {
    Fine,
    Bad,
    OverBudget,
}

pub(super) fn apply(
    budget: &ByteBudget,
    state: &RefCell<StreamState>,
    id: u32,
    reply: StreamReply,
) -> Applied {
    let mut st = state.borrow_mut();
    let Some(s) = st.streams.get_mut(&id) else {
        return Applied::Fine;
    };
    let len = reply.chunk.len();
    // An empty chunk that is not the end would spin the script's read loop.
    if len > MAX_STREAM_READ_BYTES || (len == 0 && !reply.done) {
        return Applied::Bad;
    }
    s.received = s.received.saturating_add(len);
    if s.received > MAX_STREAM_BODY_BYTES {
        return Applied::Bad;
    }
    s.text.push(&reply.chunk);
    if reply.done {
        s.text.finish();
        s.holds_slot = false;
    }
    if s.sync_budget(budget) {
        Applied::Fine
    } else {
        Applied::OverBudget
    }
}
